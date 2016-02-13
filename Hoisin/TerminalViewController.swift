import Cocoa

class CommandLineViewController: NSViewController {
    
    @IBOutlet var textView: NSTextView! {
        didSet {
            textView.font = NSFont(name: "Monaco", size: 12)
            textView.textColor = NSColor.whiteColor()
            textView.textContainerInset = NSSize(width: 0, height: 5)
            textView.enabledTextCheckingTypes = 0
            textView.continuousSpellCheckingEnabled = false
            textView.grammarCheckingEnabled = false
        }
    }
    
    // If I add an awakeFromNib method here, it gets called twice. It would be interesting to find out why.
    
}

class TerminalView: NSView {
    
    private func sharedInit() {
        wantsLayer = true
        
        layer!.backgroundColor = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.2, alpha: 1).CGColor
        
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
}

class TerminalViewController: NSViewController {
}