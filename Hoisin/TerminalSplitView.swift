import Cocoa

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

class ContentView: NSView {
    
    private func sharedInit() {
        wantsLayer = true
        
        layer!.backgroundColor = NSColor.blueColor().CGColor
        
        func makeSplitButton(title: String, action: Selector, offset: CGFloat) {
            let splitButton = NSButton()
            
            splitButton.title = title
            splitButton.setButtonType(.MomentaryPushInButton)
            splitButton.bezelStyle = .RoundedBezelStyle
            
            splitButton.target = self
            splitButton.action = action
            
            splitButton.translatesAutoresizingMaskIntoConstraints = false
            addSubview(splitButton)
            
            NSLayoutConstraint(
                item: self, attribute: .CenterY, relatedBy: .Equal,
                toItem: splitButton, attribute: .CenterY, multiplier: 1, constant: offset
                ).active = true
            
            NSLayoutConstraint(
                item: self, attribute: .CenterX, relatedBy: .Equal,
                toItem: splitButton, attribute: .CenterX, multiplier: 1, constant: 0
                ).active = true
        }
        
        makeSplitButton("Split H", "splitH:", 15)
        makeSplitButton("Split V", "splitV:", -15)
        
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        sharedInit()
    }
    
    func split(vertical: Bool) {
        
    }
    
    func splitH(sender: NSButton) {
        terminalSplitView!.splitChildView(self, newView: makeContentView(), vertically: false)
    }
    
    func splitV(sender: NSButton) {
        terminalSplitView!.splitChildView(self, newView: makeContentView(), vertically: true)
    }
}

func makeContentView() -> ContentView {
    let view = ContentView(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
}

class TerminalSplitView: NSView {
    
    private weak var parent: TerminalSplitView? = nil
    private var views: [NSView] = []
    private var viewConstraints: [NSLayoutConstraint] = []
    private var vertical = false

    private func sharedInit() {
        wantsLayer = true
        layer!.backgroundColor = NSColor.greenColor().CGColor
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        sharedInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        insertChildView(makeContentView(), atIndex: views.count)
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
        
        let index = find(views, view)!
        
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
        for (i, view) in enumerate(views) {
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
    
    override func resetCursorRects() {
        super.resetCursorRects()
        
        let cursor = vertical ? NSCursor.resizeUpDownCursor() : NSCursor.resizeLeftRightCursor()
        let dragZoneWidth: CGFloat = 2
        
        for i in 1..<views.count {
            let pos = (vertical ? self.bounds.height : self.bounds.width) * (CGFloat(i) / CGFloat(views.count))
            if vertical {
                addCursorRect(NSRect(x: 0, y: pos - dragZoneWidth, width: bounds.width, height: dragZoneWidth * 2 + 1), cursor: cursor)
            } else {
                
            }
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        println("\(self) mouseDown: \(theEvent)")
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        println("\(self) mouseDragged: \(theEvent)")
    }
    
//    override func hitTest(aPoint: NSPoint) -> NSView? {
//        println("\(self) hit test: \(aPoint)")
//        return self
//    }
    
}