//
//  PageCacheSession.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/24/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import UIKit

internal class PageCacheSession : NSObject {

    typealias Completion = (_ session: PageCacheSession, _ error: Error?) -> (Void)

    enum State: Int {
        case created
        case running
        case completed
    }

    let pageRequest: PageRequest

    internal let pageSaverFactory: PageSaverFactory

    internal let responseProvider: CacheResponseProvider

    internal var webView: UIWebView { return pageRequest.webView }

    internal var state: State = .created

    internal var completionHandler: Completion?

    // Cached responses associated with session
    internal var associatedResponses = [String: CachedURLResponse]()

    // cached URL strings of all request's.mainDocumentURL
    fileprivate var associatedDocumentAccess = SyncAccess()
    fileprivate var associatedDocumentURLStrings = Set<String>()
    
    internal init(with pageRequest: PageRequest, responseProvider: CacheResponseProvider,  pageSaverFactory: PageSaverFactory, completionHandler: @escaping Completion) {
        self.pageRequest = pageRequest
        self.pageSaverFactory = pageSaverFactory
        self.responseProvider = responseProvider
        self.completionHandler = completionHandler
    }

    internal var originalWebViewDelegate: UIWebViewDelegate?
    
    func start() {
    
        assert(Thread.isMainThread)
        assert(state == .created)
        state = .running
        
        var shouldLoadWebView = true
        if pageRequest.options.contains(.preferUsageCacheOverNetwork) {
            shouldLoadWebView = false
        }
        
        if shouldLoadWebView {
            // load web view to have needed external data (CSS, images) in system cache
            originalWebViewDelegate = webView.delegate
            webView.delegate = self
            webView.loadRequest(pageRequest.urlRequest)
        }
        else {
            processCachedResponse()
        }
    }
    
    
    internal func processCachedResponse() {

        assert(Thread.isMainThread)
        assert(state == .running)

        if !pageRequest.shouldStorePersistently {
            // no sence for preferUsageCacheOverNetwork
            reportCompletion()
            return
        }

        let url = pageRequest.url

        DDLog("Start caching of page with URL: [\(url)]")

        // get initial page html data response
        let cachedResponse = responseProvider.cachedResponse(for: url)

        var pageSaver = pageSaverFactory.makePageSaver(withURL: url, pageResponse: cachedResponse)
        
        if pageRequest.options.contains(.useRenderedByWebViewHTML) {
            // use processed by web view html
            let htmlString = webView.stringByEvaluatingJavaScript(from: "document.documentElement.outerHTML")
            pageSaver.webViewHTMLData = htmlString?.data(using: .utf8)
        }
        
        if let htmlPageData = pageSaver.htmlPageData {

            DDLog("cachePage [\(url)]: page found in cache")

            // process HTML data
            if  let websiteURL = url.wps_websiteURL(),
                let htmlDocument = MutableHTMLDocumentImpl(with: websiteURL, htmlData: htmlPageData, responseProvider: responseProvider) {
                
                pageSaver.associatedResponses = associatedResponses
                pageSaver.savePage(htmlDocument, { (error: Error?) -> (Void) in
                    self.reportCompletion(error)
                })
            }
            else {
                reportCompletion(WPSError.malformedHTMLDocument.nsError())
            }
        }
        else {
            DDLog("cachePage [\(url)]: not in cache")
            reportCompletion(WPSError.requiredDataNotFoundInCache.nsError())
        }
    }

    internal func reportCompletion(_ error: Error? = nil) {

        DDLog("End caching of page with URL: [\(pageRequest.url)]")
        state = .completed
        DispatchQueue.main.async {
            if let completionHandler = self.completionHandler {
                completionHandler(self, error)
            }
        }
    }
    
    internal func registerIfRelated(_ response: CachedURLResponse, for request: URLRequest) {

        DDLog("registerIfRelated: resp: \(response.wps_url?.wps_normalizedURLString()), request \(request.url?.wps_normalizedURLString()) main_Doc: \(request.mainDocumentURL?.wps_normalizedURLString()) ")

        if let responseURLString = response.wps_url?.wps_normalizedURLString(),
           let requestURLString = request.url?.wps_normalizedURLString() {
           
            assert(responseURLString == requestURLString)
            
            if let requestMainDocURLString = request.mainDocumentURL?.wps_normalizedURLString(),
                associatedDocumentAccess.immutable ({ associatedDocumentURLStrings.contains(requestMainDocURLString)}) {

                associatedResponses[responseURLString] = response
            }
            else {
                // for debug only since work for single running session only
                assert(false)
            }
        }
        else {
            assert(false)
        }
    }
}


// MARK: - UIWebViewDelegate

extension PageCacheSession : UIWebViewDelegate {

    internal func webViewDidStartLoad(_ webView: UIWebView) {
    
        assert(Thread.isMainThread)
        assert(state == .running)

        if let originalDelegate = originalWebViewDelegate {
            originalDelegate.webViewDidStartLoad?(webView)
        }
    }
    
    internal func webViewDidFinishLoad(_ webView: UIWebView) {

        assert(Thread.isMainThread)
        assert(state == .running)

        if let originalDelegate = originalWebViewDelegate {
            originalDelegate.webViewDidFinishLoad?(webView)
        }

        var isComplete = true
        if let completedHandler = pageRequest.completedHandler {
            isComplete = completedHandler(pageRequest)
        }
        
        if isComplete == true {
            // web view load completed
            webView.stopLoading()
            webView.delegate = originalWebViewDelegate
            
            processCachedResponse()
        }
    }
    
    internal func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {

        assert(Thread.isMainThread)
        assert(state == .running)

        DDLog("WebView loadError: \(error)")

        if let originalDelegate = originalWebViewDelegate {
            originalDelegate.webView?(webView, didFailLoadWithError: error)
        }

        if let nsError = error as NSError?,
            nsError.code == NSURLErrorCancelled  {
                // ignore this error http://stackoverflow.com/a/1053411/1084997
                return
        }

        reportCompletion(error)
    }


    internal func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        assert(Thread.isMainThread)
        assert(state == .running)

        // ignore some URLs
        if request.url?.absoluteString == "about:blank" {
            return false
        }

        DDLog("shouldStartLoadWith: \(request.wps_urlAbsoluteString) mainDocURL: \(request.mainDocumentURL?.wps_normalizedURLString())")
        
        if let urlString = request.mainDocumentURL?.wps_normalizedURLString() {
            associatedDocumentAccess.mutable {
                associatedDocumentURLStrings.insert(urlString)
            }
        }

        if let originalDelegate = originalWebViewDelegate {
            return originalDelegate.webView?(webView, shouldStartLoadWith: request, navigationType: navigationType) ?? true
        }

        return true
    }
}
