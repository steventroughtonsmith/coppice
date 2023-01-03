//
//  Configs.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 03/01/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

enum Config: String, CaseIterable {
    case production
    #if DEBUG
    case localDev
    #endif

    #if DEBUG
    var displayName: String {
        switch self {
        case .production: return "Production"
        case .localDev: return "Local Dev"
        }
    }
    #endif

    var publicKey: String {
        switch self {
        case .production:
            return """
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqZdbp6XV0sxInPFl7K5O
9aGRQkjdmspuV7bbDplLzznueAHJP25zbsiGKKKsTypKa5Zf5vJtMGNhe6D/kKiO
JkkCiTJJ8KgzP1DaJeXMCCrXmG+iivIPgXv6XJuO55+iVVI9RCOp247Z0oXjOBl6
m/PU7irVPng9wCWDELsgI8nKUZM/+RKc1PJ3bb3MW2GbDMxAWPnGRvvjx/Y9M+hW
VaYLykTPu5f6islSJKllN7XVfBgWMxt8+RNnYoVcoRGbtlRvZ0LOyjMHzwoU6NDM
0QnIJeuNvirS1wlIrdfhNLkfa6nIWsePa4aaXBPRuMx1To/gi57TTMMIqGPSsp5y
BQIDAQAB
"""
    #if DEBUG
        case .localDev:
            return """
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEArd0CI4+IYXK3DtqPBOPJ
hka+APdo653OzA4UfXal8fSYqDu0m7rB9vEf2T97xDPQ9LpXCM81hkotZv1tZdUJ
ISUiXFsXHkeD2uP/cahSsF8dLYdCO+JhatSsrBmp6tc0ttvWy4TsQjBdr7TYBDGN
FfvbryRpVHioDq4t2bt2tJ7AxYGPygyZJIOA8JUhKM2yDdsW1ALlA8PIxqn5gcmA
6lBzPNJ1pdW9nm0uLTXIT/QWB476r0CZO3RTKi/kSJ5pC/qdZ+5CP6elQCICkf6M
+1nFz7oDgqLqn7g2GilZs7dj9ubkHTtjjealHAkkqsJyXN3ZJLTC8vWmXzr7TEaL
7wIDAQAB
"""
    #endif
        }
    }

    var baseURL: URL {
        switch self {
        case .production: return URL(string: "https://mcubedsw.com/api")!
    #if DEBUG
        case .localDev: return URL(string: "https://dev-mcubedsw-com:8890/api")!
    #endif
        }
    }
}
