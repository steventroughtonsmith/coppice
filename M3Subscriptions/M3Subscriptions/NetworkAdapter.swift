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
    func callAPI(endpoint: String, method: String, body: [String: String], completion: @escaping (Result<APIData, Error>) -> Void)
}

class URLSessionNetworkAdapter: NetworkAdapter {
    enum Errors: Error {
        case genericError
        case invalidJSON
        case invalidResponse(HTTPURLResponse)
        case invalidData
    }

    var baseURL: URL {
        #if TEST
        if let baseURL = TEST_OVERRIDES.baseURL {
            return baseURL
        }
        #endif

        #if DEBUG
        if
            let apiURLString = UserDefaults.standard.string(forKey: "M3DebugAPIURL"),
            let apiURL = URL(string: apiURLString)
        {
            return apiURL
        }
        #endif
        return URL(string: "https://mcubedsw.com/api")!
    }

    var version: String {
        #if TEST
        if let version = TEST_OVERRIDES.apiVersion {
            return version
        }
        #endif
        return "v1"
    }

    let session: URLSession
    init(session: URLSession = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .main)) {
        self.session = session
    }

    func callAPI(endpoint: String, method: String = "POST", body: [String: String], completion: @escaping (Result<APIData, Error>) -> Void) {
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
                completion(.failure(Errors.invalidResponse(httpResponse)))
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

    private func request(forEndpoint endpoint: String, method: String, body: [String: String]) -> URLRequest {
        let url = self.baseURL.appendingPathComponent(self.version).appendingPathComponent(endpoint)

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = self.queryString(for: body).data(using: .utf8)
        return request
    }

    private func queryString(for body: [String: String]) -> String {
        var characterSet = CharacterSet.urlPathAllowed
        characterSet.remove(charactersIn: "&")
        let queryComponents = body.compactMap { "\($0)=\($1)".addingPercentEncoding(withAllowedCharacters: characterSet) }
        return queryComponents.joined(separator: "&")
    }
}
