import Foundation

public class Cwd {
    
    public let path: String
    private let handle: NSFileHandle?
    
    public func wrap(f: () -> ()) {
        let oldcwd = open(".", 0)
        fchdir(handle!.fileDescriptor)
        f()
        fchdir(oldcwd)
    }
    
    public init?(at pathIn: String) {
        let path = (pathIn as NSString).stringByStandardizingPath
        let fd = open(path, 0)
        if fd == -1 {
            self.handle = nil
            self.path = ""
            return nil
        }
        self.path = path
        self.handle = NSFileHandle(fileDescriptor: fd, closeOnDealloc: true)
    }
}