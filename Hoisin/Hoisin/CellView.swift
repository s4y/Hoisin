import Cocoa

private class DummyTextField: NSTextField {
    
    var onBecomeFirstResponder: (() -> ())?
    
    override func becomeFirstResponder() -> Bool {
        onBecomeFirstResponder?()
        return true
    }
}

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

protocol CellViewProvider {
    var cellViewType: CellView.Type { get }
}

class CellView: NSTableCellView {
    class var storyboardIdentifier: String { preconditionFailure() }
    class func computeHeight(cell: TerminalCell, width: CGFloat) -> CGFloat { preconditionFailure() }
    
    @IBOutlet private weak var tableView: NSTableView!
    
    var selectable: Bool { return true }
    
    private lazy var dummyTextField: DummyTextField = {
        let dummyTextField = DummyTextField(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        self.textField = dummyTextField
        self.addSubview(dummyTextField)
        return dummyTextField
    }()
}

// MARK: - TaskCellView

class TaskCellView: CellView {
    override class var storyboardIdentifier: String { return "Task" }
    override class func computeHeight(cell: TerminalCell, width: CGFloat) -> CGFloat {
        return ("foo\nbar" as NSString).boundingRectWithSize(NSSize(width: width - 5, height: CGFloat.max),
            options: .UsesLineFragmentOrigin,
            attributes: [
                NSFontAttributeName: AppDefaults.shared.monospacedFont!
            ],
            context: nil
        ).height + 2
    }
    
    override var textField: NSTextField? {
        didSet {
            guard let textField = textField else { return }
            textField.font = AppDefaults.shared.monospacedFont!
        }
    }
}

extension TaskCell: CellViewProvider { var cellViewType: CellView.Type { return TaskCellView.self } }

// MARK: - WorkingDirectoryCellView

class WorkingDirectoryCellView: CellView {
    override class var storyboardIdentifier: String { return "Working Directory" }
    override class func computeHeight(cell: TerminalCell, width: CGFloat) -> CGFloat {
        return ((cell as! WorkingDirectoryCell).path as NSString).sizeWithAttributes([
            NSFontAttributeName: NSFont.systemFontOfSize(NSFont.smallSystemFontSize())
        ]).height + 2
    }
    
    override var selectable: Bool { return false }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer!.backgroundColor = NSColor(calibratedWhite: 0.95, alpha: 1).CGColor
    }
}

extension WorkingDirectoryCell: CellViewProvider { var cellViewType: CellView.Type { return WorkingDirectoryCellView.self } }

// MARK: - CommandLineCellView

class CommandLineCellView: CellView, NSTextViewDelegate {
    override class var storyboardIdentifier: String { return "Command Line" }
    override class func computeHeight(cell: TerminalCell, width: CGFloat) -> CGFloat {
        return NSString().sizeWithAttributes([
            NSFontAttributeName: AppDefaults.shared.monospacedFont!
        ]).height
    }
    
    private var cell: CommandLineCell? { return objectValue as? CommandLineCell }
    
    @IBOutlet weak private var promptView: NSTextField! {
        didSet {
            promptView.font = AppDefaults.shared.monospacedFont!
        }
    }
    @IBOutlet private var textView: CommandLineTextView! {
        didSet {
            guard let textView = textView else { return }
            textView.font = AppDefaults.shared.monospacedFont!
            textView.textContainerInset = NSSize(width: 0, height: 2)
            let textContainer = textView.textContainer!
            textContainer.widthTracksTextView = false
            textContainer.size = NSSize(width: CGFloat.max, height: CGFloat.max)
            
            textView.onBecameFirstResponder = { [unowned self] in
                self.tableView.selectRowIndexes(
                    NSIndexSet(index: self.tableView.rowForView(self)),
                    byExtendingSelection: false
                )
            }
            
            textView.onResignedFirstResponder = { [unowned self] in
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
        case #selector(NSResponder.insertNewline(_:)):
            cell!.runCommand()
            return true
        case #selector(NSResponder.cancelOperation(_:)):
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

extension CommandLineCell: CellViewProvider { var cellViewType: CellView.Type { return CommandLineCellView.self } }