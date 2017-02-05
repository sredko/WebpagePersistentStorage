//
//  CachedURLResponsesLocalStorage.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 1/3/17.
//  Copyright © 2017 Serhiy Redko. All rights reserved.
//

import Foundation

class CachedURLResponsesLocalStorage : LocalStorage {

    fileprivate let searchPathDirectory: FileManager.SearchPathDirectory
    fileprivate let path: String
    fileprivate var storageBaseURL: URL?
    fileprivate let queue = DispatchQueue(label: "WebpagePersistentStorage.CachedURLResponsesLocalStorage")
    fileprivate let fileManager = FileManager()
    

    init(path: String?, searchPathDirectory: FileManager.SearchPathDirectory) {
        self.path = path ?? "webCache/"
        self.searchPathDirectory = searchPathDirectory
    }

    func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) -> Bool {
        var result = false

        if let hash = request.wps_MD5() {
            queue.sync {
                result = save(cachedResponse, hash)
            }
        }

        DDLog("LocalStorage stored [\(result)]: \(request.wps_urlAbsoluteString)")
        return result
    }
    
    func storeCachedResponses(_ cachedResponses: [CachedURLResponse], _ completion: @escaping LocalStorageCompletion) {

        queue.async {

            var error: NSError?
            cachedResponses.forEach({ (cachedResponse: CachedURLResponse) in
                if let hash = cachedResponse.wps_url?.wps_MD5() {
                    if !self.save(cachedResponse, hash) {
                        error = WPSError.diskStorageFailure.nsError()
                    }
                }
                else {
                    assert(false)
                }
            })
            
            completion(error)
        }
    }

    func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        var result: CachedURLResponse?
        
        if let path = filePathURL(for: request)?.path {
            queue.sync {
                result = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? CachedURLResponse
            }
        }

        DDLog("LocalStorage retrieved [\(result)]: \(request.wps_urlAbsoluteString)")
        return result
    }
    

    fileprivate func save(_ object: NSCoding, _ hash: String) -> Bool {

        if #available(iOS 10.0, *) {
            dispatchPrecondition(condition: .onQueue(queue))
        }
        
        var result = false
        if  let path = filePathURL(forRequestHash: hash)?.path {
            let data = NSKeyedArchiver.archivedData(withRootObject: object)
            do {
                try data.write(to: URL(fileURLWithPath: path), options: [])
                result = true
            } catch {
                DDLog("LocalStorage error writing request to disk: \(error)")
            }
        }
    
        return result
    }

    
    fileprivate func filePathURL(forRequestHash hash: String) -> URL? {
        var result: URL?
        if let baseURL = storageURL() {
            result = URL(string: hash, relativeTo: baseURL)
        }
        return result
    }
    
    fileprivate func filePathURL(for request: URLRequest) -> URL? {
        var url: URL?
        if  let hash = request.wps_MD5(),
            let baseURL = storageURL() {
            url = URL(string: hash, relativeTo: baseURL)
        }
        return url
    }
    

    fileprivate func storageURL() -> URL? {
        
        if let storageBaseURL = storageBaseURL {
            return storageBaseURL
        }

        if  let baseURL = try? fileManager.url(for: searchPathDirectory,
                in: .userDomainMask, appropriateFor: nil, create: false),
            let fileURL = URL(string: path, relativeTo: baseURL) {
            var isDir: ObjCBool = false
            if !fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDir) {
                do {
                    try fileManager.createDirectory(at: fileURL, withIntermediateDirectories: true, attributes: nil)
                    let status = fileURL.wps_addSkipBackupAttribute()
                    assert(status)
                } catch {
                    print("Error creating directory at URL: \(fileURL)")
                }
            }
            
            storageBaseURL = fileURL
            DDLog("Created local cache URL: \(storageBaseURL?.absoluteString)")
        }

        return storageBaseURL
    }

    func remove(responseForURL url: URL) -> Bool {
        var result = false
        if  let hash = url.wps_MD5(),
            let baseURL = storageURL() {
            if let fileURL = URL(string: hash, relativeTo: baseURL) {
                queue.sync {
                    do {
                        try fileManager.removeItem(at: fileURL)
                        result = true
                    } catch {
                        print("remove responseForURL [\(error)]: \(url)")
                    }
                }
            }
        }

        DDLog("remove responseForURL [\(result)]: \(url)")
        return result
    }

    func clear() {

        if let url = storageURL() {
            queue.sync {
                do {
                    try fileManager.removeItem(at: url)
                    storageBaseURL = nil
                } catch {
                    print("Error clearCache [\(error)]: \(url)")
                }
            }
        }
    }
}
