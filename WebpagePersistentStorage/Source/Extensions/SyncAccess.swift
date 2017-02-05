//
//  Synchronizer.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 2/3/17.
//  Copyright © 2017 Serhiy Redko. All rights reserved.
//

import Foundation


class SyncAccess {
    
    @discardableResult
    func mutable<T>(_ block: () -> T) -> T {
        objc_sync_enter(self)
        let value: T = block()
        objc_sync_exit(self)
        return value
    }

    @discardableResult
    func immutable<T>(_ block: () -> T) -> T {
        return mutable(block)
    }
}
