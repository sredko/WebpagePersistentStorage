//
//  CachedURLResponsesPageSaver.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/26/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation


class CachedURLResponsesPageSaver : PageSaverBase {

    let storage: LocalStorage

    init(_ url: URL, pageResponse: CachedURLResponse?, storage: LocalStorage) {
        self.storage = storage
        super.init(url, pageResponse: pageResponse)
    }

    override func savePage(_ htmlDocument: MutableHTMLDocument, _ completion: @escaping PageSaveCompletion) {
    
        guard let cachedResponse = primaryCachedResponse else {
            assert(false)
            completion(WPSError.requiredDataNotFoundInCache.nsError())
            return
        }

        // save initial response in sdk local cache
        if !storage.storeCachedResponse(cachedResponse, for: URLRequest(url: url)) {
            print("Failed to save page main response in local cache")
            completion(WPSError.diskStorageFailure.nsError())
            return
        }
        
        // save responses for URLs found in HTML
        htmlDocument.getURLOwnedNodes { (_ error: Error?, nodes: [URLOwnedNode]?) in
            if let urlOwnedNodes = nodes {
                urlOwnedNodes.forEach { (urlNode: URLOwnedNode) in
                    // specify 'self' as localStorage to accumulate all associated
                    // responses and save at once, to avoid duplicates as captured 
                    // during session web view load and read from CSS 
                    if !urlNode.processSavingCachedURLResponse(withStorage: self) {
                        DDLog("Failed process node: \(urlNode.contentURL)")
                    }
                }

                // no modification of parsed HTML document performed, so no need to save document
                // htmlProcessor.saveDocument()

                // save all associated cached URL responses in SDK local cache to
                // return later when correpsonding URLs will be requested from 
                // URLProtocol system by loading WebView
                
                let cachedResponses = Array(associatedResponses.values)
                storage.storeCachedResponses(cachedResponses) { (error: Error?) in
                    DDLog("Session associated cache responses stored: \(error)")
                    completion(error)
                }
            }
            else {
                assert(nil != error)
                completion(error)
            }
        }
        
    }
}

