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
