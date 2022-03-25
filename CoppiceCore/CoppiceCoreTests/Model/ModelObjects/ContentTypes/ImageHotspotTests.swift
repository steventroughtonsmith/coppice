//
//  ImageHotspotTests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 21/02/2022.
//

import XCTest

@testable import CoppiceCore

class ImageHotspotTests: XCTestCase {
    //MARK: - init(dictionaryRepresentation:)
    func test_initDictionaryRepresentation_initialisesIfKindAndPointsAreInDictionary() throws {
        let dictionary: [String: Any] = [
            "kind": "polygon",
            "points": [["X": 42.1, "Y": 60], ["X": 90, "Y": 60], ["X": -12.3, "Y": 1234.5]],
        ]

        let hotspot = try ImageHotspot(dictionaryRepresentation: dictionary)
        XCTAssertEqual(hotspot.kind, .polygon)
        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 42.1, y: 60),
            CGPoint(x: 90, y: 60),
            CGPoint(x: -12.3, y: 1234.5),
        ])
    }

    func test_initDictionaryReprsentation_initialisesIfLinkIsNotInDictionary() throws {
        let dictionary: [String: Any] = [
            "kind": "polygon",
            "points": [["X": 42.1, "Y": 60], ["X": 90, "Y": 60], ["X": -12.3, "Y": 1234.5]],
        ]

        XCTAssertNoThrow(try ImageHotspot(dictionaryRepresentation: dictionary))
    }

    func test_initDictionaryRepresentation_setsLinkIfLinkIsInDictionary() throws {
        let dictionary: [String: Any] = [
            "kind": "polygon",
            "points": [["X": 42.1, "Y": 60], ["X": 90, "Y": 60], ["X": -12.3, "Y": 1234.5]],
            "link": "https://twitch.tv/pilkycrc",
        ]

        let hotspot = try ImageHotspot(dictionaryRepresentation: dictionary)
        XCTAssertEqual(hotspot.link, URL(string: "https://twitch.tv/pilkycrc")!)
    }

    func test_initDictionaryRepresentation_throwsAttributeNotFoundIfKindNotInDictionary() throws {
        let dictionary: [String: Any] = [
            "points": [["X": 42.1, "Y": 60], ["X": 90, "Y": 60], ["X": -12.3, "Y": 1234.5]],
        ]

        XCTAssertThrowsError(try ImageHotspot(dictionaryRepresentation: dictionary)) {
            XCTAssertEqual(($0 as? ImageHotspotErrors), .attributeNotFound("kind"))
        }
    }

    func test_initDictionaryRepresentation_throwsAttributeNotFoundIfKindNotValidValue() throws {
        let dictionary: [String: Any] = [
            "kind": 42,
            "points": [["X": 42.1, "Y": 60], ["X": 90, "Y": 60], ["X": -12.3, "Y": 1234.5]],
        ]

        XCTAssertThrowsError(try ImageHotspot(dictionaryRepresentation: dictionary)) {
            XCTAssertEqual(($0 as? ImageHotspotErrors), .attributeNotFound("kind"))
        }
    }

    func test_initDictionaryRepresentation_throwsAttributeNotFoundIfPointsNotInDictionary() throws {
        let dictionary: [String: Any] = [
            "kind": "polygon",
        ]

        XCTAssertThrowsError(try ImageHotspot(dictionaryRepresentation: dictionary)) {
            XCTAssertEqual(($0 as? ImageHotspotErrors), .attributeNotFound("points"))
        }
    }

    func test_initDictionaryRepresentation_throwsInvalidPointIfAPointInDictionaryNotValidValue() throws {
        let dictionary: [String: Any] = [
            "kind": "polygon",
            "points": [["X": 42.1, "Y": 60], ["A": 5, "Y": 60], ["X": -12.3, "Y": 1234.5]],
        ]

        XCTAssertThrowsError(try ImageHotspot(dictionaryRepresentation: dictionary)) {
            XCTAssertEqual(($0 as? ImageHotspotErrors), .invalidPoint)
        }
    }


    //MARK: - .dictionaryRepresentation
    func test_dictionaryRepresentation_includesKindAndPoints() throws {
        let hotspot = ImageHotspot(kind: .oval, points: [
            CGPoint(x: 20, y: 52.1),
            CGPoint(x: 96.2, y: 52.1),
            CGPoint(x: 96.2, y: 60),
            CGPoint(x: 20, y: 60),
        ])

        let dictionary = hotspot.dictionaryRepresentation
        XCTAssertEqual(dictionary["kind"] as? String, "oval")
        XCTAssertEqual(dictionary["points"] as? [[String: Double]], [
            ["X": 20, "Y": 52.1],
            ["X": 96.2, "Y": 52.1],
            ["X": 96.2, "Y": 60],
            ["X": 20, "Y": 60],
        ])
    }

    func test_dictionaryRepresentation_includesLinkIfItIsSet() throws {
        let hotspot = ImageHotspot(kind: .oval, points: [], link: URL(string: "https://coppiceapp.com")!)

        XCTAssertEqual(hotspot.dictionaryRepresentation["link"] as? String, "https://coppiceapp.com")
    }
}
