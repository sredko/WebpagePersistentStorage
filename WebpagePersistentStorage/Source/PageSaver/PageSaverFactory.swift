//
//  PageSaverFactory.swift
//  WebpagePersistentStorage
//
//  Created by Serhiy Redko on 12/26/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import Foundation


protocol PageSaverFactory {

    func makePageSaver(withURL url: URL, pageResponse: CachedURLResponse?) -> PageSaverProtocol
    
}


class PageSaverFactoryImpl : PageSaverFactory {

    let pageStorageType: PageStorageType
    let localStorage: LocalStorage

    init(withStorageType type: PageStorageType, localStorage storage: LocalStorage) {
    
        self.pageStorageType = type
        self.localStorage = storage
    }

    func makePageSaver(withURL url: URL, pageResponse: CachedURLResponse?) -> PageSaverProtocol {
        
        var result: PageSaverProtocol!
        switch pageStorageType {
            case .storePageAsCachedURLResponses:
                result = CachedURLResponsesPageSaver(url, pageResponse: pageResponse, storage: localStorage)
                break
            case .storePageAsSingleHTMLFile:
                result = SingleHTMLFilePageSaver(url, pageResponse: pageResponse)
                break
            case .storePageAsLocalFiles:
                result = LocalFilesPageSaver(url, pageResponse: pageResponse)
                break
        }
        
        return result
    }

}
