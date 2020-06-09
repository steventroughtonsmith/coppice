//
//  NetworkAdapter.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

protocol NetworkAdapter {
    func callAPI(with request: URLRequest, completion: @escaping (Result<APIData, Error>) -> Void)
}

class URLSessionNetworkAdapter: NetworkAdapter {
    enum Errors: Error {
        case genericError
        case invalidJSON
        case invalidResponse(HTTPURLResponse)
        case invalidData
    }

    let session: URLSession
    init() {
        self.session = URLSession(configuration: .ephemeral)
    }

    func callAPI(with request: URLRequest, completion: @escaping (Result<APIData, Error>) -> Void) {
        let task = self.session.dataTask(with: request) { (data, response, error) in
            guard let jsonData = data else {
                completion(.failure(error ?? Errors.genericError))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(Errors.genericError))
                return
            }

            guard httpResponse.statusCode == 200 || httpResponse.statusCode == 422 else {
                completion(.failure(Errors.invalidResponse(httpResponse )))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                guard let jsonDictionary = json as? [String: Any] else {
                    completion(.failure(Errors.invalidJSON))
                    return
                }

                guard let apiData = APIData(json: jsonDictionary) else {
                    completion(.failure(Errors.invalidData))
                    return
                }

                completion(.success(apiData))
            }
            catch let e {
                completion(.failure(e))
            }
        }
        task.resume()
    }
}
