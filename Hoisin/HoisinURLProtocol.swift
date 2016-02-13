import Foundation

class HoisonURLProtocol : NSURLProtocol, NSURLConnectionDataDelegate {
    
    var connection: NSURLConnection? = nil
    
    override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        if request.URL!.scheme == "hoisin" {
            return true
        }
        return false
    }
    
    override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }
    
    override func startLoading() {
        if cachedResponse != nil {
            print("Will respond from cache with \(cachedResponse)")
            client!.URLProtocol(self, cachedResponseIsValid: cachedResponse!)
            return
        }
        connection = NSURLConnection(
            request: NSURLRequest(URL: NSBundle.mainBundle().URLForResource(
                "ui", withExtension: nil
                )!.URLByAppendingPathComponent(request.URL!.path!)),
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