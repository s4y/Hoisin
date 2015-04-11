import Foundation
import WebKit

@objc protocol HistoryEntryJS: JSExport {
    var type: String { get }
}

@objc protocol HistoryEntry: HistoryEntryJS {}

protocol CwdHistoryEntryProtocol: HistoryEntry {
    var path: String { get }
}

class CwdHistoryEntry: NSObject, CwdHistoryEntryProtocol {
    var type: String { get { return "cwd" } }
    var path: String
    
    init(path: String) {
        self.path = path
    }
    
}

@objc protocol CellJS: JSExport {
    var runningTask: Task? { get }
    var history: [HistoryEntry] { get }
    var cwd: Cwd { get set }
}

class Cell: NSObject, CellJS {
    
    var runningTask: Task? = nil
    var history: [HistoryEntry] = []
    var cwd: Cwd {
        didSet {
            history.append(CwdHistoryEntry(path: cwd.path))
        }
    }
    
    override init() {
        cwd = Cwd.at("~") ?? Cwd.at("/")!
        history.append(CwdHistoryEntry(path: cwd.path))
        super.init()
    }
}