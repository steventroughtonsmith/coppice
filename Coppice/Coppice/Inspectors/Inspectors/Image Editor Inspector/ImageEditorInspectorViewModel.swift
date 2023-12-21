//
//  ImageEditorInspectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

class ImageEditorInspectorViewModel: BaseInspectorViewModel {
    let editorViewModel: ImageEditorViewModel
    init(editorViewModel: ImageEditorViewModel) {
        self.editorViewModel = editorViewModel
        super.init()
        self.subscribers[.editorMode] = editorViewModel.$mode.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.willChangeValue(forKey: #keyPath(selectedModeIndex))
            self?.didChangeValue(forKey: #keyPath(selectedModeIndex))
        }

        self.subscribers[.imageDescription] = editorViewModel.imageContent.$imageDescription.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.willChangeValue(for: \.imageDescription)
            self?.didChangeValue(for: \.imageDescription)
        }
    }

    override var title: String? {
        return NSLocalizedString("Image", comment: "Image editor inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.imageEditor"
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case editorMode
        case imageDescription
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    //MARK: - Properties
    @objc dynamic var imageDescription: String {
        get {
			return self.editorViewModel.imageContent.imageDescription ?? ""
        }
        set {
			self.editorViewModel.imageContent.imageDescription = newValue
        }
    }

    @objc dynamic var selectedModeIndex: Int {
        get {
            return self.editorViewModel.mode.rawValue
        }
        set {
            self.editorViewModel.updateMode(ImageEditorViewModel.Mode(rawValue: newValue) ?? .view)
        }
    }

    //MARK: - Actions
	func rotateLeft() {
		self.editorViewModel.rotateLeft()
	}

	func rotateRight() {
		self.editorViewModel.rotateRight()
	}
}
