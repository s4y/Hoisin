import Foundation
import WebKit

@objc protocol CwdJS: JSExport {
    var path: String { get }
    func wrap(JSValue)
    func close()
    func dup() -> CwdJS
}

class Cwd: NSObject, CwdJS {
    var handle: NSFileHandle? = nil
    var path: String
    
    init(_ handle: NSFileHandle?, _ path: String) {
        self.handle = handle
        self.path = path
        super.init()
    }
    
    convenience init?(path: String) {
        let fd = open(path, 0)
        if fd == -1 {
            // For some reason Swift makes you fully initialize before returning nil
            self.init(nil, path)
            return nil
        }
        self.init(NSFileHandle(fileDescriptor: fd, closeOnDealloc: true), path)
    }
    
    func wrap(f: JSValue) {
        wrap {
            f.callWithArguments([])
            return ()
        }
    }
    
    func wrap(f: () -> ()) {
        let oldcwd = open(".", 0)
        fchdir(handle!.fileDescriptor)
        f()
        fchdir(oldcwd)
    }
    
    func close() {
        handle = nil
    }
    
    func dup() -> CwdJS {
        return Cwd(handle, path)
    }
}