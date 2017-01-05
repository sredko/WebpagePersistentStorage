//
//  PageManager.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/24/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation
import libxml2


fileprivate let kIndexName = "webpage-index.plist"

public enum WPSError : Error  {
    case requiredDataNotFoundInCache
    case malformedHTMLDocument
    case diskStorageFailure
}


public enum PageStorageType : Int {

    // [ this is default ]
    // Save page as bunch of CachedURLResponses (each per fetched external URL)
    // in SDK cache. Original HTML is not modified (unless loaded with .useRenderedByWebViewHTML)
    case storePageAsCachedURLResponses

    // Save page as single HTML file with external URLs replaced by base64 
    // encoded data URIs. Can impact memory for some pages
    case storePageAsSingleHTMLFile

    // [ not currently implemented ]
    // Store page as HTML file  with external URLs replaced by URLs to local files
    case storePageAsLocalFiles
}


public class PageManager {

    public static var shared: PageManager!

    public static func makeSharedInstance(_ isOfflineHandler: @escaping (() -> (Bool)), pageStorageType: PageStorageType = .storePageAsCachedURLResponses) {

        if nil == shared {
        
            shared = PageManager(isOfflineHandler, pageStorageType: pageStorageType)

            let Mb = 1024 * 1024
            
            // have not switched to system yet  becasue it doesn't cache some major requests
            // without hacks, see overriden diskCapacity of WPSCache
            // Foundation.URLCache.shared = Foundation.URLCache(memoryCapacity: 30 * MB, diskCapacity: 150 * MB, diskPath: nil)

            // do we need this cache at all?
            let urlCache = WPSCache(memoryCapacity: 30 * Mb, diskCapacity: 150 * Mb, diskPath: nil)
            Foundation.URLCache.shared = urlCache
        }
        else {
            print("PageManager makeSharedInstance ignored, already setup")
        }
    
    }

    internal let pageStorageType: PageStorageType

    internal let isOfflineHandler: () -> (Bool)
    
    internal let sessionManager = CacheSessionManager()
    
    internal var pages = Set<URL>()
    
    internal var localStorage: LocalStorage
    
    internal let pageSaverFactory: PageSaverFactory
    
    internal let responseProvider: CacheResponseProvider

    private init(_ isOfflineHandler: @escaping (() -> (Bool)), pageStorageType: PageStorageType) {
        self.isOfflineHandler = isOfflineHandler
        self.pageStorageType = pageStorageType
        
        self.localStorage = CachedURLResponsesLocalStorage(path: nil, searchPathDirectory: .documentDirectory)
        
        self.pageSaverFactory = PageSaverFactoryImpl(withStorageType: pageStorageType, localStorage: localStorage)
        self.responseProvider = CacheResponseProviderImpl()
        xmlInitParser()
        readIndex()

        WPSProtocol.register(true)
    }

    deinit {
        WPSProtocol.register(false)
    }

    public func allPages() -> [URL] {
        return Array(pages)
    }
    
    public func remove(pageWithURL url: URL) {
        DDLog("Remove page: \(url)")
        localStorage.remove(responseForURL: url)
        pages.remove(url)
        if pages.count == 0 {
            removeAllPages()
        }
    }

    public func removeAllPages() {
        localStorage.clear()
        pages.removeAll()
        saveIndex()
    }
}

internal extension PageManager {
    
    internal func add(pageWithURL url:URL) {
        DDLog("Add page: \(url)")
        pages.insert(url)
        saveIndex()
    }
}


extension PageManager {

    internal class func indexURL() throws -> URL {
        let baseURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let indexURL = URL(fileURLWithPath: kIndexName, relativeTo: baseURL)
        return indexURL
    }

    internal func saveIndex() {
        do {
            let indexURL = try PageManager.indexURL()
            if !NSKeyedArchiver.archiveRootObject(pages, toFile: indexURL.path) {
                print("Failed save web cache index: \(indexURL)")
            }
        } catch {
            print("Failed locate web cache index to save")
        }
    }

    internal func readIndex() {
        do {
            pages.removeAll()
            let indexURL = try PageManager.indexURL()
            let indexPath = indexURL.path
            if FileManager.default.fileExists(atPath: indexPath) {
                if let readPages = NSKeyedUnarchiver.unarchiveObject(withFile: indexPath) as? Set<URL> {
                    pages = readPages
                }
                else {
                    print("Failed read web cache index: \(indexURL)")
                }
            }
        } catch {
            print("Failed locate web cache index to read")
        }
    }
}
