package com.rajada1_docscan_kit.doc_scan_kit;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.net.Uri;

import com.google.mlkit.vision.common.InputImage;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.Map;

import io.flutter.Log;
import io.flutter.plugin.common.MethodChannel;

public class InputImageConverter {
    private static final String TAG = "InputImageConverter";

    public static InputImage getInputImageFromData(Map<String, Object> imageData, Context context, MethodChannel.Result result) {
        try {
            String imageType = (String) imageData.get("type");
            Integer rotation = (Integer) imageData.get("rotation");
            if (rotation == null) rotation = 0;

            if ("bytes".equals(imageType)) {
                byte[] bytes = (byte[]) imageData.get("bytes");
                if (bytes == null) {
                    result.error("InputImageError", "Image bytes are null", null);
                    return null;
                }

                Bitmap bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
                if (bitmap == null) {
                    result.error("InputImageError", "Failed to decode bitmap from bytes", null);
                    return null;
                }

                return InputImage.fromBitmap(bitmap, rotation);
            } else if ("file".equals(imageType)) {
                String path = (String) imageData.get("path");
                if (path == null) {
                    result.error("InputImageError", "Image path is null", null);
                    return null;
                }

                File file = new File(path);
                if (!file.exists()) {
                    result.error("InputImageError", "Image file does not exist", null);
                    return null;
                }

                return InputImage.fromFilePath(context, Uri.fromFile(file));
            } else if ("imageBytes".equals(imageType)) {
                // Fallback for compatibility
                byte[] bytes = (byte[]) imageData.get("bytes");
                if (bytes == null) {
                    result.error("InputImageError", "Image bytes are null", null);
                    return null;
                }

                // Create temporary file
                File tempFile = File.createTempFile("temp_image", ".jpg", context.getCacheDir());
                try (FileOutputStream fos = new FileOutputStream(tempFile)) {
                    fos.write(bytes);
                    fos.flush();
                }

                InputImage image = InputImage.fromFilePath(context, Uri.fromFile(tempFile));
                
                // Delete temporary file
                boolean deleted = tempFile.delete();
                if (!deleted) {
                    Log.w(TAG, "Failed to delete temporary file");
                }

                return image;
            } else {
                result.error("InputImageError", "Unknown image type: " + imageType, null);
                return null;
            }
        } catch (IOException e) {
            Log.e(TAG, "Error converting image", e);
            result.error("InputImageError", "Failed to convert image: " + e.getMessage(), null);
            return null;
        } catch (Exception e) {
            Log.e(TAG, "Unexpected error converting image", e);
            result.error("InputImageError", "Unexpected error: " + e.getMessage(), null);
            return null;
        }
    }
}