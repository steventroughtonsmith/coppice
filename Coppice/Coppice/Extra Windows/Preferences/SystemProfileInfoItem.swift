//
//  SystemProfileInfoItem.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import Sparkle

struct SystemProfileInfoItem {
    let key: String
    let displayKey: String
    let value: Any
    let displayValue: Any

    let info: String
}

class SystemProfileInfoItemCreator {
    static func infoItems(from updaterController: SPUStandardUpdaterController) -> [SystemProfileInfoItem] {
        guard let updater = updaterController.updater else {
            return []
        }
        guard let additionalInfo = updaterController.updaterDelegate?.feedParameters?(for: updater, sendingSystemProfile: true) else {
            return []
        }
        let combinedInfo = updater.systemProfileArray + additionalInfo

        var info = [SystemProfileInfoItem]()
        for infoDict in combinedInfo {
            guard
                let key = infoDict["key"],
                let displayKey = infoDict["displayKey"],
                let value = infoDict["value"],
                let displayValue = infoDict["displayValue"]
            else {
                preconditionFailure("Invalid system info found, skipping: \(infoDict)")
                continue
            }

            let infoItem = SystemProfileInfoItem(key: key,
                                                 displayKey: displayKey,
                                                 value: value,
                                                 displayValue: self.modifiedDisplayValue(forKey: key, value: value) ?? displayValue,
                                                 info: self.info(forKey: key))
            info.append(infoItem)
        }
        return info
    }

    private static func info(forKey key: String) -> String {
        switch key {
        case "osVersion":
            return NSLocalizedString("Knowing the OS version helps us know what versions of macOS we need to support going forward.", comment: "")
        case "cputype":
            return NSLocalizedString("The CPU type lets us know what processor architectures to support over time (e.g. Intel, Apple Silicon).", comment: "")
        case "model":
            return NSLocalizedString("Knowing the model of Mac our users run Coppice on lets us know what models and form factors to optimise for.", comment: "")
        case "lang":
            return NSLocalizedString("Knowing the languages our users use helps us determine what languages we may want to provide localisations for in the future.", comment: "")
        case "appVersion":
            return NSLocalizedString("The app version helps us learn how quickly users update to the latest and greatest version of Coppice.", comment: "")
        case "bundleID":
            return NSLocalizedString("The Bundle ID simply lets us know it is Coppice that is sending the data.", comment: "")
        default:
            preconditionFailure()
        }
    }

    private static func modifiedDisplayValue(forKey key: String, value: Any) -> Any? {
        switch key {
        case "lang":
            return self.displayLanguage(for: value)
        case "model":
            return self.displayModel(for: value)
        case "appVersion":
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        default:
            return nil
        }
    }

    private static func displayLanguage(for value: Any) -> String? {
        guard let languageString = value as? String else {
            return nil
        }

        return NSLocale.current.localizedString(forIdentifier: languageString)
    }


    private static let iMacModels = [
        "13,1": "(21.5\", Late 2012/Early 2013)",
        "13,2": "(27\", Late 2012)",
        "14,1": "(21.5\", Late 2013)",
        "14,2": "(27\" Late 2012)",
        "14,3": "(21.5\", Late 2013)",
        "14,4": "(21.5\", Mid 2014)",
        "15,1": "(27\", Late 2014/Mid 2015)",
        "16,1": "(21.5\", Late 2015)",
        "16,2": "(21.5\", Late 2015)",
        "17,1": "(27\" Late 2015)",
        "18,1": "(21.5\", 2017)",
        "18,2": "(21.5\", 2017)",
        "18,3": "(27\", 2017)",
        "19,1": "(27\", 2019)",
        "19,2": "(21.5\", 2019)",
        "20,1": "(27\", 2020)",
        "20,2": "(27\", 2020)",
        "21,1": "(24\", 2021)",
        "21,2": "(24\", 2021)",
    ]

    private static let iMacProModels = [
        "1,1": "(2017)",
    ]

    private static let macMiniModels = [
        "6,1": "(Late 2012)",
        "6,2": "(Late 2012)",
        "7,1": "(Late 2014)",
        "8,1": "(2018)",
        "9,1": "(2020)",
    ]

