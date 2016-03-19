import Cocoa

class CommandLineTextView: NSTextView {
    
    var onBecameFirstResponder: (() -> ())?
    var onResignedFirstResponder: (() -> ())?
    
    override func becomeFirstResponder() -> Bool {
        if super.becomeFirstResponder() {
            onBecameFirstResponder?()
            return true
        }
        return false
    }
    
    override func resignFirstResponder() -> Bool {
        if super.resignFirstResponder() {
            onResignedFirstResponder?()
            return true
        }
        return false
    }
}