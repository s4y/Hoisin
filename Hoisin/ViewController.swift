import Cocoa
import WebKit

class ViewController: NSViewController {
    
    var document: Document!
    
    override var representedObject: AnyObject? {
        didSet {
            document = representedObject as! Document
        }
    }
}

