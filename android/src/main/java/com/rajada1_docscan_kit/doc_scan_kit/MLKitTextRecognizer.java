package com.rajada1_docscan_kit.doc_scan_kit;

import android.graphics.Point;
import android.graphics.Rect;

import androidx.annotation.NonNull;

import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.Text;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

public class MLKitTextRecognizer {
    
    private final com.google.mlkit.vision.text.TextRecognizer textRecognizer;
    private final Executor executor;
    
    public interface TextRecognizerCallback {
        void onSuccess(Map<String, Object> textResult);
        void onFailure(Exception e);
    }
    
    public MLKitTextRecognizer() {
        textRecognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);
        executor = Executors.newSingleThreadExecutor();
    }
    
    public void processImage(InputImage inputImage, final TextRecognizerCallback callback) {
        textRecognizer.process(inputImage)
                .addOnSuccessListener(executor, text -> {
                    Map<String, Object> textResult = new HashMap<>();

                    textResult.put("text", text.getText());

                    List<Map<String, Object>> textBlocks = new ArrayList<>();
                    for (Text.TextBlock block : text.getTextBlocks()) {
                        Map<String, Object> blockData = new HashMap<>();

                        addData(blockData,
                                block.getText(),
                                block.getBoundingBox(),
                                block.getCornerPoints(),
                                block.getRecognizedLanguage(),
                                null,
                                null);

                        List<Map<String, Object>> textLines = new ArrayList<>();
                        for (Text.Line line : block.getLines()) {
                            Map<String, Object> lineData = new HashMap<>();

                            addData(lineData,
                                    line.getText(),
                                    line.getBoundingBox(),
                                    line.getCornerPoints(),
                                    line.getRecognizedLanguage(),
                                    line.getConfidence(),
                                    line.getAngle());

                            List<Map<String, Object>> elementsData = new ArrayList<>();
                            for (Text.Element element : line.getElements()) {
                                Map<String, Object> elementData = new HashMap<>();

                                addData(elementData,
                                        element.getText(),
                                        element.getBoundingBox(),
                                        element.getCornerPoints(),
                                        element.getRecognizedLanguage(),
                                        element.getConfidence(),
                                        element.getAngle());

                                List<Map<String, Object>> symbolsData = new ArrayList<>();
                                for (Text.Symbol symbol : element.getSymbols()) {
                                    Map<String, Object> symbolData = new HashMap<>();

                                    addData(symbolData,
                                            symbol.getText(),
                                            symbol.getBoundingBox(),
                                            symbol.getCornerPoints(),
                                            symbol.getRecognizedLanguage(),
                                            symbol.getConfidence(),
                                            symbol.getAngle());
                                    symbolsData.add(symbolData);
                                }

                                elementData.put("symbols", symbolsData);
                                elementsData.add(elementData);
                            }
                            lineData.put("elements", elementsData);
                            textLines.add(lineData);
                        }
                        blockData.put("lines", textLines);
                        textBlocks.add(blockData);
                    }
                    textResult.put("blocks", textBlocks);
                    callback.onSuccess(textResult);
                })
                .addOnFailureListener(executor, e -> callback.onFailure(e));
    }

    private void addData(Map<String, Object> addTo,
                          String text,
                          Rect rect,
                          Point[] cornerPoints,
                          String recognizedLanguage,
                          Float confidence,
                          Float angle
    ) {
        List<String> recognizedLanguages = new ArrayList<>();
        if (recognizedLanguage != null) {
            recognizedLanguages.add(recognizedLanguage);
        }
        List<Map<String, Integer>> points = new ArrayList<>();
        if (cornerPoints != null) {
            addPoints(cornerPoints, points);
        }
        addTo.put("points", points);
        addTo.put("rect", getBoundingPoints(rect));
        addTo.put("recognizedLanguages", recognizedLanguages);
        addTo.put("text", text);
        addTo.put("confidence", confidence);
        addTo.put("angle", angle);
    }

    private void addPoints(Point[] cornerPoints, List<Map<String, Integer>> points) {
        for (Point point : cornerPoints) {
            Map<String, Integer> p = new HashMap<>();
            p.put("x", point.x);
            p.put("y", point.y);
            points.add(p);
        }
    }

    private Map<String, Integer> getBoundingPoints(Rect rect) {
        Map<String, Integer> frame = new HashMap<>();
        if (rect != null) {
            frame.put("left", rect.left);
            frame.put("right", rect.right);
            frame.put("top", rect.top);
            frame.put("bottom", rect.bottom);
        }
        return frame;
    }

    public void close() {
        if (textRecognizer != null) {
            textRecognizer.close();
        }
    }
}