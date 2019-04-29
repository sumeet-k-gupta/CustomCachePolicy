//
//  NetworkManager.swift
//  CustomCachePolicy
//
//  Created by Sumeet Gupta on 29/04/19.
//  Copyright © 2019 Example. All rights reserved.
//

import Foundation

protocol APIManager {
    func fetchData(fromURL url: String!, atCompletionSuccess completionSuccess: ((URLResponse?, Any?) -> Void)!, atCompletionFailure completionFailure: ((URLResponse?, Error?) -> Void)!) -> URLSessionDataTask!
}

class NetworkManager: APIManager {
    func fetchData(fromURL url: String!, atCompletionSuccess completionSuccess: ((URLResponse?, Any?) -> Void)!, atCompletionFailure completionFailure: ((URLResponse?, Error?) -> Void)!) -> URLSessionDataTask! {
        return self.performNetworkRequest(method: "GET", urlString: url, cachePolicy: .useProtocolCachePolicy, atCompletionSuccess: completionSuccess, atCompletionFailure: completionFailure)
    }

    @discardableResult
    func performNetworkRequest(method: String, urlString: String, cachePolicy: NSURLRequest.CachePolicy, atCompletionSuccess completionSuccess: ((URLResponse?, Any?) -> Void)!, atCompletionFailure completionFailure: ((URLResponse?, Error?) -> Void)!) -> URLSessionDataTask! {
        let session = URLSession.shared
        let url = URL(string: urlString)!

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = cachePolicy

        let task = session.dataTask(with: request) { (data, response, error) in
            if error != nil {
                completionFailure(response, error)
            } else {
                completionSuccess(response, data)
            }
        }
        task.resume()
        return task
    }
}
