//
//  UIWebView+Extensions.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 3/17/17.
//  Copyright © 2017 Serhiy Redko. All rights reserved.
//

import UIKit


extension UIWebView {

    func wps_loadedPageData(_ encoding: String.Encoding = .utf8) -> Data? {
        let htmlString = stringByEvaluatingJavaScript(from: "document.documentElement.outerHTML")
        let result = htmlString?.data(using: encoding)
        return result
    }
}

