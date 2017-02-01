//
//  WPSProtocol.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/16/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

/// WPSProtocol registered with URL Loading System to process 
/// requests when app is offline and provide responses from 
/// system persistent local storage
class WPSProtocol: URLProtocol {

    class func register(_ shouldRegister: Bool) {
        DDLog("WPSProtocol register:\(shouldRegister)")
        if shouldRegister {
            registerClass(self)
        } else {
            unregisterClass(self)
        }
    }
    
    fileprivate class func shouldLoad(_ request: URLRequest) -> Bool {
        var result = false
        if  let pageManager = PageManager.shared,
            let url = request.url {
    
            // ideally would be to use hasCacheSession(for: url), but now
            // consider that WPSProtocol shoud not handle anything at time 
            // when caching session is running since we assume network is ok
            // and if it is not a true error will be reported during page cache
            if !pageManager.sessionManager.hasRunningSessions() { 
                result = pageManager.isOfflineHandler()
            }
        }
        return result
    }

    lazy var session: URLSession = {
        let configuration = URLSession.shared.configuration
        // let attempt to load data presumably being offline with small timeout
        configuration.timeoutIntervalForRequest = 10.0
        return Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()

    private var dataTask: URLSessionDataTask?

    // MARK:-
    override class func canInit(with request: URLRequest) -> Bool {
        // just ignore all data URI for now, since no issues found with possibly
        // referenced in them external content
        if let isDataURI = request.url?.absoluteString.hasPrefix("data:"), isDataURI {
            return false
        }

        let shouldLoad = self.shouldLoad(request)
        DDLog("WPSProtocol \(shouldLoad ? "" : "NOT") handled: \(request.wps_urlAbsoluteString)")
        return shouldLoad
    }

    override init(request: URLRequest, cachedResponse: CachedURLResponse?, client: URLProtocolClient?) {
        DDLog("WPSProtocol create: \(request.wps_urlAbsoluteString), cachedResponse: \(cachedResponse)")
        super.init(request: request, cachedResponse: cachedResponse, client: client)
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    // MARK:-
    override func startLoading() {

        DDLog("WPSProtocol startLoading: \(request.wps_urlAbsoluteString)")

        // try to get cached response from system/sdk local storage
        var cachedResponseToUse = cachedResponse
        if  nil == cachedResponseToUse,
            let cachedResponse = URLCache.shared.cachedResponse(for: request),
            let response = cachedResponse.response as? HTTPURLResponse,
            response.statusCode < 400 {

            cachedResponseToUse = cachedResponse
        }

        if  nil == cachedResponseToUse,
            let pageManager = PageManager.shared {
            cachedResponseToUse = pageManager.localStorage.cachedResponse(for: request)
            if nil != cachedResponseToUse {
                DDLog("Response found in local cache: \(request.wps_urlAbsoluteString)")
            }
        }

        // in case cached response found mark it as valid for usage
        if let cachedResponse = cachedResponseToUse {
            DDLog("WPSProtocol: found cachedResponse for \(request.wps_urlAbsoluteString)")
            client?.urlProtocol(self, cachedResponseIsValid: cachedResponse)
            return
        }

        // no cached response found and this code supposed to work for offline mode
        // currently in case reachability handler reports no connection just give up an report error. 
        // The logic is don't make pre-flight assumptions, but always try to perform network requests with dataTask. Currently observing issues for iOS 10.x simulator only(?) that leads to 60 sec timeouts for non important requests that block whole view rendering. Session configuration  set to have timeout 10 sec instead of 60
        DDLog("WPSProtocol: no cache found, load: \(request.wps_urlAbsoluteString)")

        // let isOffline = WPSProtocol.isOffline()
        // if isOffline {
        //    // this is workaround, review it, no pre-flight checks should be performed
        //    client?.urlProtocol(self, didFailWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil))
        //}
        //else {
            // this should be correct way to go
            dataTask = session.dataTask(with: request)
            dataTask?.resume()
        //}
    }

    override func stopLoading() {
        DDLog("WPSProtocol: stopLoading: \(request.wps_urlAbsoluteString)")
        dataTask?.cancel()
        dataTask = nil
    }

}

// MARK:-

extension WPSProtocol: URLSessionDataDelegate {

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        completionHandler(.allow)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .allowed)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        client?.urlProtocol(self, didLoad: data)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DDLog("WPSProtocol error: \(error)")
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        } else {
            client?.urlProtocolDidFinishLoading(self)
        }
    }
}
