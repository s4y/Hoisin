import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    override init() {
        super.init()
        // TODO do not commit
//        signal(SIGPIPE, COpaquePointer(bitPattern: 1))
        
        NSUserDefaults.standardUserDefaults().registerDefaults([
            "MonospacedFont": [
                "Name": "Source Code Pro",
                "Size": NSNumber(double: 12)
            ]
        ])
        
//        NSURLProtocol.registerClass(HoisonURLProtocol)
    }
    
}

