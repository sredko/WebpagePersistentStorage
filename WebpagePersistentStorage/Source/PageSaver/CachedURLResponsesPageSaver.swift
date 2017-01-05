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

    override func savePage(_ htmlDocument: MutableHTMLDocument, _ completion: PageSaveCompletion) {
    
        guard let cachedResponse = primaryCachedResponse else {
            assert(false)
            completion(WPSError.requiredDataNotFoundInCache)
            return
        }
    
        // save initial response in sdk local cache
        if !storage.storeCachedResponse(cachedResponse, for: URLRequest(url: url)) {
            print("Failed to save page main response in local cache")
            completion(WPSError.diskStorageFailure)
            return
        }

        htmlDocument.getURLOwnedNodes { (_ error: Error?, nodes: [URLOwnedNode]?) in
            if let urlOwnedNodes = nodes {
                urlOwnedNodes.forEach { (urlNode: URLOwnedNode) in
                    // save all found cached URL responses in SDK local cache to
                    // return later when correpsonding URLs will be requested from 
                    // URLProtocol system by loading WebView
                    if !urlNode.processSavingCachedURLResponse(withStorage: storage) {
                        DDLog("Failed process node: \(urlNode.contentURL)")
                    }
                }

                // no modification of parsed HTML document performed 
                // so no need to save document
                // htmlProcessor.saveDocument()
                
                completion(nil)
            }
            else {
                assert(nil != error)
                completion(error)
            }
        }
        
    }

}
