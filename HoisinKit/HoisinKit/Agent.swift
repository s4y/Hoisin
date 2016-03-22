import Foundation

private class DummyClass: NSObject {}
private let bundle = NSBundle(forClass: DummyClass.self)

class Agent {
    private let queue = 
    private let task = NSTask()
    private let stdoutHandle: NSFileHandle
    
    init() {
        task.launchPath = bundle.pathForResource("hoisinagent", ofType: nil)!
        task.currentDirectoryPath = NSHomeDirectory()
        
        let stdoutPipe = NSPipe()
        stdoutHandle = stdoutPipe.fileHandleForReading
        task.standardOutput = stdoutPipe
        
        task.launch()
    }
    
    func connected() -> Bool {
        return task.running
    }
}