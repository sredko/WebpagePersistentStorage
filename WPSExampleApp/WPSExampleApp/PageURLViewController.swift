//
//  PageURLViewController.swift
//  WPSExampleApp
//
//  Created by Serhiy Redko on 12/18/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import UIKit
import WebpagePersistentStorage


// class to show list of URLs to expiriment with
// for simplicity data model resides in AppDelegate where you can add your URLs

class PageURLViewController: UITableViewController {

    private var dataModel: AppDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()
        dataModel = UIApplication.shared.delegate as! AppDelegate
        
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        
        if let currentURL = dataModel.currentURL {
            if let i = dataModel.webPageURLs.index(of: currentURL) {
                let indexPath = IndexPath(row: i, section: 0)
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .middle)
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataModel.webPageURLs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let result = tableView.dequeueReusableCell(withIdentifier: "URLCell", for: indexPath) as! URLTableViewCell
        result.url = dataModel.webPageURLs[indexPath.row]
        return result
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dataModel.currentURL = dataModel.webPageURLs[indexPath.row]
    }
}

class URLTableViewCell : UITableViewCell {

    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var cacheButton: UIButton!
    @IBOutlet weak var loadButton: UIButton!

    

    var url: URL? {
        
        didSet {
            activityIndicator.stopAnimating()
            if let url = url {
                urlLabel.text = url.absoluteString
                isCached = PageManager.shared.allPages().contains(url)
            }
            else {
                urlLabel.text = ""
            }
        }
    }

    var isCached: Bool = false {
        didSet {
            cacheButton.setTitle(isCached ? "Remove" : "Save", for: UIControlState.normal)
        }
    }

    @IBAction func onCache(_ sender: Any) {
        
        if isCached {
            // remove from cache
            
            PageManager.shared.remove(pageWithURL: url!)
            isCached = false
        }
        else {
            // add to cache/save
            loadPage(savePersistently: true)
        }
        
    }

    @IBAction func onLoad(_ sender: Any) {
        loadPage(savePersistently: false)
    }


    func loadPage(savePersistently: Bool) {
    
        let requestCompletedHandler =  { (_ request: PageRequest) -> (Bool) in
            let documentState = request.webView.stringByEvaluatingJavaScript(from: "document.readyState")
            return documentState == "complete"
        }
        
        activityIndicator.startAnimating()
        
        let options: PageRequest.Options = savePersistently ? [] : [.dontSavePagePersistently]
        
        let pageRequest = PageRequest(with: url!, options: options, webView: nil, completedHandler: requestCompletedHandler)
        pageRequest.start(completion: { (result: PageRequest.Result) -> (Void) in

            self.activityIndicator.stopAnimating()

            switch result {
                case .success:
                    print("Request succeeded")
                    self.isCached = PageManager.shared.allPages().contains(self.url!)
                break
                
                case .failed(let error):
                    print("Request error: \(error)")
                    
                    let alertController = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    UIApplication.shared.windows[0].rootViewController?.present(alertController, animated: true, completion: nil)
                    
                break
            }

        })
    
    }

}
