import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    override init() {
        super.init()
        signal(SIGPIPE, CFunctionPointer<((Int32) -> Void)>(COpaquePointer(bitPattern: 1)))
        
        NSUserDefaults.standardUserDefaults().registerDefaults([
            "WebKitDeveloperExtras": true
        ])
        
        NSURLProtocol.registerClass(HoisonURLProtocol)
    }
    
}

