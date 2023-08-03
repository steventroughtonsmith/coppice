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
    func callAPI(endpoint: String, method: HTTPMethod, body: [String: String], headers: [String: String]?) async throws -> APIData
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum NetworkAdapterError: Error {
    case noInternetConnection
    case urlError(NSError)
    case unknownResponse
    case unauthorized
    case invalidResponse(HTTPURLResponse)
    case invalidJSON
    case invalidData
    case genericError(Error)
}

class URLSessionNetworkAdapter: NetworkAdapter {
    var baseURL: URL {
        #if TEST
        if let baseURL = TEST_OVERRIDES.baseURL {
            return baseURL
        }
        #endif

        #if DEBUG
        return APIDebugManager.shared.activeConfig.baseURL
        #else
        return Config.production.baseURL
        #endif
    }

    enum SupportedVersion: String {
        case v2
        case v1
    }

    var activeVersion: SupportedVersion = .v2

    var version: String {
        #if TEST
        if let version = TEST_OVERRIDES.apiVersion {
            return version
        }
        #endif
        return self.activeVersion.rawValue
    }

    let session: URLSession
    init(session: URLSession = URLSession(configuration: .ephemeral, delegate: nil, delegateQueue: .main)) {
        self.session = session
    }

    func callAPI(endpoint: String, method: HTTPMethod = .post, body: [String: String], headers: [String: String]?) async throws -> APIData {
        let request = self.request(forEndpoint: endpoint, method: method, body: body, headers: headers)
        return try await self.callAPI(with: request)
    }

    private func callAPI(with request: URLRequest) async throws -> APIData {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await self.session.data(for: request)
        } catch {
            let nsError = error as NSError
            guard nsError.domain == NSURLErrorDomain else {
                throw NetworkAdapterError.genericError(error)
            }

            if nsError.code == NSURLErrorNotConnectedToInternet {
                throw NetworkAdapterError.noInternetConnection
            }
            throw NetworkAdapterError.urlError(nsError)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkAdapterError.unknownResponse
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 422 else {
            if httpResponse.statusCode == 401 {
                throw NetworkAdapterError.unauthorized
            }
            throw NetworkAdapterError.invalidResponse(httpResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonDictionary = json as? [String: Any] else {
            throw NetworkAdapterError.invalidJSON
        }

        guard let apiData = APIData(json: jsonDictionary) else {
            throw NetworkAdapterError.invalidData
        }

        return apiData
    }

    private func request(forEndpoint endpoint: String, method: HTTPMethod, body: [String: String], headers: [String: String]? = nil) -> URLRequest {
        var url = self.baseURL.appendingPathComponent(self.version).appendingPathComponent(endpoint)

        if method == .get, var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            components.query = self.queryString(for: body)
            if let newURL = components.url {
                url = newURL
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        if method == .post {
            request.httpBody = self.queryString(for: body).data(using: .utf8)
        }
        request.allHTTPHeaderFields = headers
        return request
    }

    private func queryString(for body: [String: String]) -> String {
        var characterSet = CharacterSet.urlPathAllowed
        characterSet.remove(charactersIn: "&+")
        let queryComponents = body.compactMap { "\($0)=\($1)".addingPercentEncoding(withAllowedCharacters: characterSet) }
        return queryComponents.joined(separator: "&")
    }
}
