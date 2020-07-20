//
//  ModelObjects+Searching.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

public extension Page {
    struct Match: Comparable {
        public enum MatchType: Equatable {
            case title(NSRange)
            case content(NSRange)
        }

        public static func < (lhs: Page.Match, rhs: Page.Match) -> Bool {
            switch lhs.matchType {
            case .title(_):
                switch rhs.matchType {
                case .title(_):
                    return lhs.page.title < rhs.page.title
                case .content(_):
                    return true
                }
            case .content(let lhsRange):
                switch rhs.matchType {
                case .title(_):
                    return false
                case .content(let rhsRange):
                    return lhsRange.location < rhsRange.location
                }
            }
        }

        public let page: Page
        public let matchType: MatchType
    }

    func match(forSearchTerm searchTerm: String) -> Match? {
        let titleRange = (self.title as NSString).range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive])
        if titleRange.location != NSNotFound {
            return Match(page: self, matchType: .title(titleRange))
        }

        let contentRange = self.content.firstRangeOf(searchTerm)
        if contentRange.location != NSNotFound {
            return Match(page: self, matchType: .content(contentRange))
        }

        return nil
    }
}

public extension ModelCollection where ModelType == Page {
    func matches(forSearchTerm searchTerm: String) -> [Page.Match] {
        return self.all.compactMap { $0.match(forSearchTerm: searchTerm) }.sorted { $0 < $1 }
    }
}



public extension Canvas {
    struct Match: Comparable {
        public enum MatchType: Equatable {
            case title(NSRange)
            case pages(Int)
        }
        public let canvas: Canvas
        public let matchType: MatchType

        public static func < (lhs: Canvas.Match, rhs: Canvas.Match) -> Bool {
            switch lhs.matchType {
            case .title(_):
                switch rhs.matchType {
                case .title(_):
                    return lhs.canvas.title < rhs.canvas.title
                case .pages(_):
                    return true
                }
            case .pages(let lhsCount):
                switch rhs.matchType {
                case .title(_):
                    return false
                case .pages(let rhsCount):
                    return lhsCount > rhsCount
                }
            }
        }
    }

    func match(forSearchTerm searchTerm: String) -> Match? {
        let titleRange = (self.title as NSString).range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive])
        if titleRange.location != NSNotFound {
            return Match(canvas: self, matchType: .title(titleRange))
        }

        let canvasPages = self.pages.filter { $0.page?.match(forSearchTerm: searchTerm) != nil }
        if canvasPages.count > 0 {
            return Match(canvas: self, matchType: .pages(canvasPages.count))
        }

        return nil
    }
}


public extension ModelCollection where ModelType == Canvas {
    func matches(forSearchTerm searchTerm: String) -> [Canvas.Match] {
        return self.all.compactMap { $0.match(forSearchTerm: searchTerm) }.sorted { $0 < $1 }
    }
}
