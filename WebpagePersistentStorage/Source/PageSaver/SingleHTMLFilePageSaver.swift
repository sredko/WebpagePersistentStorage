//
//  SingleHTMLFilePageSaver.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/26/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation


class SingleHTMLFilePageSaver : PageSaverBase {

    override func savePage(_ htmlDocument: MutableHTMLDocument, _ completion: PageSaveCompletion) {
    
        htmlDocument.getURLOwnedNodes { (_ error: Error?, nodes: [URLOwnedNode]?) in
            if let urlOwnedNodes = nodes {
                urlOwnedNodes.forEach { (urlNode: URLOwnedNode) in
                    if !urlNode.processReplacingURLByDataURI() {
                        DDLog("Failed process node: \(urlNode.contentURL)")
                    }
                }
                
                //if let documentData = htmlProcessor.documentData() {
                    // TODO save in page file
                //}
                
                completion(nil)
            }
            else {
                assert(nil != error)
                completion(error)
            }
        }
    }

}
