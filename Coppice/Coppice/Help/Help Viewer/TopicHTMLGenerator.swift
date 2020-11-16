//
//  TopicHTMLGenerator.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/11/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class TopicHTMLGenerator: NSObject {
    func generateHTML(for topic: HelpBook.Topic) -> String? {
        guard var content = topic.helpBook?.content(for: topic) else {
            return self.generatePage(with: topic.title, content: "<p>Topic not found</p>")
        }

        content = replaceLinks(inContent: content)
        content = replaceImages(inContent: content)
        content = replaceBundleInfo(inContent: content)

        return generatePage(with: topic.title, content: content)
    }

    private func generatePage(with title: String, content: String) -> String {
        return """
<html>
<head>
    <meta charset="utf-8">
    <title>\(title)</title>
    <link rel="stylesheet" href="../_resources/stylesheet.css">
</head>
<body>
\(content)
</body>
</html>
"""
    }

    private let imageRegex = try! NSRegularExpression(pattern: "\\{\\[image\\|(.*?)\\|(.*?)\\]\\}", options: .caseInsensitive)
    private let linkRegex = try! NSRegularExpression(pattern: "\\{\\[link\\|(.*?)\\|(.*?)\\]\\}", options: .caseInsensitive)

    private func replaceLinks(inContent content: String) -> String {
        let results = self.linkRegex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count)).reversed()
        var nsContent = (content as NSString)
        for result in results {
            guard result.numberOfRanges == 3 else {
                continue
            }

            let linkID = nsContent.substring(with: result.range(at: 1))
            let linkName = nsContent.substring(with: result.range(at: 2))

            let link = "<a href=\"coppice-help://\(linkID)\">\(linkName)</a>"
            nsContent = nsContent.replacingCharacters(in: result.range, with: link) as NSString
        }
        return nsContent as String
    }

    private func replaceImages(inContent content: String) -> String {
        let results = self.imageRegex.matches(in: content, options: [], range: NSRange(location: 0, length: content.count)).reversed()
        var nsContent = (content as NSString)
        for result in results {
            guard result.numberOfRanges == 3 else {
                continue
            }

            let imageSrc = nsContent.substring(with: result.range(at: 1))
            let attributes = nsContent.substring(with: result.range(at: 2))

            let image = "<img src=\"\(imageSrc)\" \(attributes)>"
            nsContent = nsContent.replacingCharacters(in: result.range, with: image) as NSString
        }
        return nsContent as String
    }

    private func replaceBundleInfo(inContent content: String) -> String {
        let value = (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "Unknown"
        return content.replacingOccurrences(of: "{[bundleinfo|CFBundleShortVersionString]}", with: value)
    }
}
