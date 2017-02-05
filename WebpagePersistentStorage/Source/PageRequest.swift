//
//  PageRequest.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/23/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import UIKit

public struct PageRequest {

    public struct Options: OptionSet {

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let dontSavePagePersistently = Options(rawValue: 1 << 0)

        /// use HTML data from WebView after it rendered content, instead of HTML returned in response on document URL request.
        public static let useRenderedByWebViewHTML = Options(rawValue: 2 << 0)

        /// prefer to fetch page data for processing from local app caches over network access. Applicable for case when you know that data should be in cache, e.g because some WebView just fetched it or page was saved on disk earlier.
        public static let preferUsageCacheOverNetwork = Options(rawValue: 3 << 0)
    }

    public typealias CompletedHandler = (_ request: PageRequest) -> (Bool)
    public static let defaultRequestCompletedHandler: CompletedHandler =  { (_ request: PageRequest) -> (Bool) in
            let documentState = request.webView.stringByEvaluatingJavaScript(from: "document.readyState")
            return documentState == "complete"
        }

    public let url: URL

    public let options: PageRequest.Options

    public let webView: UIWebView
    
    public let completedHandler: CompletedHandler?
    
    public init(with url: URL, options: Options = [], webView: UIWebView? = nil, completedHandler: CompletedHandler? = PageRequest.defaultRequestCompletedHandler) {
        self.url = url
        self.options = options
        self.webView = webView ?? UIWebView()
        self.completedHandler = completedHandler
    }

}

extension PageRequest {

    internal var urlRequest: URLRequest {
        return URLRequest(url: url, cachePolicy:.reloadIgnoringLocalCacheData)
    }
    
    internal var shouldStorePersistently: Bool { return !options.contains(.dontSavePagePersistently) }
    
}


extension PageRequest {

    public enum Result {

        case success(response: PageResponse)

        case failed(Error)
    }
    
    public typealias Completion = (_ result: PageRequest.Result) -> (Void)

    public func start(completion: PageRequest.Completion? = nil) {

        assert(Thread.isMainThread)
    
        let session = PageManager.shared.sessionManager.makeCacheSession(for: self) { (session: PageCacheSession, error: Error?) -> (Void) in

            assert(Thread.isMainThread)
            if let error = error {
                completion?(.failed(error))
            }
            else {
                if self.shouldStorePersistently {
                    // save persistently cached page URL in index
                    PageManager.shared.add(pageWithURL: self.url)
                }
            
                completion?(.success(response: PageResponse()))
            }            
        }
        
        session.start()
    }
}



