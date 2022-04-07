//
//  LinkFinder.swift
//  Coppice
//
//  Created by Martin Pilkington on 07/04/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Foundation

import CoppiceCore

class LinkFinder {
    /// Generate a list of all uniquely titled pages we can use for auto linking
    static func autoLinkCandidates(from pages: [Page], ignoring ignoredPages: [Page]) -> [Page] {
        var autoLinkCandidates = [Page]()
        for page in pages {
            guard
                page.title != Page.localizedDefaultTitle, //Ignore default
                ignoredPages.contains(page) == false //Ignore anything we want to ignore (usually the page itself)
            else {
                continue
            }
            if let index = autoLinkCandidates.firstIndex(where: { $0.title == page.title }) {
                autoLinkCandidates.remove(at: index)
                continue
            }
            autoLinkCandidates.append(page)
        }
        return autoLinkCandidates
    }

    static func validateAutoLinks(in scratchPad: LinkScratchPad) {
        scratchPad.enumerateUnrejectedPoints { (links) in
            if links.count == 1 {
                if links[0].state == .unknown {
                    links[0].state = (links[0].age == .new) ? .accepted : .rejected
                }
            } else if links.filter({ $0.state == .accepted }).count > 0 {
                links.filter { $0.state != .accepted }.forEach { $0.state = .rejected }
            }
            //If we ever get to this part then we have multiple links, none of which have been accepted. This means they all start at the same location
            else {
                var currentLink: LinkInfo?
                for link in links {
                    guard let current = currentLink else {
                        currentLink = link
                        continue
                    }

                    if current.range.length > link.range.length {
                        link.state = .rejected
                    } else if current.range.length < link.range.length {
                        current.state = .rejected
                        currentLink = link
                    } else if current.range.length == link.range.length {
                        if link.age == .new {
                            link.state = .rejected
                        } else {
                            current.state = .rejected
                            currentLink = link
                        }
                    }
                }
                currentLink?.state = .accepted
            }
        }
    }

    /// Create a scratch pad for testing overlapping links
    static func createScratchPad(from links: [LinkInfo], currentIndex: inout Int) -> LinkScratchPad {
        var scratchPadLinks = [LinkInfo]()
        var currentRange: NSRange? = nil
        while currentIndex < links.count {
            let link = links[currentIndex]
            guard let range = currentRange else {
                currentRange = link.range
                scratchPadLinks.append(link)
                currentIndex += 1
                continue
            }

            //If the next link range doesn't overlap with our existing range then break out, as we'll create a new scratch pad for the next links
            guard link.range.intersection(range) != nil else {
                break
            }

            currentIndex += 1
            currentRange = range.union(link.range)
            scratchPadLinks.append(link)
        }
        return LinkScratchPad(links: scratchPadLinks)
    }

    /// Find all potential links for a page
    static func autoLinks(for page: Page, in string: String) -> [LinkInfo] {
        let escapedTitle = NSRegularExpression.escapedPattern(for: self.normaliseQuotes(in: page.title))
        guard let regex = try? NSRegularExpression(pattern: "((?<=\\W|_)|^)\(escapedTitle)((?=\\W|_)|$)", options: [.caseInsensitive]) else {
            return []
        }
        let matches = regex.matches(in: self.normaliseQuotes(in: string), options: [], range: (string as NSString).fullRange)
        return matches.map { LinkInfo(range: $0.range, page: page, linkType: .auto, age: .new) }
    }

    private static func normaliseQuotes(in string: String) -> String {
        return string
            .replacingOccurrences(of: "(‘|’)", with: "'", options: .regularExpression, range: nil)
            .replacingOccurrences(of: "(“|”)", with: "\"", options: .regularExpression, range: nil)
    }
}

extension LinkFinder {
    class LinkInfo: Equatable {
        static func == (lhs: LinkInfo, rhs: LinkInfo) -> Bool {
            return lhs.age == rhs.age &&
            lhs.page == rhs.page &&
            lhs.linkType == rhs.linkType &&
            lhs.state == rhs.state &&
            lhs.age == rhs.age
        }

        enum State: Equatable {
            case unknown
            case accepted
            case rejected
        }

        enum Age: Equatable {
            case new
            case existing
        }

        enum LinkType: Equatable {
            case manual
            case auto
            case external
        }

        let range: NSRange
        let page: Page?
        let linkType: LinkType
        var state: State = .unknown
        var age: Age

        init(range: NSRange, page: Page?, linkType: LinkType, age: Age) {
            self.range = range
            self.page = page
            self.linkType = linkType
            self.age = age
            if (linkType != .external) && (page == nil) {
                self.state = .rejected
            }
        }

        var description: String {
            return "LinkInfo: { range: \(self.range), page: \(self.page?.title ?? "nil"), linkType: \(self.linkType), age: \(self.age), state: \(self.state)}"
        }
    }

    class LinkScratchPad {
        let links: [LinkInfo]
        private let unrejectedAutoLinksByPoint: [[LinkInfo]]
        init(links: [LinkInfo]) {
            self.links = links
            self.unrejectedAutoLinksByPoint = LinkScratchPad.groupAutoLinksByPoint(links: links)
        }

        private static func groupAutoLinksByPoint(links: [LinkInfo]) -> [[LinkInfo]] {
            guard links.count > 0 else {
                return []
            }
            var fullRange: NSRange!
            for link in links {
                guard let range = fullRange else {
                    fullRange = link.range
                    continue
                }
                fullRange = range.union(link.range)
            }

            var groupedLinks = Array(repeating: [LinkInfo](), count: fullRange.length)
            for link in links {
                guard link.linkType == .auto else {
                    continue
                }
                let startIndex = link.range.location - fullRange.location
                let endIndex = NSMaxRange(link.range) - fullRange.location
                (startIndex..<endIndex).forEach { (index) in
                    var group = groupedLinks[index]
                    group.append(link)
                    groupedLinks[index] = group
                }
            }

            var currentGroup: [LinkInfo]?
            var condensedGroupLinks = [[LinkInfo]]()
            for group in groupedLinks {
                guard let current = currentGroup else {
                    condensedGroupLinks.append(group)
                    currentGroup = group
                    continue
                }
                guard group != current else {
                    continue
                }
                condensedGroupLinks.append(group)
                currentGroup = group
            }
            return condensedGroupLinks
        }

        func enumerateUnrejectedPoints(_ block: ([LinkInfo]) -> Void) {
            self.unrejectedAutoLinksByPoint.forEach { linkInfo in
                block(linkInfo.filter { $0.state != .rejected })
            }
        }
    }
}
