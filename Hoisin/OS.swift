import Foundation
import WebKit

@objc protocol OSJS: JSExport {
    func getenv() -> [String:String]
    func standardizePath(string: String) -> String
    
    var sessions: [Session] { get }
    
    func createSession() -> Session
    
    func createTask(argv: [String]?) -> TaskJS
    func createCwd(path: String) -> CwdJS?
}

class OS: NSObject {
    var document: Document
    
    init(document: Document) {
        self.document = document
    }
}

extension OS: OSJS {

    var sessions: [Session] { get { return document.sessions } }
    
    func createSession() -> Session {
        let session = Session()
        document.sessions.append(session)
        return session
    }
    
    func getenv() -> [String:String] {
        return NSProcessInfo.processInfo().environment 
    }
    
    func standardizePath(string: String) -> String {
        return NSURL(fileURLWithPath: string).URLByStandardizingPath!.path!
    }
    
    func createTask(argv: [String]?) -> TaskJS {
        let task = Task()
        if let argv = argv {
            task.argv = argv
        }
        return task
    }
    
   func createCwd(path: String) -> CwdJS? {
        return Cwd.at(path)
    }
}

