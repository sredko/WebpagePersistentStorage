//
//  CSSURLExtractor.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/14/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

class CSSURLExtractor {
    
    let cssString: String
    
    init(withCSSString cssString:String) {
        self.cssString = cssString
    }

    func extractURLs(_ handler: (_ urlString: String, _ stringInCSSToReplace:String) -> (Void)) {
        
        //TODO: add parsing of @import ...; that can have external resources
        let regex = "url\\(.*?\\)"
        if let regex = try? NSRegularExpression(pattern: regex, options: []) {

            let nsString = cssString as NSString
            let results  = regex.matches(in: cssString, options: [], range: NSMakeRange(0, nsString.length))
            
            results.forEach({ (result: NSTextCheckingResult) in
                (0..<result.numberOfRanges).forEach({ (i:Int) in
                    let range = result.rangeAt(i)
                    if range.location != NSNotFound {
                        let cssURLString = nsString.substring(with: range)
                        // skip 'url' before (...)
                        var value = (cssURLString as NSString).substring(from: 3)
                        // trim () and optional quotes 'url' "url"
                        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "(\"')"))
                        
                        if  !value.hasPrefix("data:") {
                            handler(value, cssURLString)
                        }
                    }
                })
            })
        }
    }
}
