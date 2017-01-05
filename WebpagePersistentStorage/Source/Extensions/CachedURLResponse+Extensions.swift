//
//  CachedURLResponse+Extensions.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/13/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

extension CachedURLResponse {

    var wps_contentType: String? {
        let result = (response as? HTTPURLResponse)?.allHeaderFields["Content-Type"] as? String
        return result
    }
    
    var wps_url: URL? {
        let result = (response as? HTTPURLResponse)?.url
        return result
    }


    func wps_base64DataURI(_ contentTypeFallback: String = "application/octet-stream") -> String {
        let contentType = self.wps_contentType ?? contentTypeFallback
        let base64 = data.base64EncodedString()
        let dataURI = "data:\(contentType);base64,\(base64)"
        return dataURI
    }

}

