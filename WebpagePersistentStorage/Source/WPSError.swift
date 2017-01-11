//
//  WPSError.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 1/10/17.
//  Copyright © 2017 Serhiy Redko. All rights reserved.
//

import Foundation

public let WPSErrorDomain = "WPSErrorDomain"

public enum WPSError : Int  {
    case requiredDataNotFoundInCache = 1
    case malformedHTMLDocument
    case diskStorageFailure
}


internal extension WPSError {

    func nsError(_ message: String? = nil) -> NSError {
        var userInfo: [AnyHashable: Any]? = nil
        if let message = message {
            userInfo = [NSLocalizedDescriptionKey: message]
        }
        return NSError(domain: WPSErrorDomain, code: self.rawValue, userInfo: userInfo)
    }
}
