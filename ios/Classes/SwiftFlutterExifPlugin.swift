import Flutter
import UIKit

public class SwiftFlutterExifPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_exif_plugin", binaryMessenger: registrar.messenger())
    let instance = SwiftFlutterExifPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch(call.method) {
      case "initPath":
        result("not implemented")
        break
      case "initBytes":
        result("not implemented")
        break
      case "isSupportedMimeType":
        result("not implemented")
        break
      case "saveAttributes":
        result("not implemented")
        break
      case "getImageData":
        result("not implemented")
        break
      case "setAttribute":
        result("not implemented")
        break
      case "getAttribute":
        result("not implemented")
        break
      case "getAttributeDouble":
        result("not implemented")
        break
      case "getAttributeInt":
        result("not implemented")
        break
      case "getAttributeRange":
        result("not implemented")
        break
      case "flipHorizontally":
        result("not implemented")
        break
      case "flipVertically":
        result("not implemented")
        break
      case "getAltitude":
        result("not implemented")
        break
      case "getLatLong":
        result("not implemented")
        break
      case "getRotationDegrees":
        result("not implemented")
        break
      case "getThumbnail":
        result("not implemented")
        break
      case "hasAttribute":
        result("not implemented")
        break
      case "isThumbnailCompressed":
        result("not implemented")
        break
      case "isFlipped":
        result("not implemented")
        break
      case "resetOrientation":
        result("not implemented")
        break
      case "rotate":
        result("not implemented")
        break
      case "setLatLong":
        result("not implemented")
        break            
      default:
        break;
    }
  }
}
