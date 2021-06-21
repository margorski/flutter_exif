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
        case "fromBytes":
            result("iOS " + UIDevice.current.systemVersion)
            break
        default:
            break;
    }
  }
}
