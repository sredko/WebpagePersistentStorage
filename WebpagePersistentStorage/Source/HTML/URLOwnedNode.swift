//
//  URLOwnedNode.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/13/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation


// wrapper for xmlNode which content is/has external resource URL that
// for purpose of offline storage should be relaced by reference to 
// locally or in-line stored data

protocol URLOwnedNode : class {
    
    var contentURL: URL? { get }
    
    // inject dataURI instead of URLs (inline content type + base64 encoded data)
    // returns false if URL not replaced because of no cached data for it
    func processReplacingURLByDataURI() -> Bool

    // saves as system CachedURLResponse instance if present for the URL
    // returns false if no Cached URL Response present for URL
    func processSavingCachedURLResponse(withStorage storage: LocalStorage) -> Bool


    // saves cached for URL data locally and replaces original URL with local file URL
    // returns false if no cached for URL data present
    func processReplacingURLByLocalFileURL() -> Bool
}

