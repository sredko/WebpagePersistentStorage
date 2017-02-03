//
//  WebpagePersistentStorageTests.swift
//  WebpagePersistentStorageTests
//
//  Created by Serhiy Redko on 1/4/17.
//  Copyright © 2017 Serhiy Redko. All rights reserved.
//

import XCTest
@testable import WebpagePersistentStorage

class WebpagePersistentStorageTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        let isOfflineHandler: (() -> Bool) = {
            return false//!self.reachabilityReportsOnline
        }
        
        let config = PageManager.Config(isOfflineHandler:isOfflineHandler,
            pageStorageType: nil, cacheMemoryCapacityMB: nil, cacheDiskCapacityMB: nil, cacheDiskPath: nil)
        
        PageManager.makeSharedInstance(withConfig: config)
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSuccessLoad() {

        PageManager.shared.removeAllPages()
        XCTAssertTrue(PageManager.shared.pages.count == 0)

        let url = URL(string: "https://www.military.com/daily-news/2016/11/21/russia-deploys-new-missiles-baltic-sea-region.html?variant=mobile.app&hidebreadcrumb=yes")!

        XCTAssertNil(PageManager.shared.localStorage.cachedResponse(for: URLRequest(url: url)))
        
        let expectation = self.expectation(description: "completion")
        
        let options: PageRequest.Options = []
        let pageRequest = PageRequest(with: url, options: options)
        pageRequest.start(completion: { (result: PageRequest.Result) -> (Void) in

            switch result {
                case .success:
                XCTAssertTrue(PageManager.shared.pages.count == 1)
                XCTAssertTrue(PageManager.shared.pages.contains(url))
                XCTAssertNotNil(PageManager.shared.localStorage.cachedResponse(for: URLRequest(url: url)))

                PageManager.shared.remove(pageWithURL: url)
                XCTAssertTrue(PageManager.shared.pages.count == 0)
                XCTAssertFalse(PageManager.shared.pages.contains(url))
                XCTAssertNil(PageManager.shared.localStorage.cachedResponse(for: URLRequest(url: url)))
                
                break
                
                case .failed(let error):
                    XCTFail("error: \(error)")
                break
            }
            
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 20)
    }


    func testErrorLoad() {

        PageManager.shared.removeAllPages()

        let url = URL(string: "https://www.hopenoonemakesuchdomain.com/someresource")!
        
        let expectation = self.expectation(description: "completion")
        
        let options: PageRequest.Options = []
        let pageRequest = PageRequest(with: url, options: options)
        pageRequest.start(completion: { (result: PageRequest.Result) -> (Void) in

            switch result {
                case .success:
                XCTFail("Should not succeed")
                break
                
                case .failed(let error):
                    XCTAssertFalse(PageManager.shared.pages.contains(url))
                    XCTAssertTrue(nil != (error as NSError?))
                break
            }
            
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 20)
    }
    
}
