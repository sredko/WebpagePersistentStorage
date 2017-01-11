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
    // guarnteed. Other direction to investigate is extend WPSCache to intercept all cached responses 
    // that can belong PageCacheSession and store them in temporary LocalStorage's cache 
    // to be requested right after WebView loads

    // TODO: review: workaround to prevent ignoring of cache resposponse saving.
    // this is the only change from system cache for now
    // without it for just loaded web view, cached responses for major URLs are missing in cache
    // this issue seems require us to have this custom WPSCache class (. 
    override open var diskCapacity: Int {
        set (value) { }
        get { return 1024 * 1024 * 150 } // 150Mb
    }

    // MARK:-

    public override init(memoryCapacity: Int, diskCapacity: Int, diskPath path: String?) {
        super.init(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: path)
    }

    deinit {
    }

    // MARK:-

    override open func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        DDLog("WPSCache store: \(request.wps_urlAbsoluteString)")
        super.storeCachedResponse(cachedResponse, for: request)
    }

    override open func cachedResponse(for request: URLRequest) -> CachedURLResponse? {

        if let cachedResponse = super.cachedResponse(for: request) {
            DDLog("WPSCache found: \(request.wps_urlAbsoluteString)")
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
        super.storeCachedResponse(cachedResponse, for: dataTask)
    }

    override open func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: @escaping (CachedURLResponse?) -> Swift.Void) {

        DDLog("WPSCache getCachedResponse for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString)")
        super.getCachedResponse(for: dataTask, completionHandler: completionHandler)

        // left for near future tracking/investigation purposes
        //    let completion : (CachedURLResponse?) -> Swift.Void = { (cachedResponce: CachedURLResponse?) in
        //
        //        DDLog("getCachedResponse \(cachedResponce) for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString) ]")
        //        completionHandler(cachedResponce)
        //    }
        //
        //    super.getCachedResponse(for: dataTask, completionHandler: completion)
    }

    override open func removeCachedResponse(for dataTask: URLSessionDataTask) {
        DDLog("WPSCache removeCachedResponse for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString)")
        super.removeCachedResponse(for: dataTask)
    }
}