    private static let macProModels = [
        "6,1": "(Late 2013)",
        "7,1": "(2019)",
    ]

    private static let macBookModels = [
        "8,1": "(Early 2015)",
        "9,1": "(Early 2016)",
        "10,1": "(Early 2017)",
    ]

    private static let macBookProModels = [
        "9,1": "(15\", Mid 2012)",
        "9,2": "(13\", Mid 2012)",
        "10,1": "(15\", Mid 2012/Early 2013)",
        "10,2": "(13\", Mid 2012/Early 2013)",
        "11,1": "(13\", Late 2013/Mid 2014)",
        "11,2": "(15\", Late 2013/Mid 2014)",
        "11,3": "(15\", Late 2013/Mid 2014)",
        "12,1": "(13\", Mid 2015)",
        "11,4": "(15\", Mid 2015)",
        "11,5": "(15\", Mid 2015)",
        "13,1": "(13\", 2016)",
        "13,2": "(13\", 2016)",
        "13,3": "(15\", 2016)",
        "14,1": "(13\", 2017)",
        "14,2": "(13\", 2017)",
        "14,3": "(15\", 2017)",
        "15,1": "(15\", 2018/2019)",
        "15,2": "(13\", 2018/2019)",
        "15,3": "(15\", 2018/2019)",
        "15,3": "(13\", 2019)",
        "16,1": "(16\", 2019)",
        "16,2": "(13\", 2020)",
        "16,3": "(13\", 2020)",
        "17,1": "(13\", M1, 2020)",
        "18,1": "(16\", 2021)",
        "18,2": "(16\", 2021)",
        "18,3": "(14\", 2021)",
        "18,4": "(14\", 2021)",
    ]

    private static let macBookAirModels = [
        "5,1": "(11\", Mid 2012)",
        "5,2": "(13\", Mid 2012)",
        "6,1": "(11\", Mid 2013/Early 2014)",
        "6,2": "(13\", Mid 2013/Early 2014)",
        "7,1": "(11\", Early 2015)",
        "7,2": "(13\", Early 2015/2017)",
        "8,1": "(13\", 2018)",
        "8,2": "(13\", 2019)",
        "9,1": "(13\", 2020)",
        "10,1": "(2020)",
    ]

    private static let macStudioModels = [
        "13,1": "(2022)",
        "13,2": "(2022)",
    ]

    private static func displayModel(for value: Any) -> String? {
        guard let modelID = value as? NSString else {
            return nil
        }

        if (modelID.hasPrefix("iMacPro")) {
            return self.displayModel(for: modelID, prefix: "iMacPro", modelName: "iMac Pro", models: self.iMacProModels)
        }
        if (modelID.hasPrefix("iMac")) {
            return self.displayModel(for: modelID, prefix: "iMac", modelName: "iMac", models: self.iMacModels)
        }
        if (modelID.hasPrefix("Macmini")) {
            return self.displayModel(for: modelID, prefix: "Macmini", modelName: "Mac Mini", models: self.macMiniModels)
        }
        if (modelID.hasPrefix("MacPro")) {
            return self.displayModel(for: modelID, prefix: "MacPro", modelName: "Mac Pro", models: self.macProModels)
        }
        if (modelID.hasPrefix("MacBookPro")) {
            return self.displayModel(for: modelID, prefix: "MacBookPro", modelName: "MacBook Pro", models: self.macBookProModels)
        }
        if (modelID.hasPrefix("MacBookAir")) {
            return self.displayModel(for: modelID, prefix: "MacBookAir", modelName: "MacBook Air", models: self.macBookAirModels)
        }
        if (modelID.hasPrefix("MacBook")) {
            return self.displayModel(for: modelID, prefix: "MacBook", modelName: "MacBook", models: self.macBookModels)
        }
        if (modelID.hasPrefix("Mac")) {
            return self.displayModel(for: modelID, prefix: "Mac", modelName: "Mac Studio", models: self.macStudioModels)
        }
        return nil
    }

    private static func displayModel(for modelID: NSString, prefix: String, modelName: String, models: [String: String]) -> String {
        let keySuffix = modelID.substring(from: prefix.count)
        if let nameSuffix = models[keySuffix] {
            return "\(modelName) \(nameSuffix)"
        }
        return modelName
    }
}
