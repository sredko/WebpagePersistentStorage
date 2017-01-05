//
//  NSLog+Config.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/20/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

#if DEBUG
    func DDLog(_ message: String, filename: String = #file, function: String = #function, line: Int = #line) {
        print("\(message)")
    }
#else
    func DDLog(_ message: String, filename: String = #file, function: String = #function, line: Int = #line) {
    }
#endif


