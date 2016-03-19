import Cocoa

protocol ViewIdentifierProvider {
    var viewIdentifier: String { get }
}

protocol TerminalCell: ViewIdentifierProvider, NSObjectProtocol {
    // TODO: Saving/restoring, etc.
}

class WorkingDirectoryCell: NSObject, TerminalCell {
    var viewIdentifier: String { return "Working Directory" }
    
    let path: String
    
    init(path: String) {
        self.path = path
    }
}

class CommandLineCell: NSObject, TerminalCell {
    var viewIdentifier: String { return "Command Line" }
    
    dynamic var command: String? = nil
    dynamic var locked: Bool = false
    
    func runCommand() {
        print("command \(command) gogogo")
        locked = true
    }
}

class TaskCell: NSObject, TerminalCell {
    var viewIdentifier: String { return "Task" }
}