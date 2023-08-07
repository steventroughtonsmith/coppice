//
//  Debug.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 06/08/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import AppKit

#if DEBUG
extension API.V2 {
    class Debug {
        static let shared = Debug()

        func debugMenuItems() -> [NSMenuItem] {
            let noneMenuItem = NSMenuItem(title: "None", action: #selector(self.updateDebugResponse(_:)), keyEquivalent: "")
            noneMenuItem.target = self
            noneMenuItem.representedObject = APIDebugManager.DebugResponse.none

            let apiResponsesMenuItem = NSMenuItem(title: "API Responses", action: nil, keyEquivalent: "")
            apiResponsesMenuItem.submenu = self.apiResponseMenu()

            let neworkErrorsMenuItem = NSMenuItem(title: "Network Errors", action: nil, keyEquivalent: "")
            neworkErrorsMenuItem.submenu = self.networkErrorMenu()
            return [noneMenuItem, apiResponsesMenuItem, neworkErrorsMenuItem]
        }

        private func apiResponseMenu() -> NSMenu {
            let menu = NSMenu()

            let listSubsMenuItem = NSMenuItem(title: "List Subscriptions", action: nil, keyEquivalent: "")
            listSubsMenuItem.submenu = self.apiResponseListSubsMenu()
            menu.addItem(listSubsMenuItem)

            let listDevicesMenuItem = NSMenuItem(title: "List Devices", action: nil, keyEquivalent: "")
            listDevicesMenuItem.submenu = self.apiResponseListDevicesMenu()
            menu.addItem(listDevicesMenuItem)

            let activationMenuItem = NSMenuItem(title: "Activation", action: nil, keyEquivalent: "")
            activationMenuItem.submenu = self.apiResponseActivationMenu()
            menu.addItem(activationMenuItem)

            let checkMenuItem = NSMenuItem(title: "Check", action: nil, keyEquivalent: "")
            checkMenuItem.submenu = self.apiResponseCheckMenu()
            menu.addItem(checkMenuItem)

            let deactivationMenuItem = NSMenuItem(title: "Dectivation", action: nil, keyEquivalent: "")
            deactivationMenuItem.submenu = self.apiResponseDeactivationMenu()
            menu.addItem(deactivationMenuItem)

            menu.addItem(.separator())
            menu.addItem(self.apiResponseMenuItem(title: "Login Failed", .loginFailed))
            menu.addItem(self.apiResponseMenuItem(title: "Multiple Subscriptions", .multipleSubscriptions))
            menu.addItem(self.apiResponseMenuItem(title: "No Subscription Found", .noSubscriptionFound))
            menu.addItem(self.apiResponseMenuItem(title: "No Device Found", .noDeviceFound))
            menu.addItem(self.apiResponseMenuItem(title: "Too Many Devices", .tooManyDevices))
            menu.addItem(self.apiResponseMenuItem(title: "Expired", .expired))
            menu.addItem(self.apiResponseMenuItem(title: "Invalid Licence", .invalidLicence))

            return menu
        }

        private func apiResponseMenuItem(title: String, _ response: APIData.Response) -> NSMenuItem {
            var apiData = APIData.empty
            apiData.response = response

            let menuItem = NSMenuItem(title: title, action: #selector(self.updateDebugResponse(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = RepresentedObject(response: .data(apiData))
            return menuItem
        }

        private func apiResponseListSubsMenu() -> NSMenu {
            let menu = NSMenu()
            menu.addItem(self.clearApiResponseMenuItem(endpoint: "subscriptions"))
            menu.addItem(self.apiResponseMenuItem(title: "1 Subscription", .success, endpoint: "subscriptions", payload: [
                "subscriptions": [
                    ["id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 180).timeIntervalSince1970), "renewalStatus": "renew", "maxDeviceCount": 3, "currentDeviceCount": 2],
                ],
            ]))

            menu.addItem(self.apiResponseMenuItem(title: "3 Subscriptions", .success, endpoint: "subscriptions", payload: [
                "subscriptions": [
                    ["id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 180).timeIntervalSince1970), "renewalStatus": "renew", "maxDeviceCount": 3, "currentDeviceCount": 2],
                    ["id": "sub2", "name": "Subscription 2", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 30).timeIntervalSince1970), "renewalStatus": "cancelled", "maxDeviceCount": 1, "currentDeviceCount": 1],
                    ["id": "sub3", "name": "Subscription 3", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 360).timeIntervalSince1970), "renewalStatus": "failed", "maxDeviceCount": 4, "currentDeviceCount": 3],
                ],
            ]))

            return menu
        }

