//
//  Page.ContentType.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 03/01/2024.
//

import AppKit
import M3Data
import UniformTypeIdentifiers

extension Page {
    public enum ContentType: String, Equatable, CaseIterable {
        case text
        case image

        public func createContent(data: Data? = nil) -> Page.Content {
            switch self {
            case .text:
                return Page.Content.Text(data: data)
            case .image:
                return Page.Content.Image(data: data)
            }
        }

        public func createContent(modelFile: ModelFile) throws -> Page.Content {
            switch self {
            case .text:
                return try Page.Content.Text(modelFile: modelFile)
            case .image:
                return try Page.Content.Image(modelFile: modelFile)
            }
        }

        public static func contentType(forUTI uti: String) -> ContentType? {
            guard let type = UTType(uti) else {
                return nil
            }

            if type.conforms(to: .text) {
                return .text
            }
            if type.conforms(to: .image) {
                return .image
            }
            return nil
        }

        public var icon: NSImage {
            return icon(.small)
        }

        public func icon(_ size: Symbols.Size) -> NSImage {
            switch self {
            case .text:
                return NSImage.symbol(withName: Symbols.Page.text(size))!
            case .image:
                return NSImage.symbol(withName: Symbols.Page.image(size))!
            }
        }

        public var addIcon: NSImage {
            if ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 10 {
                return self.icon(.small)
            }
            return self.icon(.regular)
        }

        public var localizedName: String {
            switch self {
            case .text:
                return NSLocalizedString("Text Page", comment: "Text content name")
            case .image:
                return NSLocalizedString("Image Page", comment: "Image content name")
            }
        }

        public var keyEquivalent: String {
            switch self {
            case .text, .image:
                return "N"
            }
        }

        public var keyEquivalentModifierMask: NSEvent.ModifierFlags {
            switch self {
            case .text:
                return [.command, .shift]
            case .image:
                return [.option, .command]
            }
        }
    }
}
