package com.rajada1_docscan_kit.doc_scan_kit;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Log;

import com.google.mlkit.vision.barcode.BarcodeScannerOptions;
import com.google.mlkit.vision.barcode.BarcodeScanning;
import com.google.mlkit.vision.barcode.common.Barcode;
import com.google.mlkit.vision.common.InputImage;

import androidx.annotation.NonNull;

import java.util.List;

public class DocScanBarcodeScanner {
    
    private static final String TAG = "DocScanBarcodeScanner";
    private final com.google.mlkit.vision.barcode.BarcodeScanner scanner;
    
    public interface BarcodeScannerCallback {
        void onSuccess(String barcodeContent);
        void onFailure(Exception e);
    }
    
    public DocScanBarcodeScanner() {
        // Configure scanner to detect all barcode formats including QR codes
        BarcodeScannerOptions options = new BarcodeScannerOptions.Builder()
                .setBarcodeFormats(Barcode.FORMAT_QR_CODE, Barcode.FORMAT_ALL_FORMATS)
                .build();
        scanner = BarcodeScanning.getClient(options);
    }
    
    public void scanBarcodes(byte[] imageBytes, final BarcodeScannerCallback callback) {
        try {
            // Decode bytes to Bitmap
            Bitmap bitmap = BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.length);
            if (bitmap == null) {
                Log.e(TAG, "Failed to decode bitmap from bytes");
                callback.onSuccess("[DEBUG] Failed to decode bitmap from bytes. Image size: " + imageBytes.length);
                return;
            }
            
            int width = bitmap.getWidth();
            int height = bitmap.getHeight();
            Log.d(TAG, "Bitmap decoded successfully. Width: " + width + ", Height: " + height);
            
            // Create InputImage from Bitmap
            InputImage image = InputImage.fromBitmap(bitmap, 0);
            
            // Process image
            scanner.process(image)
                .addOnSuccessListener(barcodes -> {
                    int count = (barcodes != null ? barcodes.size() : 0);
                    Log.d(TAG, "Barcodes detected: " + count);
                    
                    if (barcodes == null || barcodes.isEmpty()) {
                        // Return debug info instead of empty string
                        callback.onSuccess("");
                        return;
                    }
                    
                    // Return the first barcode found
                    Barcode firstBarcode = barcodes.get(0);
                    String rawValue = firstBarcode.getRawValue();
                    
                    Log.d(TAG, "Barcode raw value: " + rawValue);
                    Log.d(TAG, "Barcode format: " + firstBarcode.getFormat());
                    
                    if (rawValue != null && !rawValue.isEmpty()) {
                        callback.onSuccess(rawValue);
                    } else {
                        callback.onSuccess("");
                    }
                })
                .addOnFailureListener(e -> {
                    Log.e(TAG, "Barcode scanning failed", e);
                    callback.onFailure(e);
                });
        } catch (Exception e) {
            Log.e(TAG, "Error processing image bytes", e);
            callback.onFailure(e);
        }
    }
    
    public void close() {
        scanner.close();
    }
}
