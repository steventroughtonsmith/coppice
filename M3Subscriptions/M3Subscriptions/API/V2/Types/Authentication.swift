//
//  Authentication.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    enum Authentication {
        case token(String)
        case licence(Licence)
    }
}
