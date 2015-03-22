import Foundation

class JSONTransport {
    let handle: NSFileHandle
    let writeBuf = NSMutableData()
    let readBuf = NSMutableData()
    var readHandler: ((AnyObject) -> ())? {
        didSet {
            if readHandler != nil {
                if handle.readabilityHandler != nil { return }
                handle.readabilityHandler = { handle -> () in
                    let newData = self.handle.availableData
                    if newData.length == 0 {
                        self.handle.readabilityHandler = nil
                        return
                    }
                    let nlRange = newData.rangeOfData(
                        NSData(bytes: "\n", length: 1),
                        options: NSDataSearchOptions(),
                        range: NSRange(location: 0, length: newData.length)
                    )
                    if nlRange.length != 0 {
                        self.readBuf.appendData(newData.subdataWithRange(NSRange(location: 0, length: nlRange.location)))
                        if let msg: AnyObject = NSJSONSerialization.JSONObjectWithData(self.readBuf, options: NSJSONReadingOptions(), error: nil) {
                            self.readHandler!(msg)
                        }
                        self.readBuf.length = 0
                        let newPos = nlRange.location + 1
                        self.readBuf.appendData(newData.subdataWithRange(NSRange(location: newPos, length: newData.length - newPos)))
                    } else {
                        self.readBuf.appendData(newData)
                    }
                }
            } else {
                self.handle.readabilityHandler = nil
            }
        }
    }
    
    init (_ handle: NSFileHandle) {
        self.handle = handle
    }
    
    func write(data: NSData) {
        writeBuf.appendData(data)
        if handle.writeabilityHandler != nil { return }
        handle.writeabilityHandler = { handle -> () in
            if (self.writeBuf.length == 0) {
                self.handle.writeabilityHandler = nil
                return
            }
            var totalSent = 0
            var vData = data
            self.writeBuf.enumerateByteRangesUsingBlock { data, range, stop in
                let sent = send(self.handle.fileDescriptor, &vData, range.length, MSG_DONTWAIT)
                if sent < 0 {
                    println("write fail: \(sent)")
                    stop.initialize(true)
                    self.handle.writeabilityHandler = nil
                    return
                } else if sent < range.length {
                    stop.initialize(true)
                }
                totalSent += sent
            }
            self.writeBuf.replaceBytesInRange(NSRange(location: 0, length: totalSent), withBytes: nil, length: 0)
            
        }
    }
    
    func write(json: AnyObject) {
        let data = NSMutableData()
        data.appendData(NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(), error: nil)!)
        data.appendBytes("\n", length: 1)
        write(data)
    }
    
    func close() {
        self.readHandler = nil
        self.handle.writeabilityHandler = nil
    }
}