        private func apiResponseListDevicesMenu() -> NSMenu {
            let menu = NSMenu()

            menu.addItem(self.clearApiResponseMenuItem(endpoint: "devices"))
            menu.addItem(self.apiResponseMenuItem(title: "No devices", .success, endpoint: "devices", payload: [
                "devices": [[String: Any]](),
                "maxDeviceCount": 3,
            ]))

            menu.addItem(self.apiResponseMenuItem(title: "2 devices", .success, endpoint: "devices", payload: [
                "devices": [
                    ["activationID": "device1", "activationTimestamp": Int(Date(timeIntervalSinceNow: -10).timeIntervalSince1970), "name": "Device 1"],
                    ["activationID": "device2", "activationTimestamp": Int(Date(timeIntervalSinceNow: -100 * 86400).timeIntervalSince1970), "name": "Device 2"],
                ],
                "maxDeviceCount": 3,
            ]))

            menu.addItem(self.apiResponseMenuItem(title: "2 devices (no names0", .success, endpoint: "devices", payload: [
                "devices": [
                    ["activationID": "device1", "activationTimestamp": Int(Date(timeIntervalSinceNow: -10).timeIntervalSince1970)],
                    ["activationID": "device2", "activationTimestamp": Int(Date(timeIntervalSinceNow: -100 * 86400).timeIntervalSince1970)],
                ],
                "maxDeviceCount": 3,
            ]))

            menu.addItem(self.apiResponseMenuItem(title: "3 devices", .success, endpoint: "devices", payload: [
                "devices": [
                    ["activationID": "device1", "activationTimestamp": Int(Date(timeIntervalSinceNow: -10).timeIntervalSince1970), "name": "Device 1"],
                    ["activationID": "device2", "activationTimestamp": Int(Date(timeIntervalSinceNow: -100 * 86400).timeIntervalSince1970), "name": "Device 2"],
                    ["activationID": "device3", "activationTimestamp": Int(Date(timeIntervalSinceNow: -200 * 86400).timeIntervalSince1970), "name": "Device 3"],
                ],
                "maxDeviceCount": 3,
            ]))

            menu.addItem(self.apiResponseMenuItem(title: "3 devices (including current)", .success, endpoint: "devices", payload: [
                "devices": [
                    ["activationID": "device1", "activationTimestamp": Int(Date(timeIntervalSinceNow: -10).timeIntervalSince1970), "name": "Device 1"],
                    ["activationID": "device2", "activationTimestamp": Int(Date(timeIntervalSinceNow: -100 * 86400).timeIntervalSince1970), "name": "Device 2", "isCurrent": true],
                    ["activationID": "device3", "activationTimestamp": Int(Date(timeIntervalSinceNow: -200 * 86400).timeIntervalSince1970), "name": "Device 3"],
                ],
                "maxDeviceCount": 3,
            ]))
            return menu
        }

