//
//  WebCache.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/10/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

open class WPSCache: URLCache {
    
    // TODO: review: workaround to prevent ignoring of cache resposponse saving
    // this is the only change from system cache for now
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
        DDLog("Cache store: \(request.wps_urlAbsoluteString)")
        super.storeCachedResponse(cachedResponse, for: request)
    }

    override open func cachedResponse(for request: URLRequest) -> CachedURLResponse? {

        if let cachedResponse = super.cachedResponse(for: request) {
            DDLog("Cache found: \(request.wps_urlAbsoluteString)")
            return cachedResponse
        }
        
        DDLog("Cache NOT found: \(request.wps_urlAbsoluteString)")
        return nil
    }
    
    override open func removeCachedResponse(for request: URLRequest) {
    
        DDLog("removeCachedResponse: \(request.wps_urlAbsoluteString)")
        super.removeCachedResponse(for: request)
    }
    
    override open func removeAllCachedResponses() {
        DDLog("removeAllCachedResponses")
        super.removeAllCachedResponses()
    }

    override open func storeCachedResponse(_ cachedResponse: CachedURLResponse, for dataTask: URLSessionDataTask) {
        DDLog("storeCachedResponse for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString)")
        super.storeCachedResponse(cachedResponse, for: dataTask)
    }

    override open func getCachedResponse(for dataTask: URLSessionDataTask, completionHandler: @escaping (CachedURLResponse?) -> Swift.Void) {

        DDLog("[ getCachedResponse for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString)")
        
        let completion : (CachedURLResponse?) -> Swift.Void = { (cachedResponce: CachedURLResponse?) in
        
            DDLog("getCachedResponse \(cachedResponce) for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString) ]")
            completionHandler(cachedResponce)
        }
        
        super.getCachedResponse(for: dataTask, completionHandler: completion)
    }

    override open func removeCachedResponse(for dataTask: URLSessionDataTask) {
        DDLog("removeCachedResponse for dataTask \(dataTask.currentRequest?.wps_urlAbsoluteString)")
        super.removeCachedResponse(for: dataTask)
    }
}
