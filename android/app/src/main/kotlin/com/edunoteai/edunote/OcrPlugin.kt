package com.edunoteai.edunote

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Executors

class OcrPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val executor = Executors.newSingleThreadExecutor()

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.edunoteai.edunote/ocr_plugin")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "ocrPage") {
            val documentId = call.argument<String>("documentId")
            val pageIndex = call.argument<Int>("pageIndex") ?: return result.error("INVALID_ARGUMENT", "Page index required", null)
            
            // In a real implementation, we would use ML Kit Text Recognition here
            // using the same document cache from PdfTileRendererPlugin to get a Bitmap
            // and pass it to TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
            
            executor.execute {
                Thread.sleep(500) // Simulate processing time
                
                // Needs to dispatch back to main thread manually if inside executor,
                // but Flutter MethodChannel Result must be called on main thread.
                // We'll simulate success via a Handler or returning directly if thread safe
                // Wait, Result must be on UI thread in Android.
                // Let's assume we post it back.
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    result.success("Simulated OCR text for page $pageIndex (Android)")
                }
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }
}
