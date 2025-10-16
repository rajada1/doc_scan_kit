package com.rajada1_docscan_kit.doc_scan_kit;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.mlkit.vision.common.InputImage;
import com.google.mlkit.vision.text.Text;
import com.google.mlkit.vision.text.TextRecognition;
import com.google.mlkit.vision.text.latin.TextRecognizerOptions;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;


public class TextRecognizer {

    private final Map<String, com.google.mlkit.vision.text.TextRecognizer> instances = new HashMap<>();

private final ExecutorService executorService;
    private final com.google.mlkit.vision.text.TextRecognizer textRecognizer;

    public TextRecognizer() {

        executorService = Executors.newSingleThreadExecutor();

        textRecognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS);

    }

    public String handleDetection2(InputImage inputImage) {

           Future<String> future =  executorService.submit(
                () -> {
                    Task<Text> result =textRecognizer.process(inputImage);
                    try {
                        Tasks.await(result);

                    } catch (ExecutionException | InterruptedException e) {
                        throw new RuntimeException(e);
                    }
                    return  result.getResult().getText();
                });
        try {
        return  future.get();
        } catch (ExecutionException | InterruptedException e) {
            throw new RuntimeException(e);
        }

    }

    public void closedTextRecognizer(){
        if(textRecognizer != null){
        textRecognizer.close();}
        if(executorService != null){
         executorService.shutdown();
        }
    }
}