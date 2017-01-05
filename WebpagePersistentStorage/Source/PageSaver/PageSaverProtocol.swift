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

    func savePage(_ htmlDocument: MutableHTMLDocument, _ completion: PageSaveCompletion)
}


internal class PageSaverBase: PageSaverProtocol {

    let url: URL
    let pageResponse: CachedURLResponse?
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

    func savePage(_ htmlDocument: MutableHTMLDocument, _ completion: PageSaveCompletion) {
        assert (false)
    }

}
