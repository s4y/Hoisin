import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    override init() {
        super.init()
        // TODO do not commit
//        signal(SIGPIPE, COpaquePointer(bitPattern: 1))
        
        NSUserDefaults.standardUserDefaults().registerDefaults([
            "WebKitDeveloperExtras": true
        ])
        
        NSURLProtocol.registerClass(HoisonURLProtocol)
    }
    
}

