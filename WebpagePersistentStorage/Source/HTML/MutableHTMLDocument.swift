//
//  HTMLProcessor.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/13/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation
import libxml2


typealias GetURLOwnedNodesCompletionHandler = (_ error: Error?, _ nodes: [URLOwnedNode]?) -> Void

protocol MutableHTMLDocument {
    
    func getURLOwnedNodes(_ completion: GetURLOwnedNodesCompletionHandler)

    func documentData() -> Data?

}


//MARK :-

fileprivate let kXpathExpr = "//link/@href|//a/@href|//script/@src|//img/@src|//frame/@src|//iframe/@src|//style|//*/@style|//source/@src|//video/@poster|//audio/@src";

class MutableHTMLDocumentImpl : MutableHTMLDocument {

    private let responseProvider: CacheResponseProvider

    private let wps_websiteURL: URL
	private var xmlDoc: UnsafeMutablePointer<xmlDoc>!
    private var urlOwnedNodes = [URLOwnedNode]()

    init?(with wps_websiteURL:URL, htmlData: Data, responseProvider: CacheResponseProvider) {
        self.wps_websiteURL = wps_websiteURL
        self.responseProvider = responseProvider

        htmlData.withUnsafeBytes { (bytes: UnsafePointer<Int8>) -> Void in
            let options = HTML_PARSE_NONET.rawValue | HTML_PARSE_NOWARNING.rawValue | HTML_PARSE_NOERROR.rawValue
            let encoding = xmlGetCharEncodingName(XML_CHAR_ENCODING_UTF8)
            xmlDoc = UnsafeMutablePointer<xmlDoc>(htmlReadMemory(bytes, Int32(htmlData.count), "", encoding, Int32(options)))
        }
        
        guard xmlDoc != nil else {
            DDLog("Error reading html document: \(wps_websiteURL)")
            return nil
        }
    }

    deinit {
        xmlFreeDoc(xmlDoc)
        xmlDoc = nil
    }
  
 
    func getURLOwnedNodes(_ completion: GetURLOwnedNodesCompletionHandler) {

        urlOwnedNodes.removeAll()
        
        guard let xpathCtx = UnsafeMutablePointer<xmlXPathContext>(xmlXPathNewContext(xmlDoc)) else {
            DDLog("Failed create xpath context")
            completion(WPSError.malformedHTMLDocument.nsError(), nil)
            return
        }
        defer { xmlXPathFreeContext(xpathCtx) }
        
        guard let xpathObj = UnsafeMutablePointer<xmlXPathObject>(xmlXPathEvalExpression(kXpathExpr, xpathCtx)) else {
            DDLog("Failed evaluate xpath")
            completion(WPSError.malformedHTMLDocument.nsError(), nil)
            return
        }
        defer { xmlXPathFreeObject(xpathObj) }

        guard let nodeInfoSet = UnsafeMutablePointer<xmlNodeSet>(xpathObj.pointee.nodesetval) else {
            return
        }

        let nodesCount = nodeInfoSet.pointee.nodeNr
        let allXmlNodesPtr = nodeInfoSet.pointee.nodeTab
        
        for i in 0..<nodesCount {
            
            guard let node = UnsafePointer<xmlNode>(allXmlNodesPtr?[Int(i)]) else {
                DDLog("Warning: failed get xpath node")
                continue
            }

            var parentNodeName: String?
            if let parentNode = UnsafePointer<xmlNode>(node.pointee.parent) {
                if let parentNodeNamePtr = parentNode.pointee.name {
                    parentNodeName = String(cString: parentNodeNamePtr).lowercased()
                }
            }

            guard let parentName = parentNodeName else {
                DDLog("Warning: failed get parent node name")
                continue
            }

            // Filter <link> tags to use only stylesheet
            if parentName == "link" {
                if let relAttribute = xmlGetNoNsProp(node.pointee.parent, "rel") {
                    let rel = String(cString: relAttribute).lowercased()
                    xmlFree(relAttribute)
                    if rel == "stylesheet" {
                        process(node)
                    }
                }
            }
            else if parentName == "source" || parentName == "audio" {
                //TODO: add support for video/audio for now via configs
                assert(false)
            
            } else if parentName != "a" {
                process(node)
            }
        }
        
        completion(nil, urlOwnedNodes)
    }

