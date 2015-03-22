import Cocoa
import WebKit

@objc protocol OSJS: JSExport {
    func getenv() -> [String:String]
    func standardizePath(string: String) -> String
    
    // JSExport doesn't support constructors, this is a workaround
    func createTask([String]?) -> HoisinTaskJS
    func createCwd(String) -> CwdJS?
}

class ViewController: NSViewController, OSJS {
    
    @IBOutlet var webView: WebView!
    
    var document: Document!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView!.mainFrame.loadRequest(NSURLRequest(URL: NSURL(string: "hoisin://ui/index.html")!))
    }

    override var representedObject: AnyObject? {
        didSet {
            document = representedObject as! Document
        }
    }
    
    // MARK: - WebFrameLoadDelegate
    
    override func webView(sender: WebView!, didCommitLoadForFrame frame: WebFrame!) {
        frame.windowObject.JSValue().setValue(self, forProperty: "os")
    }
    
    // MARK: - JavaScript API
    
    func getenv() -> [String:String] {
        return NSProcessInfo.processInfo().environment as! [String:String]
    }
    
    func standardizePath(string: String) -> String {
        return NSURL(fileURLWithPath: string.stringByStandardizingPath)!.path!
    }
    
    func createTask(argv: [String]?) -> HoisinTaskJS {
        let task = HoisinTask()
        if let argv = argv {
            task.argv = argv
        }
        return task
    }
    
    @objc func createCwd(path: String) -> CwdJS? {
        return Cwd(path: path)
    }
}

