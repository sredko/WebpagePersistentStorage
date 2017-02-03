//
//  URL+Extensions.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/14/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

extension URL {

    func wps_normalizedURLString() -> String {

        let result = absoluteString.trimmingCharacters(in: CharacterSet(charactersIn:"/ "))
        return result
    }

    func wps_normalizedURL() -> URL? {

        let result = URL(string: wps_normalizedURLString())
        return result
    }


    func wps_websiteURL() -> URL? {
    
        var result:URL?
        if  let rootURL = URL(string:"/", relativeTo:self) {
            result = rootURL.wps_normalizedURL()
        }
        return result
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
        return wps_normalizedURLString().wps_MD5()
    }
    
    func wps_addSkipBackupAttribute() -> Bool {

        guard isFileURL else {
            assert(false)
            return false
        }

        guard FileManager.default.fileExists(atPath: self.path) else {
            assert(false)
            return false
        }

        var result: Bool
        do {

            // looks like current XCode8 issues prevent correct remmed code below
            // to not work, so NSURL workarounds applied
            
            //var values = URLResourceValues()
            //values.isExcludedFromBackup = true
            //try self.setResourceValues(values)
            try (self as NSURL).setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
            result = true
        } catch let error as NSError {
            result = false
            print("Error excluding \(lastPathComponent) from backup \(error)");
        }
 
        return result
    }
    
}
