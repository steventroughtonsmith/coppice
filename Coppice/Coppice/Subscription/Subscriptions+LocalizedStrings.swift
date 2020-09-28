//
//  Subscriptions+LocalizedStrings.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import M3Subscriptions

extension M3Subscriptions.Subscription {
    var localizedState: String {
        if self.hasExpired {
            return NSLocalizedString("Expired", comment: "Expired subscription state")
        }
        if self.renewalStatus == .failed {
            return NSLocalizedString("Billing Failed", comment: "Billing Failed subscription state")
        }

        return NSLocalizedString("Active", comment: "Active subscription state")
    }

    var localizedInfo: String {
        let format: String
        if self.hasExpired {
            format = NSLocalizedString("(expired on %@)", comment: "'expired on <date>' expired subscription info label")
        } else {
            switch self.renewalStatus {
            case .renew:
                format = NSLocalizedString("(will renew on %@)", comment: "'will renew on <date>' active subscription info label")
            case .cancelled, .failed:
                format = NSLocalizedString("(will expire on %@)", comment: "'will expire on <date>' active subscription that will expire (due to billing failure or the user cancelling) info label")
            default:
                return ""
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none

        return String(format: format, dateFormatter.string(from: self.expirationDate))
    }
}
