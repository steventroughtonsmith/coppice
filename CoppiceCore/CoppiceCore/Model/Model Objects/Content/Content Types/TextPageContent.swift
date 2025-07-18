//
//  Page.Content.Text.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import M3Data

extension Page.Content {
    public class Text: Page.Content {
        public override var contentType: Page.ContentType {
            return Page.ContentType.text
        }

        @Published public var text: NSAttributedString = NSAttributedString(string: "", attributes: [.font: Page.defaultFont]) {
            didSet {
                guard self.text != oldValue else {
                    return
                }
                self.findAllLinks()
                self.didChange(\Text.text, oldValue: oldValue)
            }
        }

        public override var maintainAspectRatio: Bool {
            return false
        }

        public init(modelFile: ModelFile) throws {
            if let textData = modelFile.data,
               let text = try? NSAttributedString(data: textData, options: [:], documentAttributes: nil)
            {
                self.text = text
            }
            super.init()
            self.otherMetadata = modelFile.metadata
            self.findAllLinks()
        }

        public init(data: Data? = nil) {
            if let textData = data,
               let text = try? NSAttributedString(data: textData, options: [:], documentAttributes: nil)
            {
                self.text = text
            }
            super.init()
            self.findAllLinks()
        }

        public override var modelFile: ModelFile {
            let textData = try? self.text.data(from: NSMakeRange(0, self.text.length),
                                               documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
            let filename = (self.page != nil) ? "\(self.page!.id.uuid.uuidString).rtf" : nil
            return ModelFile(type: self.contentType.rawValue, filename: filename, data: textData, metadata: self.otherMetadata)
        }

        public override func firstMatch(forSearchString searchString: String) -> PageContentMatch? {
            let range = (self.text.string as NSString).range(of: searchString, options: [.caseInsensitive, .diacriticInsensitive])
            guard range.location != NSNotFound else {
                return nil
            }
            return Match(range: range, textPageContent: self)
        }


        //MARK: - Sizing
        public override var initialContentSize: CGSize? {
            return self.contentSize(insideBounds: GlobalConstants.maxAutomaticTextSize, minimumSize: Page.standardSize)
        }

        public override var minimumContentSize: CGSize {
            return CGSize(width: 150, height: 100)
        }

        public override func sizeToFitContent(currentSize: CGSize) -> CGSize {
            var newContentSize = self.contentSize(insideBounds: CGSize(width: currentSize.width, height: 20000), minimumSize: Page.defaultMinimumContentSize)
            newContentSize.width = currentSize.width
            return newContentSize
        }

        private func contentSize(insideBounds bounds: CGSize, minimumSize: CGSize) -> CGSize {
            var contentSize = self.text.boundingRect(with: bounds, options: [.usesLineFragmentOrigin]).size
            let insets = GlobalConstants.textEditorInsets()

            let adjustedContentSize = contentSize.rounded().plus(width: insets.horizontalInsets, height: insets.verticalInsets)

            //Not sure why but we need to add an additional space to get the size correct
            contentSize.width = max(adjustedContentSize.width + 10, minimumSize.width)
            contentSize.height = max(adjustedContentSize.height + 20, minimumSize.height)
            return contentSize
        }

        //MARK: - Links
        private func findAllLinks() {
            var newLinks = Set<PageLink>()
            self.text.enumerateAttribute(.link, in: self.text.fullRange) { value, _, _ in
                guard let url = value as? URL else {
                    return
                }

                if let pageLink = PageLink(url: url) {
                    newLinks.insert(pageLink)
                }
            }

            if self.pageLinks != newLinks {
                self.pageLinks = newLinks
                NotificationCenter.default.post(name: .pageContentLinkDidChange, object: self)
            }
        }
    }
}


extension Page.Content.Text {
    public struct Match: PageContentMatch {
        public var range: NSRange
        public var textPageContent: Page.Content.Text

        public var string: String {
            return self.textPageContent.text.string
        }
    }
}
