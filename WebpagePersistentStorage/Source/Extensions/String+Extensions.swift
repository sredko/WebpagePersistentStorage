//
//  String+Extensions.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/15/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

extension String {

    func wps_MD5() -> String? {
        return self.data(using: .utf8)?.wps_MD5().wps_hexString()
    }
}
