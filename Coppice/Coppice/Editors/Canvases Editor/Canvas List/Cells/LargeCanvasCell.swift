//
//  LargeCanvasCell.swift
//  Coppice
//
//  Created by Martin Pilkington on 30/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

class LargeCanvasCell: EditableLabelCell, CanvasCell {
    static var identifier = NSUserInterfaceItemIdentifier(rawValue: "LargeCanvasCell")

    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var thumbnailImageView: NSImageView!
    @IBOutlet weak var thumbnailBackground: NSBox!
    private var thumbnailObserver: AnyCancellable?
    override var objectValue: Any? {
        didSet {
            guard let canvas = self.objectValue as? Canvas else {
                return
            }
            var theme = canvas.theme
            if CoppiceSubscriptionManager.shared.state == .enabled {
                theme = .auto
            }
            self.thumbnailBackground.fillColor = theme.canvasBackgroundColor
            self.thumbnailImageView.image = canvas.thumbnail
            self.nameLabel.stringValue = canvas.title

            self.subscribers[.canvasTitle] = canvas.changePublisher(for: \.title)?.notify(self, ofChangeTo: \.canvasTitle)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        //We need to prevent the thumbnail from capturing drag events
        self.thumbnailImageView.unregisterDraggedTypes()
    }

    @objc dynamic var canvasTitle: String {
        get { return (self.objectValue as? Canvas)?.title ?? "" }
        set { (self.objectValue as? Canvas)?.title = newValue }
    }

    var springLoadEnabled = false

    //MARK: - Subscribers
    private enum SubscriberKey {
        case canvasTitle
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}
