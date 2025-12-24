package com.rajada1_docscan_kit.doc_scan_kit

import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class DocScanBarcodeScanner {
    private val scanner = BarcodeScanning.getClient()
    private val scope = CoroutineScope(Dispatchers.IO + Job())
    private var scanJob: Job? = null

    interface BarcodeScannerCallback {
        fun onSuccess(barcodeContent: String)
        fun onFailure(exception: Exception)
    }

    fun scanBarcodes(image: InputImage, callback: BarcodeScannerCallback) {
        scanJob = scope.launch {
            try {
                val barcodes = withContext(Dispatchers.IO) {
                    scanner.process(image).await()
                }
                
                if (barcodes.isEmpty()) {
                    callback.onSuccess("")
                    return@launch
                }
                
                val resultContent = barcodes
                    .mapNotNull { it.rawValue }
                    .joinToString(", ")
                
                callback.onSuccess(resultContent)
            } catch (e: Exception) {
                callback.onFailure(e)
            }
        }
    }

    suspend fun scanBarcodesSuspend(image: InputImage): String = withContext(Dispatchers.IO) {
        suspendCancellableCoroutine { continuation ->
            val callback = object : BarcodeScannerCallback {
                override fun onSuccess(barcodeContent: String) {
                    continuation.resume(barcodeContent)
                }

                override fun onFailure(exception: Exception) {
                    continuation.resumeWithException(exception)
                }
            }
            
            scanBarcodes(image, callback)
            
            continuation.invokeOnCancellation {
                scanJob?.cancel()
            }
        }
    }

    fun close() {
        scanJob?.cancel()
        scanner.close()
    }
}

// Extension function to convert Task<T> to suspend function
private suspend fun <T> com.google.android.gms.tasks.Task<T>.await(): T {
    return suspendCancellableCoroutine { continuation ->
        addOnCompleteListener { task ->
            if (task.isSuccessful) {
                continuation.resume(task.result!!)
            } else {
                continuation.resumeWithException(task.exception!!)
            }
        }
    }
}
