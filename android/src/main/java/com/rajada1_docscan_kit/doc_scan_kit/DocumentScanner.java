package com.rajada1_docscan_kit.doc_scan_kit;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentSender;
import android.net.Uri;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanner;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanning;
import com.google.mlkit.vision.documentscanner.GmsDocumentScannerOptions;
import com.google.mlkit.vision.documentscanner.GmsDocumentScanningResult;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.util.Objects;


public class DocumentScanner implements MethodChannel.MethodCallHandler, PluginRegistry.ActivityResultListener {
    private static final String START = "scanKit#startDocumentScanner";
    private static final String CLOSE = "scanKit#closeDocumentScanner";
    private static final String RECOGNIZE_TEXT = "scanKit#recognizeText";
    private static final String RECOGNIZE_TEXT_DETAILED = "vision#startTextRecognizer";
    private static final String SCAN_QR_CODE = "scanKit#scanQrCode";
    private static final String TAG = "DocumentScanner";
    private final Map<String, GmsDocumentScanner> instance = new HashMap<>();
    private final Map<String, DocScanBarcodeScanner> instancesBarCode = new HashMap<>();
    private final Map<String, TextRecognizer> instancesTextRecognizer = new HashMap<>();
    private final Map<String, MLKitTextRecognizer> instancesMLKitTextRecognizer = new HashMap<>();
    private  Map<String, Object> extractedOptions;
    private final ActivityPluginBinding binding;
    private MethodChannel.Result pendingResult = null;

    final private int START_DOCUMENT_ACTIVITY = 0x362738;

    public DocumentScanner(ActivityPluginBinding binding){
        this.binding = binding;
        binding.addActivityResultListener(this);

    }


    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String method = call.method;

        switch (method){
            case START:
                startScanner(call, result);
                break;
            case CLOSE:
                closeScanner(call);
                break;
            case RECOGNIZE_TEXT:
                startRecognizeText(call, result);
                break;
            case RECOGNIZE_TEXT_DETAILED:
                startRecognizeTextDetailed(call, result);
                break;
            case SCAN_QR_CODE:
                startScanQrCode(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }

    }

