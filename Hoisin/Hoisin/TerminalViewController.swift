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
        let view = tableView.makeViewWithIdentifier(RowView.storyboardIdentifier, owner: nil) as! NSTableRowView
        return view
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if document.selectedHistoryEntry == row {
            dispatch_after(0, dispatch_get_main_queue(), {
                tableView.editColumn(0, row: row, withEvent: nil, select: false)
            })
        }
        let view = tableView.makeViewWithIdentifier((document.history[row] as! CellViewProvider).cellViewType.storyboardIdentifier, owner: nil) as! NSTableCellView
        return view
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return document.history[row]
    }
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return (tableView.viewAtColumn(0, row: row, makeIfNecessary: false) as! CellView).selectable
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        // This is terrible, I'm in hate with NSTableView right now
        return (document.history[row] as! CellViewProvider).cellViewType.computeHeight(document.history[row], width: tableView.frame.width)
    }
}