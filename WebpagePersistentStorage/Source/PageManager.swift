//
//  PageManager.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/24/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation

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

    // for missing value default will be used
    public typealias Config = (
        isOfflineHandler:(() -> (Bool)),
        pageStorageType: PageStorageType?,
        cacheMemoryCapacityMB: Int?,
        cacheDiskCapacityMB: Int?,
        cacheDiskPath: String?)

    public static func makeSharedInstance(withConfig config: Config) {

        if nil == shared {

            let pageStorageType = config.pageStorageType ?? .storePageAsCachedURLResponses

            let localStorage = CachedURLResponsesLocalStorage(path: nil, searchPathDirectory: .documentDirectory)
            let pageSaverFactory = PageSaverFactoryImpl(withStorageType: pageStorageType, localStorage: localStorage)
            let responseProvider = CacheResponseProviderImpl()

            shared = PageManager(config.isOfflineHandler,
                pageStorageType: pageStorageType,
                localStorage: localStorage,
                pageSaverFactory: pageSaverFactory,
                responseProvider: responseProvider)

            let Mb = 1024 * 1024
            
            // have not switched to system yet  becasue it doesn't cache some major requests
            // without hacks, see overriden diskCapacity of WPSCache
            let memoryCapacity = (config.cacheMemoryCapacityMB ?? 30) * Mb
            let diskCapacity = (config.cacheDiskCapacityMB ?? 150) * Mb
            let diskPath = config.cacheDiskPath

            let urlCache = WPSCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: diskPath)
            Foundation.URLCache.shared = urlCache
        }
        else {
            print("PageManager makeSharedInstance ignored, already setup")
        }
    
    }

    internal let pageStorageType: PageStorageType

    internal let isOfflineHandler: () -> (Bool)

    internal var localStorage: LocalStorage
    
    internal let pageSaverFactory: PageSaverFactory
    
    internal let responseProvider: CacheResponseProvider

    internal let sessionManager = CacheSessionManager()
    
    internal var pages = Set<URL>()
    
    fileprivate init(_ isOfflineHandler: @escaping (() -> (Bool)), pageStorageType: PageStorageType, localStorage: LocalStorage, pageSaverFactory: PageSaverFactory, responseProvider: CacheResponseProvider) {

        self.isOfflineHandler = isOfflineHandler
        self.pageStorageType = pageStorageType
        self.localStorage = localStorage
        self.pageSaverFactory = pageSaverFactory
        self.responseProvider = responseProvider

        XMLSupport.initialize()
        readIndex()
        WPSProtocol.register(true)
    }

    deinit {
        XMLSupport.shutdown()
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
            if NSKeyedArchiver.archiveRootObject(pages, toFile: indexURL.path) {
                let status = indexURL.wps_addSkipBackupAttribute()
                assert(status)
            }
            else {
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
