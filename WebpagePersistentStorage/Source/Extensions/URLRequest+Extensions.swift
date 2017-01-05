//
//  URLRequest+Extensions.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 1/3/17.
//  Copyright © 2017 Serhiy Redko. All rights reserved.
//

import Foundation

extension URLRequest {

    var wps_urlAbsoluteString: String {
        return url?.absoluteString ?? "[Missing URL]"
    }

    func wps_MD5() -> String? {
        return self.url?.wps_MD5()
    }
}