        private func apiResponseActivationMenu() -> NSMenu {
            let menu = NSMenu()
            menu.addItem(self.clearApiResponseMenuItem(endpoint: "activate"))
            menu.addItem(self.apiResponseMenuItem(title: "Renew", .active, endpoint: "activate", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 180).timeIntervalSince1970), "renewalStatus": "renew", "maxDeviceCount": 3,
                ],
            ]))
            menu.addItem(self.apiResponseMenuItem(title: "Expired", .active, endpoint: "activate", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date().timeIntervalSince1970), "renewalStatus": "renew", "maxDeviceCount": 3,
                ],
            ]))
            menu.addItem(self.apiResponseMenuItem(title: "Renewing Soon", .active, endpoint: "activate", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 15).timeIntervalSince1970), "renewalStatus": "renew", "maxDeviceCount": 3,
                ],
            ]))
            menu.addItem(self.apiResponseMenuItem(title: "Cancelled", .active, endpoint: "activate", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 180).timeIntervalSince1970), "renewalStatus": "cancelled", "maxDeviceCount": 3,
                ],
            ]))
            menu.addItem(self.apiResponseMenuItem(title: "Billing Failed", .active, endpoint: "activate", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 15).timeIntervalSince1970), "renewalStatus": "failed", "maxDeviceCount": 3,
                ],
            ]))

            return menu
        }

        private func apiResponseCheckMenu() -> NSMenu {
            let menu = NSMenu()
            menu.addItem(self.clearApiResponseMenuItem(endpoint: "check"))
            menu.addItem(self.apiResponseMenuItem(title: "Renew", .active, endpoint: "check", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 180).timeIntervalSince1970), "renewalStatus": "renew", "maxDeviceCount": 3,
                ],
            ]))
            menu.addItem(self.apiResponseMenuItem(title: "Expired", .active, endpoint: "check", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date().timeIntervalSince1970), "renewalStatus": "renew", "maxDeviceCount": 3,
                ],
            ]))
            menu.addItem(self.apiResponseMenuItem(title: "Renewing Soon", .active, endpoint: "check", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 15).timeIntervalSince1970), "renewalStatus": "renew", "maxDeviceCount": 3,
                ],
            ]))
            menu.addItem(self.apiResponseMenuItem(title: "Cancelled", .active, endpoint: "check", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 180).timeIntervalSince1970), "renewalStatus": "cancelled", "maxDeviceCount": 3,
                ],
            ]))
            menu.addItem(self.apiResponseMenuItem(title: "Billing Failed", .active, endpoint: "check", payload: [
                "activationID": "activation1",
                "device": ["name": "My Cool Mac"],
                "subscription": [
                    "id": "sub1", "name": "Subscription 1", "expirationTimestamp": Int(Date(timeIntervalSinceNow: 86400 * 15).timeIntervalSince1970), "renewalStatus": "failed", "maxDeviceCount": 3,
                ],
            ]))

            return menu
        }

        private func apiResponseDeactivationMenu() -> NSMenu {
            let menu = NSMenu()
            menu.addItem(self.clearApiResponseMenuItem(endpoint: "deactivate"))
            menu.addItem(self.apiResponseMenuItem(title: "Deactivated", .deactivated, endpoint: "deactivate", payload: [:]))
            return menu
        }

        private func clearApiResponseMenuItem(endpoint: String) -> NSMenuItem {
            let menuItem = NSMenuItem(title: "None", action: #selector(self.updateDebugResponse(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = RepresentedObject(response: .none, endpoint: endpoint, reset: false)
            return menuItem
        }

        private func apiResponseMenuItem(title: String, _ response: APIData.Response, endpoint: String, payload: [String: Any]) -> NSMenuItem {
            var apiData = APIData.empty
            apiData.response = response
            apiData.payload = payload

            let menuItem = NSMenuItem(title: title, action: #selector(self.updateDebugResponse(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = RepresentedObject(response: .data(apiData), endpoint: endpoint, reset: false)
            return menuItem
        }


        //MARK: - Network Errors
        private func networkErrorMenu() -> NSMenu {
            let menu = NSMenu()

            menu.addItem(self.networkErrorMenuItem(.noInternetConnection, title: "No Internet Connection"))

            let networkURLError = NSMenuItem(title: "URL Error", action: nil, keyEquivalent: "")
            networkURLError.submenu = self.networkURLErrorMenu()
            menu.addItem(networkURLError)

            let invalidResponseError = NSMenuItem(title: "Invalid Response", action: nil, keyEquivalent: "")
            invalidResponseError.submenu = self.networkInvalidResponseErrorMenu()
            menu.addItem(invalidResponseError)

            menu.addItem(self.networkErrorMenuItem(.unauthorized, title: "Unauthorized"))
            menu.addItem(self.networkErrorMenuItem(.invalidJSON, title: "Invalid JSON"))
            menu.addItem(self.networkErrorMenuItem(.invalidData, title: "Invalid API Data"))
            menu.addItem(self.networkErrorMenuItem(.genericError(NSError(domain: "generic error", code: -1)), title: "Generic Error"))

            return menu
        }

        private func networkURLErrorMenu() -> NSMenu {
            let menu = NSMenu()
            menu.addItem(self.networkErrorMenuItem(.urlError(NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)), title: "Timed Out (-1001)"))
            menu.addItem(self.networkErrorMenuItem(.urlError(NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotFindHost)), title: "Cannot Find Host (-1003)"))
            menu.addItem(self.networkErrorMenuItem(.urlError(NSError(domain: NSURLErrorDomain, code: NSURLErrorNetworkConnectionLost)), title: "Network Connection Lost (-1005)"))
            return menu
        }

        private func networkInvalidResponseErrorMenu() -> NSMenu {
            let menu = NSMenu()
            let fakeURL = URL(string: "https://mcubedsw.com")!
            menu.addItem(self.networkErrorMenuItem(.invalidResponse(HTTPURLResponse(url: fakeURL, statusCode: 400, httpVersion: nil, headerFields: nil)!), title: "400 Bad Request"))
            menu.addItem(self.networkErrorMenuItem(.invalidResponse(HTTPURLResponse(url: fakeURL, statusCode: 403, httpVersion: nil, headerFields: nil)!), title: "403 Forbidden"))
            menu.addItem(self.networkErrorMenuItem(.invalidResponse(HTTPURLResponse(url: fakeURL, statusCode: 404, httpVersion: nil, headerFields: nil)!), title: "404 Not Found"))
            menu.addItem(self.networkErrorMenuItem(.invalidResponse(HTTPURLResponse(url: fakeURL, statusCode: 500, httpVersion: nil, headerFields: nil)!), title: "500 Internal Server Error"))
            return menu
        }

        private func networkErrorMenuItem(_ error: NetworkAdapterError, title: String) -> NSMenuItem {
            let menuItem = NSMenuItem(title: title, action: #selector(self.updateDebugResponse(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.representedObject = RepresentedObject(response: .error(error))
            return menuItem
        }

        private var selectedMenuItem: NSMenuItem?
        @objc private func updateDebugResponse(_ menuItem: NSMenuItem) {
            guard let response = menuItem.representedObject as? RepresentedObject else {
                return
            }
            self.selectedMenuItem?.state = .off
            menuItem.state = .on
            self.selectedMenuItem = menuItem

            if (response.reset) {
                APIDebugManager.shared.resetDebugResponses()
            }
            APIDebugManager.shared.setDebugResponse(response.response, forEndpoint: response.endpoint)
        }
    }


    struct RepresentedObject {
        var response: APIDebugManager.DebugResponse
        var endpoint: String?
        var reset: Bool = true
    }
}

#endif
