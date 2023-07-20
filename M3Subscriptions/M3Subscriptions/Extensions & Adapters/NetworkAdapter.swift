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
    func callAPI(endpoint: String, method: String, body: [String: String]) async throws -> APIData
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
        return APIDebugManager.shared.activeConfig.baseURL
        #else
        return Config.production.baseURL
        #endif
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

    //TODO: Make Async
    func callAPI(endpoint: String, method: String = "POST", body: [String: String]) async throws -> APIData {
        let request = self.request(forEndpoint: endpoint, method: method, body: body)
        return try await self.callAPI(with: request)
    }

    //TODO: Make Async
    private func callAPI(with request: URLRequest) async throws -> APIData {
        let (data, response) = try await self.session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw Errors.genericError
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 422 else {
            throw Errors.invalidResponse(httpResponse)
        }

        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let jsonDictionary = json as? [String: Any] else {
            throw Errors.invalidJSON
        }

        guard let apiData = APIData(json: jsonDictionary) else {
            throw Errors.invalidData
        }

        return apiData
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
