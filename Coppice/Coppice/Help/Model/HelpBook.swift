//
//  HelpBook.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

class HelpBook: Codable {
    class Group: Codable, Equatable {
        var id: String
        var title: String
        var topicIDs: [String]
        weak var helpBook: HelpBook?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case topicIDs = "topics"
        }

        static func == (lhs: Group, rhs: Group) -> Bool {
            return lhs.id == rhs.id
        }
    }

    class Topic: Codable, Equatable {
        var id: String
        var title: String
        var versionIntroduced: String
        var versionUpdated: String
        var tags: [String] = []
        weak var helpBook: HelpBook?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case versionIntroduced
            case versionUpdated
            case tags
        }

        static func == (lhs: Topic, rhs: Topic) -> Bool {
            return lhs.id == rhs.id
        }

        init(id: String, title: String, versionIntroduced: String, versionUpdated: String, tags: [String]) {
            self.id = id
            self.title = title
            self.versionIntroduced = versionIntroduced
            self.versionUpdated = versionUpdated
            self.tags = tags
        }

        var isNewInCurrentVersion: Bool {
            guard let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
                return false
            }
            return versionString.hasPrefix(self.versionIntroduced)
        }
    }

    enum CodingKeys: String, CodingKey {
        case allGroups = "groups"
        case allTopics = "topics"
    }

    private(set) var allGroups: [Group]
    private(set) var allTopics: [Topic]
    let url: URL

    enum DecodingError: Error {
        case noURLSupplied
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.allGroups = try container.decode([Group].self, forKey: .allGroups)
        self.allTopics = try container.decode([Topic].self, forKey: .allTopics)

        guard let url = decoder.userInfo[.helpBookURL] as? URL else {
            throw DecodingError.noURLSupplied
        }
        self.url = url

        self.allGroups.forEach { $0.helpBook = self }
        self.allTopics.forEach { $0.helpBook = self }
    }

    func topic(withID id: String) -> Topic? {
        return self.allTopics.first(where: { $0.id == id })
    }

    lazy var home: Topic = {
        let topic = HelpBook.Topic(id: "_home", title: "Home", versionIntroduced: "2020.1", versionUpdated: "2020.1", tags: [])
        topic.helpBook = self
        return topic
    }()

    func content(for topic: Topic) -> String? {
        let targetURL = self.url.appendingPathComponent(topic.id).appendingPathComponent("index.html")
        return try? String(contentsOf: targetURL)
    }
}
