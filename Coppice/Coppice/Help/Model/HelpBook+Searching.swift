//
//  HelpBook+Searching.swift
//  Coppice
//
//  Created by Martin Pilkington on 23/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension HelpBook {
    struct SearchResult {
        var topic: Topic
        var relevance: Float
    }

    func topics(matchingSearchString searchString: String) -> [SearchResult] {
        var results = [SearchResult]()
        for topic in self.allTopics {
            let lowercaseTitle = topic.title.lowercased()
            let lowercaseSearch = searchString.lowercased()
            var relevance = 0
            if lowercaseTitle.contains(lowercaseSearch) {
                relevance += 5
                if lowercaseTitle == lowercaseSearch {
                    relevance = 10
                }
            }
            let components = lowercaseSearch.split(separator: " ")
            for component in components {
                if (lowercaseTitle.contains(component)) {
                    relevance += 2
                }
                if (topic.tags.contains(String(component))) {
                    relevance += 2
                }
            }
            if (relevance > 0) {
                results.append(SearchResult(topic: topic, relevance: Float(min(relevance, 10)) / 10.0))
            }
        }

        return results.sorted { $0.relevance > $1.relevance }
    }
}
