//
//  CSSURLOwnedNode.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/27/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation
import libxml2


// wrapper for xmlNode which  content is either CSS URL or CSS string itself
// CSS content can have external URLs that should be replaced by locally stored data and or in-lined data
class CSSURLOwnedNode : GenericURLOwnedNode {
    
    // originalURLString is CSS reference of url string in format: url('...')
    typealias CSSURLInfo = (url: URL, originalURLString: String, cachedResponse:CachedURLResponse?)

    private var cssURLInfos = [CSSURLInfo]()
    func addURLFromCSS(with info: CSSURLInfo) {
        cssURLInfos.append(info)
    }

    var cssString: String? {
        
        var result: String?
        if  nil != contentURL {
            // if content is CSS URL, try use data from cache if any to get CSS data
            if let data = cachedResponse?.data {
                result = String(data: data, encoding: .utf8)
            }
        }
        else if let contentPtr = xmlNodeGetContent(node) {
            // if no CSS URL provided, process content as CSS string (<style> tag)
            result = String(cString: contentPtr).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            xmlFree(contentPtr)
        }
        
        return result
    }

    override func processReplacingURLByDataURI() -> Bool {

        var result = false

        if let cssString = cssString {
            
            // replace in CSS string occurances of external URLs with local data/URLs
            cssURLInfos.forEach({ (info: CSSURLInfo) in
            
                if let dataURI = info.cachedResponse?.wps_base64DataURI() {

                    _ = cssString.replacingOccurrences(of: info.originalURLString, with: dataURI, options: String.CompareOptions(rawValue: 0), range: nil)
                }
                else {
                    print("CSS URL \(result ? "" : "NOT") in Cache: \(info.url)")
                }
            })

            var newContent: String?
            if nil != contentURL {
                let contentType = cachedResponse?.wps_contentType ?? "text/css"
                if let base64 = cssString.data(using: .utf8)?.base64EncodedString() {
                    newContent = "data:\(contentType);base64,\(base64)"
                }
            }
            else {
               newContent = cssString
            }
            
            if let newContent = newContent {
                setNodeContent(newContent)
                result = true
            }
        }

        DDLog("URL \(result ? "" : "NOT") in Cache: \(contentURL)")
        return result
    }
    
    
    override func processSavingCachedURLResponse(withStorage storage: LocalStorage) -> Bool {

        var result = false
        
        if  let cachedResponse = cachedResponse,
            let contentURL = contentURL {
            result = storage.storeCachedResponse(cachedResponse, for: URLRequest(url: contentURL))
        }

        cssURLInfos.forEach({ (info: CSSURLInfo) in

            if  let cachedResponse = info.cachedResponse {
                result = storage.storeCachedResponse(cachedResponse, for: URLRequest(url: info.url))
            }
        })
        
        return result
    }


}
