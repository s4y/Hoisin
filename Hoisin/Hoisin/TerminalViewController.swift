import Cocoa

//class CommandLineViewController: NSViewController {
//    
//    @IBOutlet var textView: NSTextView! {
//        didSet {
//            textView.textContainerInset = NSSize(width: 0, height: 5)
//            textView.enabledTextCheckingTypes = 0
//        }
//    }
//    
//    // If I add an awakeFromNib method here, it gets called twice. It would be interesting to find out why.
//    
//}

//class TerminalView: NSView {
//    
//    private func sharedInit() {
//        wantsLayer = true
//        
//        layer!.backgroundColor = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.2, alpha: 1).CGColor
//        
//    }
//    
//    override init(frame frameRect: NSRect) {
//        super.init(frame: frameRect)
//        sharedInit()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        sharedInit()
//    }
//}

class RowView: NSTableRowView {
    
    override var selected: Bool {
        didSet {
            layer!.backgroundColor = selected ? NSColor(calibratedRed: 0.9, green: 0.9, blue: 1, alpha: 1).CGColor : nil
        }
    }
    
    override var interiorBackgroundStyle: NSBackgroundStyle {
        return .Light
    }
    
    override func updateLayer() {}
}

class DummyTextField: NSTextField {
    
    var onBecomeFirstResponder: (() -> ())?
    
    override func becomeFirstResponder() -> Bool {
        onBecomeFirstResponder?()
        return true
    }
}

class CellView: NSTableCellView {
    @IBOutlet var tableView: NSTableView!
    
    var selectable: Bool { return true }
    
    lazy var dummyTextField: DummyTextField = {
        let dummyTextField = DummyTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        self.textField = dummyTextField
        self.addSubview(dummyTextField)
        return dummyTextField
    }()
}

class TaskCellView: CellView {}

class WorkingDirectoryCellView: CellView {
    
    override var selectable: Bool { return false }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer!.backgroundColor = NSColor(calibratedWhite: 0.95, alpha: 1).CGColor
    }
}
    
class CommandLineCellView: CellView, NSTextViewDelegate {
    
    var cell: CommandLineCell? { return objectValue as? CommandLineCell }
    
    @IBOutlet var promptView: NSTextField! {
        didSet {
            promptView.font = AppDefaults.shared.monospacedFont!
        }
    }
    @IBOutlet var textView: NSTextView! {
        didSet {
            guard let textView = textView else { return }
            textView.font = AppDefaults.shared.monospacedFont!
            textView.textContainerInset = NSSize(width: 0, height: 2)
            
            (textView as! CommandLineTextView).onBecameFirstResponder = { [unowned self] in
                self.tableView.selectRowIndexes(
                    NSIndexSet(index: self.tableView.rowForView(self)),
                    byExtendingSelection: false
                )
            }
            
            (textView as! CommandLineTextView).onResignedFirstResponder = { [unowned self] in
                if !textView.editable {
                    self.textView.setSelectedRange(NSRange(location: (textView.string! as NSString).length ?? 0, length: 0))
                }
            }
            
            dummyTextField.onBecomeFirstResponder = { [unowned self] in
                self.window!.makeFirstResponder(self.textView)
                if !self.textView.editable {
                    self.textView.selectAll(nil)
                }
            }
        }
    }
    
    func textView(textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        switch commandSelector {
        case "insertNewline:":
            cell!.runCommand()
            return true
        case "cancelOperation:":
            textView.window?.makeFirstResponder(self.tableView)
            return true
        default:
            return false
        }
    }
    
    func textView(textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
        return []
    }
}

class TerminalViewController: NSViewController {
    @IBOutlet private var tableView: NSTableView!
    
    private var document: Document {
        get { return representedObject as! Document }
    }
}

extension TerminalViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return document.history.count
    }
}

extension TerminalViewController: NSTableViewDelegate, NSControlTextEditingDelegate {
    
    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let view = tableView.makeViewWithIdentifier("Row", owner: nil) as! NSTableRowView
        return view
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if document.selectedHistoryEntry == row {
            dispatch_after(0, dispatch_get_main_queue(), {
                tableView.editColumn(0, row: row, withEvent: nil, select: false)
            })
        }
        let view = tableView.makeViewWithIdentifier(document.history[row].viewIdentifier, owner: nil) as! NSTableCellView
        return view
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        // This is terrible, I'm in hate with NSTableView right now
        switch document.history[row] {
        case let cell as WorkingDirectoryCell:
            return (cell.path as NSString).sizeWithAttributes([
                NSFontAttributeName: NSFont.systemFontOfSize(NSFont.smallSystemFontSize())
            ]).height + 2
        case _ as CommandLineCell:
            return NSString().sizeWithAttributes([
                NSFontAttributeName: AppDefaults.shared.monospacedFont!
            ]).height
        case _ as TaskCell:
            return 10
        default: preconditionFailure()
        }
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return document.history[row]
    }
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return (tableView.viewAtColumn(0, row: row, makeIfNecessary: false) as! CellView).selectable
    }
}