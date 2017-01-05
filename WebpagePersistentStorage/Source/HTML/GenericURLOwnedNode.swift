//
//  GenericURLOwnedNode.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/27/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation
import libxml2


// xmlNode wrapper that has content which is an external URL and should
// be replaced by locally stored data and or in-lined data
class GenericURLOwnedNode : URLOwnedNode {

    // xmlNode node itself, retrieved at time HTML document was parsed,
    // updated at time referenced by external URLs data stored locally
    // saved in final HTML document when content updated to reference locally stored data
    let node: UnsafePointer<xmlNode>
    
    // URL from this node's content. Might be missing since
    // e.g <style> doesn't have URL, but can include many URLs in its content which is CSS
    let contentURL: URL?
    
    // if content is URL this can have cached response for that URL
    let cachedResponse: CachedURLResponse?
    
    required init(node: UnsafePointer<xmlNode>, contentURL: URL?, cachedResponse:CachedURLResponse?) {
        self.node = node
        self.contentURL = contentURL
        self.cachedResponse = cachedResponse
    }

    func processReplacingURLByDataURI() -> Bool {

        var result = false
        if let dataURI = cachedResponse?.wps_base64DataURI() {
            setNodeContent(dataURI)
            result = true
        }

        DDLog("URL \(result ? "" : "NOT") in Cache: \(contentURL)")
        return result
    }


    func processSavingCachedURLResponse(withStorage storage: LocalStorage) -> Bool {

        var result = false
        if  let cachedResponse = cachedResponse,
            let contentURL = contentURL {
            result = storage.storeCachedResponse(cachedResponse, for: URLRequest(url: contentURL))
        }
        return result
    }


    func processReplacingURLByLocalFileURL() -> Bool {
        assert(false) // not impl yet
        return false
    }

    
    internal func setNodeContent(_ value: String?) {
        if let value = value {
            let nodePtr = xmlNodePtr(mutating: node)
            xmlNodeSetContent(nodePtr, value)
        }
    }
}


