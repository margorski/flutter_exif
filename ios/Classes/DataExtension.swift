extension Data {
    init<T>(from value: T) {
        self = Swift.withUnsafeBytes(of: value) { Data($0) }
    }
    
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
