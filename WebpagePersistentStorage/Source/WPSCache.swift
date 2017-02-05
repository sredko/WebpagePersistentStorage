//
//  WebCache.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/10/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

class WPSCache: URLCache {
    
    // Precense of cached response in cache is VERY system cache behaviour dependent and cannot be 
    // guaranteed. TransientCache used to keep all intercepted cached responses during WebView loads

    // MARK:-
    fileprivate var cacheAccess = SyncAccess()
    fileprivate var transientCache = [String: CachedURLResponse]()
    
    public override init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
        super.init(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: path)
    }

    deinit {
    }

    // MARK:-
    override open func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        DDLog("WPSCache store: \(request.wps_urlAbsoluteString)")
        storeInTransientCacheResponse(cachedResponse, for:request)
        super.storeCachedResponse(cachedResponse, for: request)
    }

    override open func cachedResponse(for request: URLRequest) -> CachedURLResponse? {

        if let cachedResponse = super.cachedResponse(for: request) {
            DDLog("WPSCache found: \(request.wps_urlAbsoluteString)")
            storeInTransientCacheResponse(cachedResponse, for:request)
            return cachedResponse
        }
        
        DDLog("WPSCache NOT found: \(request.wps_urlAbsoluteString)")
        return nil
    }
    
    override open func removeCachedResponse(for request: URLRequest) {
    
        DDLog("WPSCache removeCachedResponse: \(request.wps_urlAbsoluteString)")
        super.removeCachedResponse(for: request)
    }
    
    override open func removeAllCachedResponses() {
        DDLog("WPSCache removeAllCachedResponses")
        super.removeAllCachedResponses()
    }

    override open func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) {
        DDLog("WPSCache storeCachedResponse for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString)")
        
        if let request = dataTask.currentRequest {
            storeInTransientCacheResponse(cachedResponse, for: request)
        }
        
        super.storeCachedResponse(cachedResponse, for: dataTask)
    }

    override open func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: @escaping (CachedURLResponse?) -> Swift.Void) {

        DDLog("WPSCache getCachedResponse for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString)")

        let completion : (CachedURLResponse?) -> Swift.Void = { (cachedResponse: CachedURLResponse?) in
    
            DDLog("getCachedResponse \(cachedResponse) for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString) ]")
            if let response = cachedResponse,
               let request = dataTask.currentRequest {
                self.storeInTransientCacheResponse(response, for: request)
            }
            completionHandler(cachedResponse)
        }
    
        super.getCachedResponse(for: dataTask, completionHandler: completion)
    }

    override open func removeCachedResponse(for dataTask: URLSessionDataTask) {
        DDLog("WPSCache removeCachedResponse for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString)")
        super.removeCachedResponse(for: dataTask)
    }
    
    // MARK:-
    internal func storeInTransientCacheResponse(_ response: CachedURLResponse, for request: URLRequest) {

        if  let sessionManager = PageManager.shared?.sessionManager,
            sessionManager.hasRunningSessions(),
            let urlString = response.wps_url?.wps_normalizedURLString() {

            // responses during page load can be initiated by JS code (e.g read JSON file and get URLs from there). Such URLs are not present in HTML so there is no hint to store such response in local cache. To resolve it register corresponding responses with session to store them anyway at the end of page caching
            
            cacheAccess.mutable {
                transientCache[urlString] = response
                sessionManager.registerIfRelated(response, for: request)
            }
        }
    }
    
    internal func clearTransientCache() {
        cacheAccess.mutable {
            transientCache.removeAll()
        }
    }


    // called during HTML parsing to get cached URL responses for found URLs in HTML
    func getSessionCachedResponse(for request: URLRequest) -> CachedURLResponse? {

        if let cachedResponse = super.cachedResponse(for: request) {
            DDLog("WPSCache found.: \(request.wps_urlAbsoluteString)")
            return cachedResponse
        }
        else if let urlString = request.url?.wps_normalizedURLString(),
            let cachedResponse = cacheAccess.immutable({ return transientCache[urlString]}) {
    
            DDLog("WPSCache found..: \(request.wps_urlAbsoluteString)")
            return cachedResponse
        }
        
        DDLog("WPSCache NOT found.: \(request.wps_urlAbsoluteString)")
        return nil
    }

}
