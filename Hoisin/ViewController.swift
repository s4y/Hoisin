import Cocoa
import WebKit

class ViewController: NSViewController {
    
    @IBOutlet var webView: WebView!
    
    var document: Document!
    var os: OS? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView!.mainFrame.loadRequest(NSURLRequest(URL: NSURL(string: "hoisin://ui/index.html")!))
    }

    override var representedObject: AnyObject? {
        didSet {
            document = representedObject as! Document
            os = OS(document: document)
        }
    }
    
    // MARK: WebFrameLoadDelegate
    
    override func webView(sender: WebView!, didCommitLoadForFrame frame: WebFrame!) {
        frame.windowObject.JSValue().setValue(os, forProperty: "os")
    }
}

