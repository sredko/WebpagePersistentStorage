//
//  ViewController.swift
//  WPSExampleApp
//
//  Created by Serhiy Redko on 12/20/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import UIKit
import WebpagePersistentStorage


class MainViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet var webView: UIWebView!
    private var dataModel: AppDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        dataModel = UIApplication.shared.delegate as! AppDelegate
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)    
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    var loadsCount: Int = 0
    @IBAction func loadWebpage() {
    
        print("All pages: \(PageManager.shared.allPages())")
    
        if let url = dataModel.currentURL {
            webView.delegate = self
            let request = URLRequest(url: url)
            loadsCount = 0
            webView.loadRequest(request)
        }
        else {
            fatalError()
        }
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {

        print("===========================")
        print("= shouldStartLoadWith [\(navigationType.rawValue)]")
        print("=             URL: \(request.url?.absoluteString)")
        print("= mainDocumentURL: \(request.mainDocumentURL?.absoluteString)")
        print("===========================")
        return true
    }


    func webViewDidStartLoad(_ webView: UIWebView) {
        print("Original delegate webViewDidStartLoad")
        loadsCount =  loadsCount + 1
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("Original delegate webViewDidFinishLoad")
        loadsCount =  loadsCount - 1
        if 0 == loadsCount {
            print("Completed page load")
        }
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("Original delegate didFailLoadWithError: \(error)")
    }
}
