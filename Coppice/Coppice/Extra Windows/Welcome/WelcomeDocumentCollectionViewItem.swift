//
//  WelcomeDocumentCollectionViewItem.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa
import QuickLookThumbnailing
import QuickLookUI

protocol WelcomeDocumentCollectionViewItemDelegate: NSObject {
    func didDoubleClick(on collectionViewItem: WelcomeDocumentCollectionViewItem)
}

class WelcomeDocumentCollectionViewItem: NSCollectionViewItem {
    override var representedObject: Any? {
        didSet {
            self.reloadData()
        }
    }

    weak var delegate: WelcomeDocumentCollectionViewItemDelegate?

    var recentDocument: RecentDocument? {
        return self.representedObject as? RecentDocument
    }

    @IBOutlet weak var previewContainerView: NSView!
    {
        didSet {
            self.previewContainerView.wantsLayer = true
            self.previewContainerView.layer?.cornerRadius = 15
            self.previewContainerView.layer?.masksToBounds = false
            self.previewContainerView.layer?.borderColor = NSColor.black.withAlphaComponent(0.2).cgColor
            self.previewContainerView.layer?.borderWidth = 1

            self.previewContainerView.layer?.shadowOpacity = 0.15
        }
    }

    var previewAspectRatioConstraint: NSLayoutConstraint? {
        didSet {
            guard oldValue != self.previewAspectRatioConstraint else {
                return
            }

            oldValue?.isActive = false
            self.previewAspectRatioConstraint?.isActive = true
        }
    }

    @IBOutlet weak var previewImageView: NSImageView! {
        didSet {
            self.previewImageView.wantsLayer = true
            self.previewImageView.layer?.cornerRadius = 15
            self.previewImageView.layer?.masksToBounds = true
        }
    }

    private lazy var quickLookPreview: QLPreviewView = {
        return QLPreviewView(frame: .zero, style: .normal)
    }()


    @IBOutlet weak var labelSelectionBackground: NSBox!
    @IBOutlet weak var label: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadData()

        let clickRecogniser = NSClickGestureRecognizer(target: self, action: #selector(self.doubleClick(_:)))
        clickRecogniser.numberOfClicksRequired = 2
        self.view.addGestureRecognizer(clickRecogniser)
    }

    private func reloadData() {
        guard let document = self.recentDocument, self.isViewLoaded else {
            return
        }

        self.label.stringValue = document.name

        let preview = document.preview
        self.previewImageView.image = preview
        self.previewAspectRatioConstraint = self.previewImageView.widthAnchor.constraint(equalTo: self.previewImageView.heightAnchor, multiplier: preview.size.width / preview.size.height)
        self.updateSelectedState()
    }


    //MARK: - Actions
    @objc func doubleClick(_ sender: Any) {
        self.delegate?.didDoubleClick(on: self)
    }

    @IBAction func revealInFinder(_ sender: Any) {
        guard let document = self.recentDocument else {
            return
        }
        NSWorkspace.shared.selectFile(document.url.path, inFileViewerRootedAtPath: "")
    }




    //MARK: - Selection
    override var isSelected: Bool {
        didSet {
            self.updateSelectedState()
        }
    }

    private func updateSelectedState() {
        if self.view.effectiveAppearance.isDarkMode {
            self.label.textColor = self.isSelected ? NSColor(named: "CoppiceGreen")! : .white
            self.labelSelectionBackground.fillColor = self.isSelected ? .white : .clear

            let previewBorder: NSColor = self.isSelected ? .white.withAlphaComponent(0.7) : .black.withAlphaComponent(0.2)
            self.previewContainerView.layer?.borderColor = previewBorder.cgColor
            self.previewContainerView.layer?.borderWidth = self.isSelected ? 3 : 1
        } else {
            self.label.textColor = self.isSelected ? .white : .labelColor
            self.labelSelectionBackground.fillColor = self.isSelected ? .controlAccentColor : .clear

            let previewBorder: NSColor = self.isSelected ? .controlAccentColor : .black.withAlphaComponent(0.2)
            self.previewContainerView.layer?.borderColor = previewBorder.cgColor
            self.previewContainerView.layer?.borderWidth = self.isSelected ? 3 : 1
        }
    }


    //MARK: - Layout
    override func preferredLayoutAttributesFitting(_ layoutAttributes: NSCollectionViewLayoutAttributes) -> NSCollectionViewLayoutAttributes {
        if let document = self.recentDocument {
            var size = layoutAttributes.size
            let scaledPreviewSize = document.preview.size.scaleDownToFit(CGSize(width: 210, height: 160))
            size.width = max(min(scaledPreviewSize.width, 210), 130)
            layoutAttributes.size = size
        }
        return layoutAttributes
    }
}
