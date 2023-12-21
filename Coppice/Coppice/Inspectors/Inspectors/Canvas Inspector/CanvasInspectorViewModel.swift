//
//  CanvasInspectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import CoppiceCore
import Foundation
import M3Data
import M3Subscriptions

protocol CanvasInspectorView: AnyObject {}


class CanvasInspectorViewModel: BaseInspectorViewModel {
    weak var view: CanvasInspectorView?

    let canvas: Canvas
    let modelController: ModelController
    init(canvas: Canvas, modelController: ModelController) {
        self.canvas = canvas
        self.modelController = modelController
        super.init()

        self.subscribers[.canvasTitle] = canvas.changePublisher(for: \.title)?.notify(self, ofChangeTo: \.canvasTitle)
        self.subscribers[.alwaysShowPageTitles] = canvas.changePublisher(for: \.alwaysShowPageTitles)?.notify(self, ofChangeTo: \.alwaysShowPageTitles)
    }

    override var title: String? {
        return NSLocalizedString("Canvas", comment: "Canvas inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.page"
    }

    @objc dynamic var canvasTitle: String {
        get { self.canvas.title }
        set { self.canvas.title = newValue }
    }

    @objc dynamic var themes: [String] {
        return Canvas.Theme.allCases.map(\.localizedName)
    }

    @objc dynamic var selectedThemeIndex: Int {
        get {
            guard self.isProEnabled else {
                return 0
            }
            return Canvas.Theme.allCases.firstIndex(of: self.canvas.theme) ?? 0
        }
        set {
            guard self.isProEnabled else {
                return
            }
            self.canvas.theme = Canvas.Theme.allCases[newValue]
        }
    }

    @objc dynamic var alwaysShowPageTitles: Bool {
        get { self.canvas.alwaysShowPageTitles }
        set { self.canvas.alwaysShowPageTitles = newValue }
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case canvasTitle
        case alwaysShowPageTitles
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}
