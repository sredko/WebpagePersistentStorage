//
//  XML+Extensions.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 1/5/17.
//  Copyright © 2017 Serhiy Redko. All rights reserved.
//

import Foundation
import libxml2


class XMLSupport {

    static func initialize() {
        xmlInitParser()
    }

    static func shutdown() {
        xmlCleanupParser()
    }
}

