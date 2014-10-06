//
//  Document.swift
//  Hoisin
//
//  Created by Sidney San Martín on 8/19/14.
//  Copyright (c) 2014 s4y. All rights reserved.
//

import Cocoa
import WebKit

class HoisonURLProtocol : NSURLProtocol, NSURLConnectionDataDelegate {
    
    var connection: NSURLConnection? = nil
    
    override class func load() {
        NSURLProtocol.registerClass(self)
    }
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        if request.URL.scheme == "hoisin" {
            return true
        }
        return false
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override func startLoading() {
        if cachedResponse != nil {
            println("Will respond from cache with \(cachedResponse)")
            client!.URLProtocol(self, cachedResponseIsValid: cachedResponse!)
            return
        }
        connection = NSURLConnection(
            request: NSURLRequest(URL: NSBundle.mainBundle().URLForResource(
                "ui", withExtension: nil
                )!.URLByAppendingPathComponent(request.URL.path!)),
            delegate: self,
            startImmediately: true
        )

    }
    
    override func stopLoading() {
        self.connection!.cancel()
        self.connection = nil
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .AllowedInMemoryOnly)
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        self.client!.URLProtocol(self, didLoadData: data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        self.client!.URLProtocolDidFinishLoading(self)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.client!.URLProtocol(self, didFailWithError: error)
    }
}

@objc protocol DocumentJS: JSExport {
    func getenv() -> [String:String]
    func standardizePath(string: String) -> String
    
    // JSExport doesn't support constructors, this is a workaround
    func createTask([String]?) -> HoisinTaskJS
}

class Document: NSDocument, DocumentJS {
    
    @IBOutlet var webView: WebView?

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
                                    
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        
        webView!.frameLoadDelegate = self
        webView!.mainFrame.loadRequest(NSURLRequest(URL: NSURL(string: "hoisin://ui/index.html")!))
//        webView!.mainFrame.loadRequest(NSURLRequest(URL: NSBundle.mainBundle().URLForResource(
//            "index", withExtension: "html", subdirectory: "ui"
//        )))
    }

    override class func autosavesInPlace() -> Bool {
        return false // until we make saving work
    }

    override var windowNibName: String {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return "Document"
    }

    override func dataOfType(typeName: String?, error outError: NSErrorPointer) -> NSData? {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return nil
    }

    override func readFromData(data: NSData?, ofType typeName: String?, error outError: NSErrorPointer) -> Bool {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
        outError.memory = NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        return false
    }
    
    // MARK: - WebFrameLoadDelegate
    
    override func webView(sender: WebView!, didCommitLoadForFrame frame: WebFrame!) {
        frame.windowObject.JSValue().setValue(self, forProperty: "os")
    }

    // MARK: - JavaScript API
    
    func getenv() -> [String:String] {
        return NSProcessInfo.processInfo().environment as [String:String]
    }
    
    func standardizePath(string: String) -> String {
        return NSURL(fileURLWithPath: string.stringByStandardizingPath)!.path!
    }
    
    func createTask(argv: [String]?) -> HoisinTaskJS {
        let task = HoisinTask()
        if let argv = argv {
            task.argv = argv
        }
        return task
    }
}

