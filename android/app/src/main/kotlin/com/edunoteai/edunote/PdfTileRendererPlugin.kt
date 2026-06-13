package com.edunoteai.edunote

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.Matrix
import android.graphics.Rect
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File
import java.nio.ByteBuffer
import java.util.UUID
import java.util.concurrent.Executors

class PdfTileRendererPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private val documents = mutableMapOf<String, DocumentWrapper>()
    private val executor = Executors.newFixedThreadPool(4)

    class DocumentWrapper(val fileDescriptor: ParcelFileDescriptor, val renderer: PdfRenderer)

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.edunoteai.edunote/pdf_renderer")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "loadDocument" -> {
                val path = call.argument<String>("path") ?: return result.error("INVALID_ARGUMENT", "Path required", null)
                try {
                    val file = File(path)
                    val fd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                    val renderer = PdfRenderer(fd)
                    val docId = UUID.randomUUID().toString()
                    documents[docId] = DocumentWrapper(fd, renderer)
                    result.success(mapOf("documentId" to docId))
                } catch (e: Exception) {
                    result.error("LOAD_ERROR", e.message, null)
                }
            }
            "getPageCount" -> {
                val docId = call.argument<String>("documentId")
                val doc = documents[docId] ?: return result.success(0)
                result.success(doc.renderer.pageCount)
            }
            "getPageSize" -> {
                val docId = call.argument<String>("documentId")
                val pageIndex = call.argument<Int>("pageIndex") ?: return result.success(null)
                val doc = documents[docId] ?: return result.success(null)
                
                try {
                    val page = doc.renderer.openPage(pageIndex)
                    // Convert points (1/72 inch) to a standard size. Android PdfRenderer returns sizes in points.
                    val width = page.width.toDouble()
                    val height = page.height.toDouble()
                    page.close()
                    result.success(mapOf("width" to width, "height" to height))
                } catch (e: Exception) {
                    result.success(null)
                }
            }
            "renderTile" -> {
                val docId = call.argument<String>("documentId")
                val pageIndex = call.argument<Int>("pageIndex") ?: return result.success(null)
                val x = call.argument<Double>("x") ?: 0.0
                val y = call.argument<Double>("y") ?: 0.0
                val width = call.argument<Double>("width") ?: 0.0
                val height = call.argument<Double>("height") ?: 0.0
                val scale = call.argument<Double>("scale") ?: 1.0
                val pixelWidth = call.argument<Int>("pixelWidth") ?: 0
                val pixelHeight = call.argument<Int>("pixelHeight") ?: 0
                
                val doc = documents[docId] ?: return result.success(null)

                executor.execute {
                    try {
                        val bitmap = Bitmap.createBitmap(pixelWidth, pixelHeight, Bitmap.Config.ARGB_8888)
                        bitmap.eraseColor(Color.WHITE)
                        
                        val page = doc.renderer.openPage(pageIndex)
                        
                        // PdfRenderer doesn't support complex matrix transformations directly in its render call.
                        // We must define a destination rect and a transformation matrix.
                        val matrix = Matrix()
                        matrix.postScale(scale.toFloat(), scale.toFloat())
                        matrix.postTranslate((-x * scale).toFloat(), (-y * scale).toFloat())
                        
                        page.render(bitmap, null, matrix, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                        page.close()

                        // Convert Bitmap to RGBA byte array
                        val buffer = ByteBuffer.allocate(bitmap.byteCount)
                        bitmap.copyPixelsToBuffer(buffer)
                        val bytes = buffer.array()
                        
                        // Run on UI thread to return result
                        channel.invokeMethod("returnResult", null) // Placeholder for UI thread dispatch
                        result.success(bytes)
                    } catch (e: Exception) {
                        result.success(null)
                    }
                }
            }
            "unloadDocument" -> {
                val docId = call.argument<String>("documentId")
                documents.remove(docId)?.let {
                    it.renderer.close()
                    it.fileDescriptor.close()
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        for (doc in documents.values) {
            try { doc.renderer.close(); doc.fileDescriptor.close() } catch (e: Exception) {}
        }
        documents.clear()
        executor.shutdown()
    }
}
