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

        static func ==(lhs: Group, rhs: Group) -> Bool {
            return lhs.id == rhs.id
        }
    }

    class Topic: Codable, Equatable {
        var id: String
        var title: String
        var dateUpdated: Date
        var dateCreated: Date?
        var tags: [String] = []
        weak var helpBook: HelpBook?

        enum CodingKeys: String, CodingKey {
            case id
            case title
            case dateUpdated
            case dateCreated
            case tags
        }

        static func ==(lhs: Topic, rhs: Topic) -> Bool {
            return lhs.id == rhs.id
        }
    }

    enum CodingKeys: String, CodingKey {
        case indexID = "index"
        case allGroups = "groups"
        case allTopics = "topics"
    }

    private let indexID: String
    private(set) var allGroups: [Group]
    private(set) var allTopics: [Topic]
    let url: URL

    enum DecodingError: Error {
        case noURLSupplied
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.indexID = try container.decode(String.self, forKey: .indexID)
        self.allGroups = try container.decode([Group].self, forKey: .allGroups)
        self.allTopics = try container.decode([Topic].self, forKey: .allTopics)

        guard let url = decoder.userInfo[.helpBookURL] as? URL else {
            throw DecodingError.noURLSupplied
        }
        self.url = url

        self.allGroups.forEach { $0.helpBook = self }
        self.allTopics.forEach { $0.helpBook = self }
    }


    var index: Topic {
        guard let topic = self.topic(withID: self.indexID) else {
            preconditionFailure("You have not specified a valid index topic")
        }
        return topic
    }

    func topic(withID id: String) -> Topic? {
        return self.allTopics.first(where: {$0.id == id})
    }


    func content(for topic: Topic) -> String? {
        let targetURL = self.url.appendingPathComponent(topic.id).appendingPathComponent("index.html")
        return try? String(contentsOf: targetURL)
    }
}
