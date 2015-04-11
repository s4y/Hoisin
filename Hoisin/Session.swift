import WebKit

@objc protocol SessionJS: JSExport {
    var cells: [Cell] { get }
}

class Session: NSObject, SessionJS {
    
    var cells: [Cell] = [Cell()]
    
}