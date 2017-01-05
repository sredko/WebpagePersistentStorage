//
//  LocalStorage.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 1/3/17.
//  Copyright © 2017 Serhiy Redko. All rights reserved.
//

import Foundation


protocol LocalStorage {

    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) -> Bool

    func cachedResponse(for request: URLRequest) -> CachedURLResponse?

    func clear()
    
    @discardableResult
    func remove(responseForURL url: URL) -> Bool
}


