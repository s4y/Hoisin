import Cocoa

class RowView: NSTableRowView {
    static let storyboardIdentifier = "Row"
    
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