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
import M3Subscriptions

protocol CanvasInspectorView: AnyObject {}


class CanvasInspectorViewModel: BaseInspectorViewModel {
    weak var view: CanvasInspectorView?

    @objc dynamic let canvas: Canvas
    let modelController: ModelController
    init(canvas: Canvas, modelController: ModelController) {
        self.canvas = canvas
        self.modelController = modelController
        super.init()
        self.setupProObservation()
    }

    override var title: String? {
        return NSLocalizedString("Canvas", comment: "Canvas inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.page"
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(canvasTitle)) {
            keyPaths.insert("canvas.title")
        }
        return keyPaths
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


    //MARK: - Pro
    @objc dynamic var isProEnabled = false

    var activationObserver: AnyCancellable?
    private func setupProObservation() {
        self.activationObserver = CoppiceSubscriptionManager.shared.$activationResponse
            .map { $0?.isActive ?? false }
            .assign(to: \.isProEnabled, on: self)
    }
}
