package com.rajada1_docscan_kit.doc_scan_kit

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel

class DocScanKitPlugin : FlutterPlugin, ActivityAware {
    private val channelName = "doc_scan_kit"
    private lateinit var channel: MethodChannel
    private var documentScanner: DocumentScanner? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, channelName)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        documentScanner = DocumentScanner(binding).also {
            channel.setMethodCallHandler(it)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        // No special handling needed for config changes
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        documentScanner = DocumentScanner(binding).also {
            channel.setMethodCallHandler(it)
        }
    }

    override fun onDetachedFromActivity() {
        documentScanner = null
        channel.setMethodCallHandler(null)
    }
}
