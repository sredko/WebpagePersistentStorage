//
//  PageSaverProtocol.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/26/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

typealias PageSaveCompletion = (_ error: Error?) -> (Void)

internal protocol PageSaverProtocol {

    var webViewHTMLData: Data? { get set }
    
    var htmlPageData: Data? { get }

    var associatedResponses: [String: CachedURLResponse] { get set }

    func savePage(_ htmlDocument: MutableHTMLDocument, _ completion: @escaping PageSaveCompletion)
}


internal class PageSaverBase: PageSaverProtocol {

    let url: URL
    let pageResponse: CachedURLResponse?
    var associatedResponses = [String: CachedURLResponse]()
    private var processedHTMLResponse: CachedURLResponse?

    init(_ url: URL, pageResponse: CachedURLResponse?) {
        self.url = url
        self.pageResponse = pageResponse
    }

    var webViewHTMLData: Data? {
        didSet {
            if let data = webViewHTMLData {
                let urlResponse = URLResponse(url: url, mimeType: "text/html", expectedContentLength: data.count, textEncodingName: nil)
                processedHTMLResponse = CachedURLResponse(response: urlResponse, data: data)
            }
        }
    }

    var primaryCachedResponse: CachedURLResponse? {

        if let processedHTMLResponse = processedHTMLResponse {
            return processedHTMLResponse
        }

        if let pageResponse = pageResponse {
            return pageResponse
        }
        
        return nil
    }
    
    var htmlPageData: Data? {
        return primaryCachedResponse?.data
    }

    func savePage(_ htmlDocument: MutableHTMLDocument, _ completion: @escaping PageSaveCompletion) {
        assert (false)
    }

}

// WARNING: potential memeory pressure on big pages
// Internal auxilary extension to act as localStorage to accumulate all associated
// responses and futher save at once, to avoid duplicates as captured
// during session web view load and read from CSS. 
extension PageSaverBase : LocalStorage {

    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) -> Bool {
        
        if let requestURLString = request.url?.wps_normalizedURLString() {
            associatedResponses[requestURLString] = cachedResponse
        }

        return true
    }

    func storeCachedResponses(_ cachedResponses: [CachedURLResponse], _ completion: @escaping LocalStorageCompletion) {
        assert(false)
    }

    func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        assert(false)
        return nil
    }

    func clear() {
        assert(false)
    }
    
    func remove(responseForURL url: URL) -> Bool {
        assert(false)
        return false
    }
}

