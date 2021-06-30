enum ExifFileInterfaceEror: Error {
        case invalidFile(String)
}

public class ExifFileInterface {
    private(set) var imageData:Data
    var exifAttributes = CGImageMetadataCreateMutable()
    
    init(fromData data: Data) throws {
        imageData = data
        if (!imageData.isJpgData) {
            throw ExifFileInterfaceEror.invalidFile("File provided is not a valid JPG file.")
        }
        initExifAttributes()
    }
    
    init(fromPath path: String) throws {
        imageData = try Data(contentsOf: URL(string: path)!, options: Data.ReadingOptions.uncached)
        if (!imageData.isJpgData) {
            throw ExifFileInterfaceEror.invalidFile("File provided is not a valid JPG file.")
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
        
        let EXIFDictionary = (imageProperties[kCGImagePropertyExifDictionary as String] as? NSDictionary) ?? [:] as NSDictionary
        let GPSDictionary = (imageProperties[kCGImagePropertyGPSDictionary as String] as? NSDictionary) ?? [:] as NSDictionary
        
        for (k, v) in EXIFDictionary {
            setAttribute(tag: k as! String, value: v)
        }
        for (k, v) in GPSDictionary {
            setAttribute(tag: k as! String, value: v, dictionary: kCGImagePropertyGPSDictionary)
        }
    }
    
    public func setAttribute(tag:String, value:Any, dictionary:CFString = kCGImagePropertyExifDictionary) {
        if !(CGImageMetadataSetValueMatchingImageProperty(exifAttributes, dictionary, tag as CFString, value as CFTypeRef)) {
            print("Cannot set EXIF metadata \(tag) to \(value) value")
        }
    }
    
    public func getAttribute(tag:String) -> Any? {
        let dictionaries = [kCGImageMetadataPrefixExif as String, kCGImageMetadataPrefixExifEX as String, kCGImageMetadataPrefixTIFF as String, kCGImageMetadataPrefixExifAux as String, kCGImageMetadataPrefixPhotoshop as String, kCGImageMetadataPrefixXMPBasic as String,
            "GPS"
        ]
        
        for dict in dictionaries {
            let attributeValue = CGImageMetadataCopyStringValueWithPath(exifAttributes, nil, getTagPath(dictionary: dict, tag: tag) as CFString)
            if (attributeValue != nil) {
                return attributeValue;
            }
        }
        return nil;
    }
    
    public func getAttributeDouble(tag:String) -> Double? {
        let value = getAttribute(tag: tag) as! String?
        if (value == nil) {
            return nil
        }
        return Double(value!) ?? 0.0
    }
    
    public func hasAttribute(tag:String) -> Bool {
        return getAttribute(tag: tag) != nil
    }
    
    public func setLatLong(latitude:Double, longitude:Double) {
        if (latitude < 0.0) {
            setAttribute(tag: kCGImagePropertyGPSLatitudeRef as String, value: "S")
        }
        else
        {
            setAttribute(tag: kCGImagePropertyGPSLatitudeRef as String, value: "N")
        }
        setAttribute(tag: kCGImagePropertyGPSLatitude as String, value: abs(latitude))
        
        if (longitude < 0.0) {
            setAttribute(tag: kCGImagePropertyGPSLongitudeRef as String, value: "W")
        }
        else
        {
            setAttribute(tag: kCGImagePropertyGPSLongitudeRef as String, value: "E")
        }
        setAttribute(tag: kCGImagePropertyGPSLongitude as String, value: abs(longitude))
    }
    
    public func getLatLong() -> [Double]? {
        print(CGImageMetadataCopyTags(exifAttributes))
        
        let latitudeRef = getAttribute(tag: "GPS\(kCGImagePropertyGPSLatitudeRef)") as! String?
        let latitude = getAttributeDouble(tag: "GPS\(kCGImagePropertyGPSLatitude)")
        let longitudeRef = getAttribute(tag: "GPS\(kCGImagePropertyGPSLongitudeRef)") as! String?
        let longitude = getAttributeDouble(tag: "GPS\(kCGImagePropertyGPSLongitude)")
        
        if (latitudeRef == nil || latitude == nil || longitude == nil || longitudeRef == nil) {
            return nil
        }
        return [(latitudeRef == "S" ? -1.0 : 1.0) * latitude!, (longitudeRef == "W" ? -1.0 : 1.0) * longitude!]
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
