# WebpagePersistentStorage
iOS SDK for network efficient webpage persistent caching and storage

Register auxilary global cache at some point on app start (e.g in app delegate didFinishLaunchingWithOptions)

	let isOfflineHandler: (() -> Bool) = {
    	return actual reachability value
	    let isOffline = true  
	    return isOffline
	}

Provide config values for cache or nil so defaults will be used

	let config = PageManager.Config(isOfflineHandler:isOfflineHandler,
	    pageStorageType: nil, cacheMemoryCapacityMB: nil, cacheDiskCapacityMB: nil, cacheDiskPath: nil)

This will setup URLCache.shared instance that should not be changed
	
    PageManager.makeSharedInstance(withConfig: config)


To save web page

	let url = URL(string: "http://....")!
	let pageRequest = PageRequest(with: url, options: [])

	pageRequest.start(completion: { (result: PageRequest.Result) -> (Void) in

	    switch result {
	        case .success:
	            assert(PageManager.shared.allPages().contains(url))
    	    break
        
	        case .failed(let error):
    	        let nsError = error as NSError?
        	    print("Error \(error)")
       		break
    	}
	})


To load saved webpage being offline use regular UIWebView code

	let request = URLRequest(url: url)
	webView.loadRequest(request)







