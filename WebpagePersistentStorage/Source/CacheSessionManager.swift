//
//  CacheSessionManager.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/24/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation



internal class CacheSessionManager {
    
    private var sessions = [PageCacheSession]()
    
    internal func makeCacheSession(for pageRequest: PageRequest, completion: @escaping PageCacheSession.Completion) -> PageCacheSession {

        assert(Thread.isMainThread)
        
        // create page cache session with completion that unregisters session
        // with manager when its done
        let pageSaverFactory = PageManager.shared.pageSaverFactory
        let responseProvider = PageManager.shared.responseProvider
        let result = PageCacheSession(with: pageRequest, responseProvider:responseProvider, pageSaverFactory: pageSaverFactory) { (_ session: PageCacheSession, _ error: Error?) -> Void in

            assert(Thread.isMainThread)
            
            // its correct to have strongly referenced self here
            if let i = self.sessions.index(of: session) {
                self.sessions.remove(at: i)
            }
            else {
                fatalError("unknown session: \(session)")
            }
            
            // and call original completion closure
            completion(session, error)
            
            if  0 == self.sessions.count,
                let wpsCache = Foundation.URLCache.shared as? WPSCache {
                wpsCache.clearTransientCache()
            }
        }

        sessions.append(result)
        return result
    }

    func hasRunningSessions() -> Bool {
        return sessions.count > 0
    }
    
    func registerIfRelated(_ response:CachedURLResponse, for request: URLRequest) {

        sessions.forEach { (session: PageCacheSession) in
            session.registerIfRelated(response, for: request)
        }
    }

}
