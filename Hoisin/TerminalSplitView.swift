import Cocoa

private let dragZoneWidth: CGFloat = 2

extension NSView {
    var terminalSplitView: TerminalSplitView? {
        get {
            for var view: NSView? = self; view != nil; view = view!.superview {
                if let terminalSplitView = view as? TerminalSplitView {
                    return terminalSplitView
                }
            }
            return nil
        }
    }
}

class TerminalSplitView: NSView {
    
    private weak var parent: TerminalSplitView? = nil
    private var views: [NSView] = []
    private var viewConstraints: [NSLayoutConstraint] = []
    private var vertical = false

    private func sharedInit() {
        wantsLayer = true
        layer!.backgroundColor = NSColor.whiteColor().CGColor
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    func insertChildView(view: NSView, atIndex index: Int) {
        views.insert(view, atIndex: index)
        if let view = view as? TerminalSplitView {
            view.parent = self
        }
        addSubview(view)
        rebuildConstraints()
    }
    
    func addChildView(view: NSView) {
        insertChildView(view, atIndex: views.count)
    }
    
    func splitChildView(view: NSView, newView: NSView, vertically: Bool) {
        if views.count == 1 {
            vertical = vertically
            addChildView(newView)
            return
        }
        
        let index = views.indexOf(view)!
        
        if vertically == vertical {
            insertChildView(newView, atIndex: index + 1)
            return
        }
        
        let newSplitView = TerminalSplitView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        newSplitView.translatesAutoresizingMaskIntoConstraints = false
        replaceSubview(view, with: newSplitView)
        views[index] = newSplitView
        newSplitView.vertical = vertically
        newSplitView.addChildView(view)
        newSplitView.addChildView(newView)
        rebuildConstraints()
    }
    
    private func rebuildConstraints() {
        NSLayoutConstraint.deactivateConstraints(viewConstraints)
        viewConstraints = []
        
        let widthMultiplier = 1 / CGFloat(views.count)
        for (i, view) in views.enumerate() {
            viewConstraints.append(NSLayoutConstraint(
                item: view, attribute: self.vertical ? .Height : .Width, relatedBy: .Equal,
                toItem: self, attribute: self.vertical ? .Height : .Width,
                multiplier: widthMultiplier, constant: -(CGFloat(views.count) - 1) * widthMultiplier
            ))
            viewConstraints.append(NSLayoutConstraint(
                  item: view, attribute: self.vertical ? .Bottom : .Right, relatedBy: .Equal,
                toItem: self, attribute: self.vertical ? .Bottom : .Right,
                multiplier: (CGFloat(i) + 1) * widthMultiplier, constant: -CGFloat(views.count - i - 1) / CGFloat(views.count)
            ))
            viewConstraints.append(NSLayoutConstraint(
                item: self,   attribute: self.vertical ? .Left : .Top, relatedBy: .Equal,
                toItem: view, attribute: self.vertical ? .Left : .Top,
                multiplier: 1, constant: 0
            ))
            viewConstraints.append(NSLayoutConstraint(
                  item: self, attribute: self.vertical ? .Right : .Bottom, relatedBy: .Equal,
                toItem: view, attribute: self.vertical ? .Right : .Bottom,
                multiplier: 1, constant: 0
            ))
        }
        
        NSLayoutConstraint.activateConstraints(viewConstraints)
        
    }
    
    private func positionOfZone(i: Int) -> CGFloat {
        return (vertical ? self.bounds.height : self.bounds.width) * (CGFloat(i) / CGFloat(views.count))
    }
    
    private func zoneIndex(point: NSPoint) -> Int? {
        if views.count == 0 { return nil }
        let pos = vertical ? point.y : point.x
        for i in 1..<views.count {
            let zonePos = positionOfZone(i)
            if pos > zonePos - dragZoneWidth && pos < zonePos + dragZoneWidth {
                return i
            }
        }
        return nil
    }
    
    override func resetCursorRects() {
        super.resetCursorRects()
        if views.count == 0 { return }
        
        let cursor = vertical ? NSCursor.resizeUpDownCursor() : NSCursor.resizeLeftRightCursor()
        
        for i in 1..<views.count {
            let pos = positionOfZone(i)
            if vertical {
                addCursorRect(NSRect(x: 0, y: pos - dragZoneWidth, width: bounds.width, height: dragZoneWidth * 2 + 1), cursor: cursor)
            } else {
                addCursorRect(NSRect(x: pos - dragZoneWidth, y: 0, width: dragZoneWidth * 2 + 1, height: bounds.height), cursor: cursor)
            }
        }
    }
    
    override func hitTest(point: NSPoint) -> NSView? {
        return zoneIndex(point) != nil ? self : super.hitTest(point)
    }
    
}