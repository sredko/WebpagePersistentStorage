//
//  SettingsViewController.swift
//  WPSExampleApp
//
//  Created by Serhiy Redko on 12/18/16.
//  Copyright © 2016 Serhiy Redko. All rights reserved.
//

import UIKit
import WebpagePersistentStorage 

class SettingsViewController: UITableViewController {

    private var dataModel: AppDelegate!

    @IBOutlet weak var useLoadedWebViewHTML: UISwitch!
    @IBOutlet weak var reachabilityOnline: UISwitch!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataModel = UIApplication.shared.delegate as! AppDelegate
        
        reachabilityOnline.isOn = dataModel.reachabilityReportsOnline
        useLoadedWebViewHTML.isOn = dataModel.useLoadedWebViewHTML
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)    
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }


    @IBAction func useLoadedHTMLChanged(_ sender: Any) {
        dataModel.useLoadedWebViewHTML = useLoadedWebViewHTML.isOn
    }

    @IBAction func reachabilityOnlineChanged(_ sender: Any) {
        dataModel.reachabilityReportsOnline = reachabilityOnline.isOn
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)
        
        switch tableView.cellForRow(at: indexPath)!.reuseIdentifier! {
        
            case "ClearSystemCacheID":
                Foundation.URLCache.shared.removeAllCachedResponses()
            break

            case "ClearWebPagesCacheID":
                PageManager.shared.removeAllPages()
            break
            
            default:
            break
        }
    }

}
