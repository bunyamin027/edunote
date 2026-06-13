import Flutter
import UIKit
import CoreGraphics
import Vision

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let registrar = self.registrar(forPlugin: "com.edunoteai.edunote")!
    PdfTileRendererPlugin.register(with: registrar)
    OcrPlugin.register(with: registrar)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

public class PdfTileRendererPlugin: NSObject, FlutterPlugin {
    private var documents: [String: CGPDFDocument] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.edunoteai.edunote/pdf_renderer", binaryMessenger: registrar.messenger())
        let instance = PdfTileRendererPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        switch call.method {
        case "loadDocument":
            guard let path = args["path"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Path is required", details: nil))
                return
            }
            let url = URL(fileURLWithPath: path)
            guard let document = CGPDFDocument(url as CFURL) else {
                result(FlutterError(code: "LOAD_ERROR", message: "Failed to load PDF", details: nil))
                return
            }
            let docId = UUID().uuidString
            documents[docId] = document
            result(["documentId": docId])
            
        case "getPageCount":
            guard let docId = args["documentId"] as? String,
                  let document = documents[docId] else {
                result(0)
                return
            }
            result(document.numberOfPages)
            
        case "getPageSize":
            guard let docId = args["documentId"] as? String,
                  let document = documents[docId],
                  let pageIndex = args["pageIndex"] as? Int,
                  let page = document.page(at: pageIndex + 1) else { // CGPDF pages are 1-based
                result(nil)
                return
            }
            let rect = page.getBoxRect(.mediaBox)
            let rotation = page.rotationAngle
            if rotation == 90 || rotation == 270 {
                result(["width": rect.height, "height": rect.width])
            } else {
                result(["width": rect.width, "height": rect.height])
            }
            
        case "renderTile":
            guard let docId = args["documentId"] as? String,
                  let document = documents[docId],
                  let pageIndex = args["pageIndex"] as? Int,
                  let page = document.page(at: pageIndex + 1),
                  let x = args["x"] as? Double,
                  let y = args["y"] as? Double,
                  let width = args["width"] as? Double,
                  let height = args["height"] as? Double,
                  let scale = args["scale"] as? Double,
                  let pixelWidth = args["pixelWidth"] as? Int,
                  let pixelHeight = args["pixelHeight"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments for renderTile", details: nil))
                return
            }
            
            // Perform rendering on a background thread
            DispatchQueue.global(qos: .userInitiated).async {
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
                
                guard let context = CGContext(data: nil,
                                              width: pixelWidth,
                                              height: pixelHeight,
                                              bitsPerComponent: 8,
                                              bytesPerRow: pixelWidth * 4,
                                              space: colorSpace,
                                              bitmapInfo: bitmapInfo) else {
                    DispatchQueue.main.async {
                        result(nil)
                    }
                    return
                }
                
                // 1. Fill white background
                context.setFillColor(UIColor.white.cgColor)
                context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
                
                // 2. Set context to top-left so index 0 of memory buffer is the top-left pixel.
                context.translateBy(x: 0, y: CGFloat(pixelHeight))
                context.scaleBy(x: 1.0, y: -1.0)
                
                // 3. Translate and scale so context origin is at the top-left of the visual PDF page.
                // (x, y) from Flutter is the top-left of the tile in visual (rotated) PDF coordinates.
                context.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
                context.translateBy(x: CGFloat(-x), y: CGFloat(-y))
                
                // 4. Get the visual dimensions of the PDF page.
                let rawRect = page.getBoxRect(.mediaBox)
                let rotation = page.rotationAngle
                let visualWidth = (rotation == 90 || rotation == 270) ? rawRect.height : rawRect.width
                let visualHeight = (rotation == 90 || rotation == 270) ? rawRect.width : rawRect.height
                
                // 5. Flip context to bottom-left because getDrawingTransform and drawPDFPage expect it.
                // Move origin to the bottom-left of the visual PDF page.
                context.translateBy(x: 0, y: visualHeight)
                context.scaleBy(x: 1.0, y: -1.0)
                
                // 6. Apply the PDF's intrinsic transform to map it into the visual bounds.
                let targetRect = CGRect(x: 0, y: 0, width: visualWidth, height: visualHeight)
                let transform = page.getDrawingTransform(.mediaBox, rect: targetRect, rotate: 0, preserveAspectRatio: true)
                context.concatenate(transform)
                
                context.interpolationQuality = .high
                context.setRenderingIntent(.defaultIntent)
                context.drawPDFPage(page)
                
                guard let data = context.data else {
                    DispatchQueue.main.async { result(nil) }
                    return
                }
                
                let flutterData = FlutterStandardTypedData(bytes: Data(bytes: data, count: pixelWidth * pixelHeight * 4))
                
                DispatchQueue.main.async {
                    result(flutterData)
                }
            }
            
        case "unloadDocument":
            guard let docId = args["documentId"] as? String else {
                result(nil)
                return
            }
            documents.removeValue(forKey: docId)
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // Allow OCR plugin or others to access the loaded PDF
    public func getDocument(id: String) -> CGPDFDocument? {
        return documents[id]
    }
}

public class OcrPlugin: NSObject, FlutterPlugin {
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.edunoteai.edunote/ocr_plugin", binaryMessenger: registrar.messenger())
        let instance = OcrPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]
        
        if call.method == "ocrPage" {
            guard let documentId = args["documentId"] as? String,
                  let pageIndex = args["pageIndex"] as? Int else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing arguments", details: nil))
                return
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest { (request, error) in
                    guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                        DispatchQueue.main.async { result("") }
                        return
                    }
                    
                    let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
                    DispatchQueue.main.async { result(text) }
                }
                
                request.recognitionLevel = .accurate
                
                DispatchQueue.main.async {
                    result("Simulated OCR text for page \(pageIndex)")
                }
            }
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
}
