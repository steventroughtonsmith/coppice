//
//  TextPageContent.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import M3Data

public class TextPageContent: NSObject, PageContent {
    public let contentType = PageContentType.text
    @objc dynamic public  var text: NSAttributedString = NSAttributedString(string: "", attributes: [.font: Page.defaultFont]) {
        didSet {
            guard self.text != oldValue else {
                return
            }
            self.didChange(\.text, oldValue: oldValue)
        }
    }

    public var maintainAspectRatio: Bool {
        return false
    }

    public weak var page: Page?
    public private(set) var otherMetadata: [String: Any]?

    public init(modelFile: ModelFile) throws {
        if let textData = modelFile.data,
           let text = try? NSAttributedString(data: textData, options: [:], documentAttributes: nil)
        {
            self.text = text
        }
        self.otherMetadata = modelFile.metadata
    }

    public init(data: Data? = nil) {
        if let textData = data,
           let text = try? NSAttributedString(data: textData, options: [:], documentAttributes: nil)
        {
            self.text = text
        }
    }

    public var modelFile: ModelFile {
        let textData = try? self.text.data(from: NSMakeRange(0, self.text.length),
                                           documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let filename = (self.page != nil) ? "\(self.page!.id.uuid.uuidString).rtf" : nil
        return ModelFile(type: self.contentType.rawValue, filename: filename, data: textData, metadata: self.otherMetadata)
    }

    public func firstMatch(forSearchString searchString: String) -> PageContentMatch? {
        let range = (self.text.string as NSString).range(of: searchString, options: [.caseInsensitive, .diacriticInsensitive])
        guard range.location != NSNotFound else {
            return nil
        }
        return Match(range: range, textPageContent: self)
    }


    //MARK: - Sizing
    public var initialContentSize: CGSize? {
        return self.contentSize(insideBounds: GlobalConstants.maxAutomaticTextSize, minimumSize: Page.standardSize)
    }

    public var minimumContentSize: CGSize {
        return CGSize(width: 150, height: 100)
    }

    public func sizeToFitContent(currentSize: CGSize) -> CGSize {
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
}


extension TextPageContent {
    public struct Match: PageContentMatch {
        public var range: NSRange
        public var textPageContent: TextPageContent

        public var string: String {
            return self.textPageContent.text.string
        }
    }
}
