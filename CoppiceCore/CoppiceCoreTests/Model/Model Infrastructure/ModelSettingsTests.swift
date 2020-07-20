//
//  ModelSettingsTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 09/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import CoppiceCore

class ModelSettingsTests: XCTestCase {

    //MARK: - value(for:)
    func test_valueForSetting_returnsSettingIfItExists() {
        let settings = ModelSettings()
        settings.set("Foobar", for: .genericKey)

        XCTAssertEqual(settings.value(for: .genericKey) as? String, "Foobar")
    }

    func test_valueForSetting_returnsNilIfSettingDoesntExist() {
        let settings = ModelSettings()
        XCTAssertNil(settings.value(for: .genericKey))
    }


    //MARK: - set(_:for:)
    func test_setValueForSetting_updatesSettingIfItExists() {
        let settings = ModelSettings()
        settings.set("Foobar", for: .genericKey)
        settings.set("Baz", for: .genericKey)

        XCTAssertEqual(settings.value(for: .genericKey) as? String, "Baz")
    }

    func test_setValueForSetting_removesSettingIfPassedNil() {
        let settings = ModelSettings()
        settings.set("Foobar", for: .genericKey)
        settings.set(nil, for: .genericKey)

        XCTAssertNil(settings.value(for: .genericKey))
    }


    //MARK: - string(for:)
    func test_stringForSetting_returnsValuesIfSetAndString() {
        let settings = ModelSettings()
        settings.set("Foobar", for: .stringKey)

        XCTAssertEqual(settings.string(for: .stringKey), "Foobar")
    }

    func test_stringForSetting_returnsNilIfValueSetButNotString() {
        let settings = ModelSettings()
        settings.set(42, for: .stringKey)

        XCTAssertNil(settings.string(for: .stringKey))
    }

    func test_stringForSetting_returnsNilIfValueNotSet() {
        let settings = ModelSettings()

        XCTAssertNil(settings.string(for: .stringKey))
    }


    //MARK: - integer(for:)
    func test_integerForSetting_returnsIntegerIfSetAndInteger() {
        let settings = ModelSettings()
        settings.set(42, for: .integerKey)

        XCTAssertEqual(settings.integer(for: .integerKey), 42)
    }

    func test_integerForSetting_returnsNilIfSetButNotInteger() {
        let settings = ModelSettings()
        settings.set(true, for: .integerKey)
        XCTAssertNil(settings.integer(for: .integerKey))
    }

    func test_integerForString_returnsNilIfValueNotSet() {
        let settings = ModelSettings()
        XCTAssertNil(settings.integer(for: .integerKey))
    }


    //MARK: - bool(for:)
    func test_boolForSetting_returnsBoolIfSetAndBool() {
        let settings = ModelSettings()
        settings.set(true, for: .boolKey)
        XCTAssertEqual(settings.bool(for: .boolKey), true)
    }

    func test_boolForSetting_returnsNilIfSetButNotBool() {
        let settings = ModelSettings()
        settings.set("Foobar", for: .boolKey)
        XCTAssertNil(settings.bool(for: .boolKey))
    }

    func test_boolForSetting_returnsNilIfNotSet() {
        let settings = ModelSettings()
        XCTAssertNil(settings.bool(for: .boolKey))
    }


    //MARK: - modelID(for:)
    func test_modelIDForSetting_returnsModelIDIfSetAndModelIDString() {
        let modelID = TestModelObject.modelID(with: UUID())
        let settings = ModelSettings()
        settings.set(modelID.stringRepresentation, for: .modelIDKey)
        XCTAssertEqual(settings.modelID(for: .modelIDKey), modelID)
    }

    func test_modelIDForSetting_returnsNilIfSetButNotModelIDString() {
        let settings = ModelSettings()
        settings.set("Hello World", for: .modelIDKey)
        XCTAssertNil(settings.modelID(for: .modelIDKey))
    }

    func test_modelIDForSetting_returnsNilIfNotSet() {
        let settings = ModelSettings()
        XCTAssertNil(settings.modelID(for: .modelIDKey))
    }


    //MARK: - set(:ModelID, for:)
    func test_setModelIDForSetting_updatesModelIDIfAlreadyExists() {
        let modelID = TestModelObject.modelID(with: UUID())
        let modelID2 = TestModelObject.modelID(with: UUID())
        let settings = ModelSettings()
        settings.set(modelID, for: .modelIDKey)
        settings.set(modelID2, for: .modelIDKey)

        XCTAssertEqual(settings.modelID(for: .modelIDKey), modelID2)
    }

