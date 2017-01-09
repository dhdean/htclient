//
//  HTClient.swift
//
//  Created by Daniel Dean on 12/18/16.
//

import Foundation

public typealias HTErrorCallback = (NSError?) -> Void
public typealias HTResponseCallback = (Data?, Int, NSError?) -> Void


/**
 ///////////////////////////////////////////////////////////////////////////////
 HTTP Request Configuration.
 ///////////////////////////////////////////////////////////////////////////////
 */
open class HTReq {
    open var body:Data?
    open var url:String?
    open var method:String = "POST"
    open var headers:[String:String]?
    open var cellular:Bool = true
    open var timeout:Int = 0
}


/**
 ///////////////////////////////////////////////////////////////////////////////
 URLRequest+HTClient
 ///////////////////////////////////////////////////////////////////////////////
 */
extension URLRequest {

    /**
     Create a new URLRequest using a given request configuration.
     
     - param request: The request configuration object
     
     - returns: initialized URLRequest
     */
    static func createWithHTReq(request: HTReq) -> URLRequest {
        var urlReq = URLRequest(url: URL(string: request.url!)!)
        urlReq.httpMethod = request.method
        urlReq.allowsCellularAccess = request.cellular
        urlReq.httpBody = request.body
        if (request.timeout > 0) {
            urlReq.timeoutInterval = Double(request.timeout)
        }
        for (key,value) in request.headers! {
            urlReq.setValue(value, forHTTPHeaderField: key)
        }
        return urlReq
    }
}

/**
 ///////////////////////////////////////////////////////////////////////////////
 HTClient
 ///////////////////////////////////////////////////////////////////////////////
 */
open class HTClient {
    
    private let sessionLock = NSLock()
    private var _urlSession: URLSession?
    var urlSession:URLSession? {
        get {
            self.sessionLock.lock()
            let urlSession = _urlSession
            self.sessionLock.unlock()
            if urlSession == nil {
                return URLSession.shared
            }
            return urlSession
        }
        set(urlSession) {
            self.sessionLock.lock()
            _urlSession = urlSession
            self.sessionLock.unlock()
        }
    }
    
    /**
     Begins an HTTP request for a given request configuration.
     
     - param request: The request configuration object
     - param handler: Completion handler fired when the request completes.
     
     - returns: The data task representation of the request.
     */
    @discardableResult
    open func dispatch(_ request: HTReq, handler: @escaping HTResponseCallback) -> URLSessionDataTask {
        return HTClient.dispatch(request, urlSession:self.urlSession!, handler:handler)
    }

    /**
     Begins an HTTP request for a given request configuration and session.
     
     - param request: The request configuration object
     - param urlSession: The URLSession instance to use for hte request. Defaults to the shared session.
     - param handler: Completion handler fired when the request completes.
     
     - returns: The data task representation of the request.
     */
    @discardableResult
    open static func dispatch(_ request: HTReq, urlSession:URLSession=URLSession.shared, handler: @escaping HTResponseCallback) -> URLSessionDataTask {
        let req = URLRequest(url: URL(string: request.url!)!)
        
        let task = urlSession.dataTask(with: req as URLRequest, completionHandler: { (data, response, error) in
            handler(data, (response as! HTTPURLResponse).statusCode, error as NSError?)
        })
        task.resume()
        return task
    }

    /**
     Sets the client's active url session.
     
     - param urlSession: An initialized URLSession instance
     */
    open func updateURLSession(urlSession: URLSession) -> Void {
        self.urlSession = urlSession
    }
    
}