    @Override
    public boolean onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        if(requestCode == START_DOCUMENT_ACTIVITY){
            if(resultCode == Activity.RESULT_OK){
                GmsDocumentScanningResult result = GmsDocumentScanningResult.fromActivityResultIntent(data);
                if(result != null){
                    handleScannerResult(result);
                }
            }else if(resultCode == Activity.RESULT_CANCELED){
                 // Add null check before using pendingResult to prevent NullPointerException
                if (pendingResult != null) {
                    pendingResult.error(TAG, "Operation canceled", null);
                } else {
                    Log.e(TAG, "pendingResult is null when trying to handle cancellation");
                }                
            }else{
                pendingResult.error(TAG, "Unknown Error", null);
            }
            return true;
        }
        return false;
    }


    private void startScanner(MethodCall call, final MethodChannel.Result result){
        String id = call.argument("id");
        extractedOptions = call.argument("androidOptions");
        GmsDocumentScanner scanner = instance.get(id);
        pendingResult = result;

        if (scanner == null) {
            Map<String, Object> options = call.argument("androidOptions");
            if(options == null){
                result.error(TAG, "Invalid options", null);
                return;
            }
            GmsDocumentScannerOptions scannerOptions =makeOptions(options);
            scanner = GmsDocumentScanning.getClient(scannerOptions);
            instance.put(id, scanner);

        }

        Activity activity = binding.getActivity();
        scanner.getStartScanIntent(activity).addOnSuccessListener(new OnSuccessListener<IntentSender>() {
            @Override
            public void onSuccess(IntentSender intentSender) {
                try {
                    activity.startIntentSenderForResult(intentSender, START_DOCUMENT_ACTIVITY, null, 0, 0, 0);
                } catch (IntentSender.SendIntentException e) {
                    result.error(TAG, "Failed Start document Scanner", e);
                }
            }
        }).addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
                result.error(TAG, "Failed to Start document Scanner", e);
            }
        });

    }


    private GmsDocumentScannerOptions makeOptions(Map<String, Object> options){
        boolean isGalleryImport = Boolean.TRUE.equals(options.get("isGalleryImport"));
        Object pageLimitObject = options.get("pageLimit");
        Object scannerModeObject = options.get("scannerMode");
        int pageLimit = (pageLimitObject instanceof  Number) ? ((Number) pageLimitObject).intValue() : 1;
        String scannerModeValue = (scannerModeObject instanceof  String) ? ((String) scannerModeObject) : "full";
        int scannerMode = GmsDocumentScannerOptions.SCANNER_MODE_FULL;
        switch (scannerModeValue){
            case "base":
                scannerMode = GmsDocumentScannerOptions.SCANNER_MODE_BASE;
                break;
            case "filter":
                scannerMode = GmsDocumentScannerOptions.SCANNER_MODE_BASE_WITH_FILTER;
                break;
            case "full":
                break;

        }
        GmsDocumentScannerOptions.Builder builder = new GmsDocumentScannerOptions.Builder()
                .setGalleryImportAllowed(isGalleryImport)
                .setPageLimit(pageLimit)
                .setResultFormats(GmsDocumentScannerOptions.RESULT_FORMAT_JPEG)
                .setScannerMode(scannerMode);
    return builder.build();

    }

    private void closeScanner(MethodCall call ){
        String id = call.argument("id");
        GmsDocumentScanner scanner = instance.get(id);
        TextRecognizer  text = instancesTextRecognizer.get(id);
        DocScanBarcodeScanner barcode = instancesBarCode.get(id);
        MLKitTextRecognizer mlKitText = instancesMLKitTextRecognizer.get(id);
        
        if(scanner != null) instance.remove(id);

        if(text != null){
            text.closedTextRecognizer();
            instancesTextRecognizer.remove(id);
        }

        if(barcode != null){
            barcode.close();
            instancesBarCode.remove(id);
        }

        if(mlKitText != null){
            mlKitText.close();
            instancesMLKitTextRecognizer.remove(id);
        }
    }

    private void handleScannerResult(GmsDocumentScanningResult result) {
        List<Map<String, Object>> resultMap = new ArrayList<>();
        List<GmsDocumentScanningResult.Page> pages = result.getPages();
        if(pages != null && !pages.isEmpty()){
            for (GmsDocumentScanningResult.Page page : pages){
                Map<String, Object> imageData = new HashMap<>();
                Uri imageUri = page.getImageUri();
                Context context = binding.getActivity().getApplicationContext();
                byte[]  imageBytes = getBytesFromUri(context, imageUri);
                imageData.put("bytes", imageBytes);
                
                boolean saveImage = true;
            
                if (extractedOptions != null) {
                    saveImage = Boolean.TRUE.equals(extractedOptions.get("saveImage"));
                }
                if(!saveImage){
                    File file = new File(Objects.requireNonNull(imageUri.getPath()));
                    file.deleteOnExit();
                }else{
                    imageData.put("path", imageUri.getPath());
                }
                resultMap.add(imageData);
            }
        }else{
            resultMap.add(null);
        }
        
        // Add null check before using pendingResult to prevent NullPointerException
        if (pendingResult != null) {
            pendingResult.success(resultMap);
            pendingResult = null;
        } else {
            Log.e(TAG, "pendingResult is null when trying to handle scanner result");
        }
    }


    private byte[] getBytesFromUri(Context context, Uri uri) {
        try (InputStream inputStream = context.getContentResolver().openInputStream(uri);
             ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[4096];
            int bytesRead;
            while (true) {
                assert inputStream != null;
                if ((bytesRead = inputStream.read(buffer)) == -1) break;
                outputStream.write(buffer, 0, bytesRead);
            }
            return outputStream.toByteArray();
        } catch (IOException e) {

            Log.d("error GetImg Bytes", e.toString());
            return null;
        }
    }

    private void startRecognizeText(MethodCall call, final MethodChannel.Result result) {
        String id = call.argument("id");
        TextRecognizer textRecognizerInstance = instancesTextRecognizer.get(id);
        pendingResult = result;
        if (textRecognizerInstance == null) {
            textRecognizerInstance = new TextRecognizer();
            instancesTextRecognizer.put(id, textRecognizerInstance);

        }



        try {
            byte[] imageBytes = call.argument("imageBytes");
            if (imageBytes == null) {
                result.error(TAG, "Invalid image data", null);
                return;
            }

            String text = textRecognizerInstance.handleDetection2(getInputImageByByteArray(imageBytes));
            result.success(text);
        } catch (Exception e) {
            Log.e(TAG, "Error in text recognition", e);
            result.error(TAG, "Failed to recognize text", e);
        }
    }

    private void startRecognizeTextDetailed(MethodCall call, final MethodChannel.Result result) {
        try {
            String id = call.argument("id");
            MLKitTextRecognizer mlKitTextRecognizer = instancesMLKitTextRecognizer.get(id);
            
            if (mlKitTextRecognizer == null) {
                mlKitTextRecognizer = new MLKitTextRecognizer();
                instancesMLKitTextRecognizer.put(id, mlKitTextRecognizer);
            }

            Map<String, Object> imageData = call.argument("imageData");
            if (imageData == null) {
                result.error(TAG, "Image data is null", null);
                return;
            }

            InputImage inputImage = InputImageConverter.getInputImageFromData(imageData,
                    binding.getActivity().getApplicationContext(), result);
            if (inputImage == null) return;

            mlKitTextRecognizer.processImage(inputImage, new MLKitTextRecognizer.TextRecognizerCallback() {
                @Override
                public void onSuccess(Map<String, Object> textResult) {
                    result.success(textResult);
                }

                @Override
                public void onFailure(Exception e) {
                    result.error(TAG, "Failed to recognize text", e);
                }
            });
        } catch (Exception e) {
            Log.e(TAG, "Error in detailed text recognition", e);
            result.error(TAG, "Failed to recognize text", e);
        }
    }

    private void startScanQrCode(MethodCall call, final MethodChannel.Result result) {
        try {
            String id = call.argument("id");
            DocScanBarcodeScanner barcodeScanner = instancesBarCode.get(id);
            
            if (barcodeScanner == null) {
                barcodeScanner = new DocScanBarcodeScanner();
                instancesBarCode.put(id, barcodeScanner);
            }

            byte[] imageBytes = call.argument("imageBytes");
            if (imageBytes == null) {
                result.error(TAG, "Invalid image data", null);
                return;
            }
            
            Log.d(TAG, "Starting QR code scan with image bytes: " + imageBytes.length);
            
            // Pass bytes directly to the scanner
            barcodeScanner.scanBarcodes(imageBytes, new DocScanBarcodeScanner.BarcodeScannerCallback() {
                @Override
                public void onSuccess(String barcodeContent) {
                    Log.d(TAG, "QR code scan success: " + barcodeContent);
                    result.success(barcodeContent);
                }

                @Override
                public void onFailure(Exception e) {
                    Log.e(TAG, "QR code scan failure", e);
                    result.error(TAG, "Failed to scan barcode", e);
                }
            });
        } catch (Exception e) {
            Log.e(TAG, "Error in QR code scanning", e);
            result.error(TAG, "Failed to scan QR code", e);
        }
    }

    private InputImage getInputImageByByteArray(byte[] imageBytes) throws Exception {
        File tempFile = File.createTempFile("temp_image", ".jpeg", binding.getActivity().getCacheDir());
        try {

            try (FileOutputStream fos = new FileOutputStream(tempFile)) {
                fos.write(imageBytes);
                fos.flush();
            } catch (IOException e) {
                Log.e(TAG, "Error write bytes in temp file", e);
            }
            Context context = binding.getActivity().getApplicationContext();
            return InputImage.fromFilePath(context, Uri.fromFile(tempFile));
        }catch (Exception e) {
            Log.e(TAG, "Error in text recognition", e);
           throw  new Exception("Failed to recognize text", e);
        } finally {
            boolean deleteSuccess = tempFile.delete();
            if (!deleteSuccess) {
                Log.w(TAG, "Failed to delete temporary file");
            }
        }

    }

}
