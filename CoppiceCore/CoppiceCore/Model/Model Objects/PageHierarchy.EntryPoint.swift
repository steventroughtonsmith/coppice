//
//  PageHierarchy.EntryPoint.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 02/01/2024.
//

import Foundation
import M3Data

extension PageHierarchy {
    public struct EntryPoint: PlistConvertable {
        var pageLink: PageLink
        var relativePosition: CGPoint

        init(pageLink: PageLink, relativePosition: CGPoint) {
            self.pageLink = pageLink
            self.relativePosition = relativePosition
        }

        public func toPlistValue() throws -> PlistValue {
            return [
                "pageLink": try self.pageLink.toPlistValue(),
                "relativePosition": try self.relativePosition.toPlistValue(),
            ] as PlistValue
        }

        public static func fromPlistValue(_ plistValue: PlistValue) throws -> PageHierarchy.EntryPoint {
            guard
                let value = plistValue as? [String: PlistValue],
                let pageLink = value["pageLink"],
                let relativePosition = value["relativePosition"]
            else {
                throw PlistConvertableError.invalidConversionFromPlistValue
            }
            return EntryPoint(pageLink: try .fromPlistValue(pageLink),
                              relativePosition: try .fromPlistValue(relativePosition))
        }
    }
}