    func test_setModelIDForSetting_addsModelIDIfItDoesntAlreadyExist() {
        let modelID = TestModelObject.modelID(with: UUID())
        let settings = ModelSettings()
        settings.set(modelID, for: .modelIDKey)

        XCTAssertEqual(settings.modelID(for: .modelIDKey), modelID)
    }

    func test_setModelIDForSetting_removesModelIDIfNilSupplied() {
        let modelID = TestModelObject.modelID(with: UUID())
        let settings = ModelSettings()
        settings.set(modelID, for: .modelIDKey)
        settings.set(nil, for: .modelIDKey)

        XCTAssertNil(settings.modelID(for: .modelIDKey))
    }


    //MARK: - .plistRepresentation
    func test_plistRepresentation_returnsEmptyArrayIfEmpty() {
        let settings = ModelSettings()
        XCTAssertEqual(settings.plistRepresentation.count, 0)
    }

    func test_plistRepresentation_returnsAllSettingsinPlist() {
        let modelID = TestModelObject.modelID(with: UUID())
        let settings = ModelSettings()
        settings.set("Foo Bar", for: .stringKey)
        settings.set(42, for: .integerKey)
        settings.set(true, for: .boolKey)
        settings.set(modelID, for: .modelIDKey)

        let plist = settings.plistRepresentation
        XCTAssertEqual(plist["StringKey"] as? String, "Foo Bar")
        XCTAssertEqual(plist["IntegerKey"] as? Int, 42)
        XCTAssertEqual(plist["BoolKey"] as? Bool, true)
        XCTAssertEqual(plist["ModelIDKey"] as? String, modelID.stringRepresentation)
    }


    //MARK: - update(withPlist:)
    func test_updateWithPlist_addsNewValuesIfTheyDontExist() {
        let settings = ModelSettings()
        settings.update(withPlist: [
            "StringKey": "Testing",
            "BoolKey": true
        ])

        XCTAssertEqual(settings.string(for: .stringKey), "Testing")
        XCTAssertEqual(settings.bool(for: .boolKey), true)
        XCTAssertNil(settings.integer(for: .integerKey))
        XCTAssertNil(settings.modelID(for: .modelIDKey))
    }

    func test_updateWithPlist_removesOldValuesIfNotInPlist() {
        let settings = ModelSettings()
        settings.set("Testing", for: .stringKey)
        settings.set(42, for: .integerKey)
        settings.set(false, for: .boolKey)

        settings.update(withPlist: ["StringKey": "Testing"])

        XCTAssertEqual(settings.string(for: .stringKey), "Testing")
        XCTAssertNil(settings.bool(for: .stringKey))
        XCTAssertNil(settings.integer(for: .integerKey))
        XCTAssertNil(settings.modelID(for: .modelIDKey))
    }

    func test_updateWithPlist_updatesExistingValuesIfDifferentInPlist() {
        let modelID = TestModelObject.modelID(with: UUID())
        let modelID2 = TestModelObject.modelID(with: UUID())
        let settings = ModelSettings()
        settings.set("Testing", for: .stringKey)
        settings.set(42, for: .integerKey)
        settings.set(false, for: .boolKey)
        settings.set(modelID, for: .modelIDKey)

        settings.update(withPlist: [
            "StringKey": "Foobar",
            "IntegerKey": 31,
            "BoolKey": true,
            "ModelIDKey": modelID2.stringRepresentation
        ])

        XCTAssertEqual(settings.string(for: .stringKey), "Foobar")
        XCTAssertEqual(settings.integer(for: .integerKey), 31)
        XCTAssertEqual(settings.bool(for: .boolKey), true)
        XCTAssertEqual(settings.modelID(for: .modelIDKey), modelID2)
    }
}


extension ModelSettings.Setting {
    static let genericKey = ModelSettings.Setting(rawValue: "GenericKey")
    static let stringKey = ModelSettings.Setting(rawValue: "StringKey")
    static let integerKey = ModelSettings.Setting(rawValue: "IntegerKey")
    static let boolKey = ModelSettings.Setting(rawValue: "BoolKey")
    static let modelIDKey = ModelSettings.Setting(rawValue: "ModelIDKey")
}
