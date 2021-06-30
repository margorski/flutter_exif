import Flutter
import UIKit

public class SwiftFlutterExifPlugin: NSObject, FlutterPlugin {
    var exifInterface:ExifFileInterface? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_exif_plugin_channel", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterExifPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if (call.method == "initPath") {
            guard let args = call.arguments else {
                result("cannot recognize arguments in method: \(call.method)")
                return
            }
            let path = (args as! String)
            
            do {
                exifInterface = try ExifFileInterface.init(fromPath: path)
            }
            catch {
                print("Unexpected error, when initializing data: \(error).")
                result("error, when initializing data \(error)")
                return
            }
            result(true)
        }
        else if (call.method == "initBytes") {
            guard let args = call.arguments else {
                result("cannot recognize arguments in method: \(call.method)")
                return
            }
            let bytes = (args as! FlutterStandardTypedData)
            let data = Data(bytes.data)
            if (!data.isJpgData) {
                result("data is not a valid jpg file")
                return
            }
            
            do {
                exifInterface = try ExifFileInterface.init(fromData: data)
            }
            catch {
                print("Unexpected error, when initializing data: \(error).")
                result("error, when initializing data \(error)")
                return
            }
            result(true)
        }
        else {
            if (exifInterface == nil) {
                result(FlutterError(code: "EXIF_ERROR", message: "image not initialized", details: nil))
                return
            }
            switch(call.method) {
                case "saveAttributes":
                    do {
                        try exifInterface?.saveToImageData()
                    }
                    catch {
                        print("Unexpected error, when trying to save data to temporary file: \(error).")
                        result("error, while trying to save data to temporary file: \(error)")
                        return
                    }
                    result(true)
                    break
                case "getImageData":
                    result(exifInterface?.imageData)
                    break
                case "setAttribute":
                    guard let args = call.arguments else {
                        result("cannot recognize arguments in method: \(call.method)")
                        return
                    }
                    let tag = ((args as AnyObject)["tag"] as? String)
                    if (tag == nil) {
                        result(FlutterError(code: "ARGUMENT_ERROR", message: "tag is required", details: nil))
                        return
                    }
                    
                    let tagValue = ((args as AnyObject)["tagValue"] as? String)
                    if (tagValue == nil) {
                        result(FlutterError(code: "ARGUMENT_ERROR", message: "tagValue is required", details: nil))
                    }
                    exifInterface?.setAttribute(tag: tag!, value: tagValue!)
                    result(true)
                    break
                case "getAttribute":
                    guard let args = call.arguments else {
                        result("cannot recognize arguments in method: \(call.method)")
                        return
                    }
                    let tag = (args as? String)
                    if (tag == nil) {
                        result(FlutterError(code: "ARGUMENT_ERROR", message: "tag is required", details: nil))
                        return
                    }
                    result(exifInterface?.getAttribute(tag:tag!))
                    break
                case "getLatLong":
                    var latLong = exifInterface?.getLatLong()
                    if (latLong == nil || latLong!.count < 2) {
                        result(false)
                    }
                    var message = Data(capacity: MemoryLayout<Double>.size * 2)
                    message.append(UnsafeBufferPointer(start: &latLong![0], count: 1))
                    message.append(UnsafeBufferPointer(start: &latLong![1], count: 1))
                    let data = FlutterStandardTypedData(float64: message)
                    result(data)
                    break
                case "hasAttribute":
                    guard let args = call.arguments else {
                        result("cannot recognize arguments in method: \(call.method)")
                        return
                    }
                    let tag = (args as? String)
                    if (tag == nil) {
                        result(FlutterError(code: "ARGUMENT_ERROR", message: "tag is required", details: nil))
                        return
                    }
                    result(exifInterface?.hasAttribute(tag:tag!))
                    break
                case "setLatLong":
                    guard let args = call.arguments else {
                        result("cannot recognize arguments in method: \(call.method)")
                        return
                    }
                    let latitude = ((args as AnyObject)["latitude"] as? Double)
                    if (latitude == nil) {
                        result(FlutterError(code: "ARGUMENT_ERROR", message: "latitude is required", details: nil))
                        return
                    }
                    
                    let longitude = ((args as AnyObject)["longitude"] as? Double)
                    if (longitude == nil) {
                        result(FlutterError(code: "ARGUMENT_ERROR", message: "longitude is required", details: nil))
                    }
                    exifInterface?.setLatLong(latitude: latitude!, longitude: longitude!)
                    result(true)
                    break;
                default:
                    result(FlutterMethodNotImplemented)
                    break;
            }
        }
    }
}
