import Foundation
import WebKit

@objc protocol CwdJS: JSExport {
    var path: String { get }
    func wrap(_: JSValue)
    func close()
    func dup() -> CwdJS
}

class Cwd: NSObject, CwdJS {
    
    var handle: NSFileHandle?
    let path: String
    
    init(_ handle: NSFileHandle?, _ path: String) {
        self.handle = handle
        self.path = path
    }
    
    func wrap(f: JSValue) {
        let oldcwd = open(".", 0)
        fchdir(handle!.fileDescriptor)
        f.callWithArguments([])
        fchdir(oldcwd)
    }
    
    func close() {
        handle = nil
    }
    
    func dup() -> CwdJS {
        return Cwd(handle, path)
    }
    
    class func at(path: String) -> Cwd? {
        let fd = open(path, 0)
        if fd == -1 {
            return nil
        }
        return Cwd(NSFileHandle(fileDescriptor: fd, closeOnDealloc: true), path)
    }
}