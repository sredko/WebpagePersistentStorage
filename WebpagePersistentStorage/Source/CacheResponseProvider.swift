//
//  CacheResponseProvider.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/13/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

/// provider of cached responces from system cache.
/// provided cached responces will be save in local storage 
/// for later usage

protocol CacheResponseProvider {
    func cachedResponse(for url:URL) -> CachedURLResponse?
}

class CacheResponseProviderImpl: CacheResponseProvider {

    func cachedResponse(for url:URL) -> CachedURLResponse? {
        let request = NSURLRequest(url: url)
        
        if let wpsCache = Foundation.URLCache.shared as? WPSCache {
            let cachedResponse = wpsCache.getSessionCachedResponse(for:request as URLRequest)
            return cachedResponse
        }
        
        return nil
    }
}

