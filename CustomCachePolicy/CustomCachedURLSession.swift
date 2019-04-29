//
//  CustomCachedURLSession.swift
//  CustomCachePolicy
//
//  Created by Sumeet Gupta on 27/04/19.
//  Copyright © 2019 Example. All rights reserved.
//

import Foundation

public enum CustomCachePolicy {
    case urlCachePolicy(NSURLRequest.CachePolicy)

    /// Custom cache policy to return data from the cache if available, and always fetch results from the server.
    case returnCacheDataAndFetch
}

protocol CachedAPIManager: APIManager {
    func fetchData(fromURL url: String!, cachePolicy: CustomCachePolicy, cacheMissResponse: Any?, atCompletionSuccess completionSuccess: ((URLResponse?, Any?) -> Void)!, atCompletionFailure completionFailure: ((URLResponse?, Error?) -> Void)!) -> URLSessionDataTask!
}

extension NetworkManager: CachedAPIManager {
    func fetchData(fromURL url: String!, cachePolicy: CustomCachePolicy, cacheMissResponse: Any? = nil, atCompletionSuccess completionSuccess: ((URLResponse?, Any?) -> Void)!, atCompletionFailure completionFailure: ((URLResponse?, Error?) -> Void)!) -> URLSessionDataTask! {

        switch cachePolicy {

        case .urlCachePolicy(let policy):
            return self.performNetworkRequest(method: "GET", urlString: url, cachePolicy: policy, atCompletionSuccess: completionSuccess, atCompletionFailure: completionFailure)

        case .returnCacheDataAndFetch:
            func forceReload(withCompletionUpdates callCompletion: Bool = false) {
                self.performNetworkRequest(method: "GET", urlString: url, cachePolicy: .reloadIgnoringLocalCacheData, atCompletionSuccess: {(response, responseObject) in
                    if callCompletion {
                        completionSuccess(response, responseObject)
                    }
                }, atCompletionFailure: {(response, error) in
                    if callCompletion {
                        completionFailure(response, error)
                    }
                })
            }

            return self.performNetworkRequest(method: "GET", urlString: url, cachePolicy: .returnCacheDataDontLoad, atCompletionSuccess: {(response, responseObject) in
                // returnCacheData
                completionSuccess(response, responseObject)
                // AndFetch
                forceReload()
            }, atCompletionFailure: {(response, _) in
                if let responseOnCacheMiss = cacheMissResponse {
                    // returnCacheData, in this case if cacheMissResponse is available, return that as the user of the method expects this if cache was missed
                    completionSuccess(response, responseOnCacheMiss)
                }
                // AndFetch, if cacheMissResponse was not provided then call the API and let updates to the happen after data is fetched from the API
                forceReload(withCompletionUpdates: true)
            })
        }
    }
}
