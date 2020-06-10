//
//  NetworkAdapter.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

protocol NetworkAdapter {
    var baseURL: URL { get }
    var version: String { get }
    func callAPI(endpoint: String, method: String, body: Data, completion: @escaping (Result<APIData, Error>) -> Void)
}

class URLSessionNetworkAdapter: NetworkAdapter {
    enum Errors: Error {
        case genericError
        case invalidJSON
        case invalidResponse(HTTPURLResponse)
        case invalidData
    }

    var baseURL: URL {
        return URL(string: "http://localhost:8080")!
    }

    var version: String {
        return "v1"
    }

    let session: URLSession
    init() {
        self.session = URLSession(configuration: .ephemeral)
    }

    func callAPI(endpoint: String, method: String = "POST", body: Data, completion: @escaping (Result<APIData, Error>) -> Void) {
        let request = self.request(forEndpoint: endpoint, method: method, body: body)
        self.callAPI(with: request, completion: completion)
    }

    private func callAPI(with request: URLRequest, completion: @escaping (Result<APIData, Error>) -> Void) {
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

    private func request(forEndpoint endpoint: String, method: String, body: Data) -> URLRequest {
        let url = self.baseURL.appendingPathComponent(self.version).appendingPathComponent(endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        return request
    }
}
