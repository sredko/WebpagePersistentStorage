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
    
    @IBAction func loadWebpage() {
    
        print("All pages: \(PageManager.shared.allPages())")
    
        if let url = dataModel.currentURL {
            webView.delegate = self
            let request = URLRequest(url: url)
            webView.loadRequest(request)
        }
        else {
            fatalError()
        }
    }


    func webViewDidStartLoad(_ webView: UIWebView) {
        print("Original delegate webViewDidStartLoad")
    }

    func webViewDidFinishLoad(_ webView: UIWebView) {
        print("Original delegate webViewDidFinishLoad")
    }

    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        print("Original delegate didFailLoadWithError: \(error)")
    }
}
