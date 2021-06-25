import Flutter
import UIKit

enum ExifInterfaceEror: Error {
        case invalidFile(String)
}

public class ExifFileInterface {
    private(set) var imageData:Data
    var exifAttributes = CGImageMetadataCreateMutable()
    
    init(fromData data: Data) throws {
        imageData = data
        if (!imageData.isJpgData) {
            throw ExifInterfaceEror.invalidFile("File provided is not a valid JPG file.")
        }
        initExifAttributes()
    }
    
    init(fromPath path: String) throws {
        imageData = try Data(contentsOf: URL(string: path)!, options: Data.ReadingOptions.uncached)
        if (!imageData.isJpgData) {
            throw ExifInterfaceEror.invalidFile("File provided is not a valid JPG file.")
        }
        initExifAttributes()
    }
    
    public func saveToImageData() throws -> Void {
        let imageRef: CGImageSource = CGImageSourceCreateWithData((imageData as CFData), nil)!
        let uti: CFString = CGImageSourceGetType(imageRef)!
        let dataWithEXIF: NSMutableData = NSMutableData(data: imageData)
        let optionsDictionary:CFDictionary = [
            kCGImageDestinationMetadata: exifAttributes,
            kCGImageDestinationMergeMetadata : kCFBooleanTrue as Any
        ] as CFDictionary
        
        let destination: CGImageDestination = CGImageDestinationCreateWithData((dataWithEXIF as CFMutableData), uti, 1, nil)!
        CGImageDestinationCopyImageSource(destination, imageRef, optionsDictionary, nil)
        imageData = dataWithEXIF as Data
    }
    
    func initExifAttributes() {
        exifAttributes = CGImageMetadataCreateMutable()
        
        let imageRef: CGImageSource = CGImageSourceCreateWithData((imageData as CFData), nil)!
        let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageRef, 0, nil)! as NSDictionary
        
        let EXIFDictionary = (imageProperties[kCGImagePropertyExifDictionary as String] as? NSDictionary)!
        //let GPSDictionary = (imageProperties[kCGImagePropertyGPSDictionary as String] as? NSDictionary)!
        
        for (k, v) in EXIFDictionary {
            setAttribute(tag: k as! String, value: v)
        }
//        for (k, v) in GPSDictionary {
//            setAttribute(tag: k as! String, value: v)
//        }
    }
    
    public func setAttribute(tag:String, value:Any) {
        if !(CGImageMetadataSetValueMatchingImageProperty(exifAttributes, kCGImagePropertyExifDictionary, tag as CFString, value as CFTypeRef)) {
            print("Cannot set EXIF metadata \(tag) to \(value) value")
        }
    }
    
    public func getAttribute(tag:String) -> Any? {
        let dictionaries = [kCGImageMetadataPrefixExif as String, kCGImageMetadataPrefixExifEX as String, kCGImageMetadataPrefixTIFF as String, kCGImageMetadataPrefixExifAux as String, kCGImageMetadataPrefixPhotoshop as String, kCGImageMetadataPrefixXMPBasic as String ]
        
        for dict in dictionaries {
            let attributeValue = CGImageMetadataCopyStringValueWithPath(exifAttributes, nil, getTagPath(dictionary: dict, tag: tag) as CFString)
            if (attributeValue != nil) {
                return attributeValue;
            }
        }
        return nil;
    }
    
    public func hasAttribute(tag:String) -> Bool {
        return getAttribute(tag: tag) != nil
    }
    
    func getExifTagPath(tag:String) -> String {
        return getTagPath(dictionary: kCGImageMetadataPrefixExif as String, tag: tag)
    }
    
    func getExifEXTagPath(tag:String) -> String {
        return getTagPath(dictionary: kCGImageMetadataPrefixExifEX as String, tag: tag)
    }
    
    func getTagPath(dictionary:String, tag:String) -> String {
        return "\(dictionary):\(tag)"
    }
    
}

public class ExifPluginHelper {
    static func getTemporaryJpgFilePath() -> String {
        let filename = uniqueFilename(fileExtension: "jpg")
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(filename).absoluteString
    }
    
    static func uniqueFilename(prefix: String? = nil, fileExtension: String? = nil) -> String {
        var uniqueString = ProcessInfo.processInfo.globallyUniqueString
        
        if prefix != nil {
            uniqueString = "\(prefix!)-\(uniqueString)"
        }
        if fileExtension != nil {
            uniqueString = "\(uniqueString).\(fileExtension!)"
        }
        return uniqueString
    }
    
    static func saveDataToFile(data: NSData, path: String) throws {
        let manager: FileManager = FileManager.default
        manager.createFile(atPath: path, contents: data as Data, attributes: nil)
    }
}

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
                    let tag = ((args as AnyObject)["tag"]! as? String)
                    if (tag == nil) {
                        result(FlutterError(code: "ARGUMENT_ERROR", message: "tag is required", details: nil))
                        return
                    }
                    
                    let tagValue = ((args as AnyObject)["tagValue"]! as? String)
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
                    result(FlutterMethodNotImplemented)
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
                    result(FlutterMethodNotImplemented)
                    break
                default:
                    break;
            }
        }
    }
}

extension Data {
    var isJpgData: Bool {
        let array = self.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: 8))
        }
        let jpgHeader: [UInt8] = [
            0xFF, 0xD8, 0xFF
        ]
        
        var image = true
        for i in 0..<jpgHeader.count {
            if array[i] != jpgHeader[i] {
                image = false
                break
            }
        }
        if image { return true }
        return false
    }
}
