//
//  AppDelegate.swift
//  WPSExampleApp
//
//  Created by Serhiy Redko on 12/18/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import UIKit
import WebpagePersistentStorage


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var webPageURLs: [URL]!
    var currentURL: URL?
    var reachabilityReportsOnline: Bool = false
    var useLoadedWebViewHTML: Bool = false

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {


        // setup URLs you'd like to work with
        
        webPageURLs = [
            URL(string: "https://www.military.com/daily-news/2016/11/21/russia-deploys-new-missiles-baltic-sea-region.html?variant=mobile.app&hidebreadcrumb=yes")!,
            URL(string: "https://www.military.com/daily-news/2016/12/08/marine-hornet-pilot-killed-in-japan-identified.html?variant=mobile.app&hidebreadcrumb=yes")!,
            URL(string: "https://techcrunch.com/2016/12/19/apples-tim-cook-assures-employees-that-it-is-committed-to-the-mac-and-that-great-desktops-are-coming/")!,
            URL(string: "https://www.nasa.gov/feature/pluto-paints-its-largest-moon-red")!,
            URL(string: "https://www.nasa.gov/feature/scientists-probe-mystery-of-pluto-s-icy-heart")!,
            URL(string: "https://www.nasa.gov/feature/jpl/nasas-curiosity-rover-begins-next-mars-chapter")!,
            URL(string: "http://www.cnn.com/")!,
            URL(string: "https://techcrunch.com")!
        ]
        
        currentURL = webPageURLs?[0]
    
        let isOfflineHandler: (() -> Bool) = {
            return !self.reachabilityReportsOnline
        }
        
        WebpagePersistentStorage.PageManager.makeSharedInstance(isOfflineHandler)
        
        return true
    }
}

