import Cocoa

protocol TerminalCell: NSObjectProtocol {
    // TODO: Saving/restoring, etc.
}

class WorkingDirectoryCell: NSObject, TerminalCell {
    let path: String
    
    init(path: String) {
        self.path = path
    }
}

class CommandLineCell: NSObject, TerminalCell {
    dynamic var command: String? = nil
    dynamic var locked: Bool = false
    
    func runCommand() {
        print("command \(command) gogogo")
        locked = true
    }
}

class TaskCell: NSObject, TerminalCell {}