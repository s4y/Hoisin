import Cocoa
import WebKit

class ViewController: NSViewController {
    
    var document: Document!
    
    var splitView: TerminalSplitView { get { return view as! TerminalSplitView } }
    
    override var representedObject: AnyObject? {
        didSet {
            document = representedObject as! Document
        }
    }
}

