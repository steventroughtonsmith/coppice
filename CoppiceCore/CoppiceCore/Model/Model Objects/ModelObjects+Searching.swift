//
//  ModelObjects+Searching.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import M3Data
import Vision

extension Page {
    public struct Match: Comparable {
        public enum MatchType {
            case title(NSRange)
            case content(PageContentMatch)
        }

        public static func < (lhs: Page.Match, rhs: Page.Match) -> Bool {
            switch lhs.matchType {
            case .title:
                switch rhs.matchType {
                case .title:
                    return lhs.page.title < rhs.page.title
                case .content:
                    return true
                }
            case .content(let lhsContent):
                switch rhs.matchType {
                case .title:
                    return false
                case .content(let rhsContent):
                    return lhsContent.range.location < rhsContent.range.location
                }
            }
        }

        public static func == (lhs: Page.Match, rhs: Page.Match) -> Bool {
            guard lhs.page == rhs.page else {
                return false
            }

            switch (lhs.matchType, rhs.matchType) {
            case (.title(let range1), .title(let range2)):
                return range1 == range2
            case (.content(let content1), .content(let content2)):
                return content1.range == content2.range
            default:
                return false
            }
        }


        public let page: Page
        public let matchType: MatchType
    }

    public func match(forSearchString searchString: String) -> Match? {
        let titleRange = (self.title as NSString).range(of: searchString, options: [.caseInsensitive, .diacriticInsensitive])
        if titleRange.location != NSNotFound {
            return Match(page: self, matchType: .title(titleRange))
        }

        if let contentMatch = self.content.firstMatch(forSearchString: searchString) {
            return Match(page: self, matchType: .content(contentMatch))
        }

        return nil
    }
}

extension ModelCollection where ModelType == Page {
    public func matches(forSearchString searchString: String) -> [Page.Match] {
        return self.all.compactMap { $0.match(forSearchString: searchString) }.sorted { $0 < $1 }
    }
}



extension Canvas {
    public struct Match: Comparable {
        public enum MatchType: Equatable {
            case title(NSRange)
            case pages(Int)
        }

        public let canvas: Canvas
        public let matchType: MatchType

        public static func < (lhs: Canvas.Match, rhs: Canvas.Match) -> Bool {
            switch lhs.matchType {
            case .title:
                switch rhs.matchType {
                case .title:
                    return lhs.canvas.title < rhs.canvas.title
                case .pages:
                    return true
                }
            case .pages(let lhsCount):
                switch rhs.matchType {
                case .title:
                    return false
                case .pages(let rhsCount):
                    return lhsCount > rhsCount
                }
            }
        }
    }

    public func match(forSearchString searchString: String) -> Match? {
        let titleRange = (self.title as NSString).range(of: searchString, options: [.caseInsensitive, .diacriticInsensitive])
        if titleRange.location != NSNotFound {
            return Match(canvas: self, matchType: .title(titleRange))
        }

        let canvasPages = self.pages.filter { $0.page?.match(forSearchString: searchString) != nil }
        if canvasPages.count > 0 {
            return Match(canvas: self, matchType: .pages(canvasPages.count))
        }

        return nil
    }
}


extension ModelCollection where ModelType == Canvas {
    public func matches(forSearchString searchString: String) -> [Canvas.Match] {
        return self.all.compactMap { $0.match(forSearchString: searchString) }.sorted { $0 < $1 }
    }
}


public protocol PageContentMatch {
    var range: NSRange { get }
    var string: String { get }
}


