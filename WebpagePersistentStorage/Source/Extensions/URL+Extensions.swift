//
//  URL+Extensions.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/14/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

extension URL {

    func wps_websiteURL() -> URL {
    
        var result:URL?
        if let rootURL = URL(string:"/", relativeTo:self) {
            result = URL(string: rootURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn:"/ ")))
        }
        return result!
    }


    // this should be called for "website URL"
    func wps_websiteResourceURL(referencedBy urlString:String) -> URL?
    {
        var result: URL?
        if urlString.hasPrefix("//") {
            result = URL(string: "\(self.scheme!):" + urlString, relativeTo: nil)
        }
        else {
            result = URL(string: urlString, relativeTo: self)
        }
        
        return result
    }

    func wps_MD5() -> String? {
        return absoluteString.trimmingCharacters(in: CharacterSet(charactersIn:"/ ")).wps_MD5()
    }
}