    // review with something DataConvertible, NSCoder or so
    func documentData() -> Data? {

        let buffer = xmlBufferCreate()
        let saveContext = xmlSaveToBuffer(buffer, nil , Int32(XML_SAVE_NO_DECL.rawValue))
        defer { xmlBufferFree(buffer) }
        
        xmlSaveDoc(saveContext, xmlDoc)
        xmlSaveClose(saveContext)
        
        if let rawPointer = buffer?.pointee.content,
            let count = buffer?.pointee.use {
            let result = Data(bytes:rawPointer, count: Int(count))
            return result
        }
        
        return nil
    }

    /// create and register wrapper for xmlNode that have URL in content
    /// and corresponding URL's cached response if any in cache.
    private func process(_ node:UnsafePointer<xmlNode>) {

        var nodeName: String?
        if let nodeNamePtr = node.pointee.name {
            nodeName = String(cString: nodeNamePtr).lowercased()
        }
        
        if nodeName == "style" {
            // Parse the content of <style> tags and style attributes to 
            // find external image URLs or external CSS files
            process(CSSNode: node, contentURL: nil, cachedResponse: nil, cssWebsiteURL: wps_websiteURL)
            return
        }

        var nodeContent: String?
        if let contentPtr = xmlNodeGetContent(node) {
            nodeContent = String(cString: contentPtr).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            xmlFree(contentPtr)
        }

        guard let urlString = nodeContent,
            // Don't attempt to fetch data URIs
            !urlString.hasPrefix("data:") else {
            return
        }
    
        // resource from html can actually reside on different host, so resolve URL correctly
        guard let url = wps_websiteURL.wps_websiteResourceURL(referencedBy: urlString) else {
            DDLog("Failed to make URL for resource \(urlString)")
            return
        }

        // get cached response if any for this URL
        let cachedResponse = responseProvider.cachedResponse(for: url)
        if let contentType = cachedResponse?.wps_contentType,
            contentType == "text/css" {

            // in case we have cached response and it is css data
            // extract URLs from CSS content where they stored in url(...) or @import 'file'
            if let websiteURL = url.wps_websiteURL() {
                process(CSSNode: node, contentURL: url, cachedResponse: cachedResponse, cssWebsiteURL: websiteURL)
            }
            else {
                assert(false)
            }
        }
        else {
            // process as regular node with URL as content
            let urlNode = GenericURLOwnedNode(node: node, contentURL: url, cachedResponse: cachedResponse)
            urlOwnedNodes.append(urlNode)
        }
    }
    
    // process CSS related node
    private func process(CSSNode node:UnsafePointer<xmlNode>, contentURL: URL?, cachedResponse: CachedURLResponse?, cssWebsiteURL: URL) {
        
        let urlNode = CSSURLOwnedNode(node: node, contentURL: contentURL, cachedResponse: cachedResponse)
        urlOwnedNodes.append(urlNode)
    
        if let cssString = urlNode.cssString {
        
            let urlExtractor = CSSURLExtractor(withCSSString: cssString)
            urlExtractor.extractURLs { (urlString: String, stringInCSSToReplace:String) in

                if let resourceURL = cssWebsiteURL.wps_websiteResourceURL(referencedBy: urlString) {
                    let cachedResponse = responseProvider.cachedResponse(for: resourceURL)
                    let cssURLInfo = CSSURLOwnedNode.CSSURLInfo(url: resourceURL, originalURLString: stringInCSSToReplace, cachedResponse: cachedResponse)
                    urlNode.addURLFromCSS(with: cssURLInfo)
                }
            }
        }
    }
    
}

