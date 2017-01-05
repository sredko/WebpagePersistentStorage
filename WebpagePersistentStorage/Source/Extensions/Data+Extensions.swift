//
//  Data+Extensions.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/14/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//


import Foundation
import CommonCrypto

extension Data {

    func wps_hexString() -> String {
        var string = String()
        withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
            for i in UnsafeBufferPointer<UInt8>(start: bytes, count: count) {
                string += NSString(format:"%02x", i) as String
            }
        }
        return string
    }

    func wps_MD5() -> Data {
    
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))!

        withUnsafeBytes { (bytes: UnsafePointer<UInt8>) -> Void in
            let p = result.mutableBytes.assumingMemoryBound(to: UInt8.self)
            CC_MD5(bytes, CC_LONG(count), p)
        }
        
        return (NSData(data: result as Data) as Data)
    }

}
