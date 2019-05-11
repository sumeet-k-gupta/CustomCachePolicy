//
//  CustomNetworkManager.swift
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
            func forceReload(withCompletionUpdates callCompletion: Bool = false, cachedResponse: Any? = nil) {
                self.performNetworkRequest(method: "GET", urlString: url, cachePolicy: .reloadIgnoringLocalCacheData, atCompletionSuccess: {(response, responseObject) in
                    if self.hasResponseChanged(response1: cachedResponse, response2: responseObject) {
                        completionSuccess(response, responseObject)
                    } else if callCompletion {
                        completionSuccess(response, responseObject)
                    }
                }, atCompletionFailure: {(operation, error) in
                    if callCompletion {
                        completionFailure(operation, error)
                    }
                })
            }


            return self.performNetworkRequest(method: "GET", urlString: url, cachePolicy: .returnCacheDataDontLoad, atCompletionSuccess: {(response, responseObject) in
                // returnCacheData
                completionSuccess(response, responseObject)
                // AndFetch
                forceReload(cachedResponse: responseObject)
            }, atCompletionFailure: {(response, _) in
                if let responseOnCacheMiss = cacheMissResponse {
                    // returnCacheData, in this case if cacheMissResponse is available, return that as the user of the method expects this if cache was missed
                    completionSuccess(response, responseOnCacheMiss)
                }
                // AndFetch, if cacheMissResponse was not provided then call the API and let updates to the happen after data is fetched from the API
                forceReload(withCompletionUpdates: true, cachedResponse: cacheMissResponse)
            })
        }
    }

    private func hasResponseChanged(response1 optionalResponse1: Any?, response2 optionalResponse2: Any?) -> Bool {
        guard let response1 = optionalResponse1 else {
            if optionalResponse2 != nil {
                return true
            }
            return false
        }

        guard let response2 = optionalResponse2 else {
            return true
        }

        if Swift.type(of: response1) == Swift.type(of: response2) {
            if Swift.type(of: response1) == String.self {
                if let string1 = response1 as? String, let string2 = response2 as? String, string1 == string2 {
                    return false
                }
                return true
            } else {
                if let json1 = try? JSONSerialization.data(withJSONObject: response1, options: JSONSerialization.WritingOptions.prettyPrinted), let json2 = try? JSONSerialization.data(withJSONObject: response2, options: JSONSerialization.WritingOptions.prettyPrinted), json1 == json2 {
                    return false
                }
                return true
            }
        }
        return true
    }

}
