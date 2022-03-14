//
//  ImageEditorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class ImageEditorViewController: NSViewController, NSMenuItemValidation, NSToolbarItemValidation {
    @IBOutlet weak var imageView: NSImageView!
	@IBOutlet var placeholderView: ImageEditorPlaceholderView!

    @objc dynamic let viewModel: ImageEditorViewModel
    init(viewModel: ImageEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "ImageEditorViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    var enabled: Bool = true

    private lazy var imageEditorInspectorViewController: ImageEditorInspectorViewController = {
        return ImageEditorInspectorViewController(viewModel: ImageEditorInspectorViewModel(editorViewModel: self.viewModel))
    }()


	//MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        (self.view as? ColourBackgroundView)?.backgroundColour = NSColor.pageEditorBackground
    }

    override func viewWillAppear() {
        super.viewWillAppear()

		self.subscribers[.mode] = self.viewModel.$mode.sink { [weak self] newMode in
			self?.switchTo(newMode)
		}
    }

	//MARK: - Subscribers
	private enum SubscriberKey {
		case mode
	}

	private var subscribers: [SubscriberKey: AnyCancellable] = [:]

	//MARK: - Mode
	private func switchTo(_ mode: ImageEditorViewModel.Mode) {
		switch mode {
		case .view:
            self.editorModeViewController = ImageEditorViewModeViewController(viewModel: self.viewModel)
		case .crop:
            self.editorModeViewController = ImageEditorCropModeViewController(viewModel: self.viewModel)
        case .hotspot:
            self.editorModeViewController = ImageEditorHotspotModeViewController(viewModel: self.viewModel)
		}
	}

	private var editorModeViewController: (NSViewController & PageContentEditor)? {
		didSet {
			oldValue?.removeFromParent()
			oldValue?.view.removeFromSuperview()

			if let overlayViewController = self.editorModeViewController {
				self.addChild(overlayViewController)
                overlayViewController.view.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(overlayViewController.view)
                if #available(macOS 11.0, *) {
                    NSLayoutConstraint.activate([
                        overlayViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        overlayViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                        overlayViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        overlayViewController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
                    ])
                } else {
                    NSLayoutConstraint.activate([
                        overlayViewController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                        overlayViewController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                        overlayViewController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                        overlayViewController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
                    ])
                }
			}
		}
	}

	//MARK: - Linking
    @IBAction func editLink(_ sender: Any?) {
        //We need an empty implementation just so validation occurs
    }

	//MARK: - Valdiation
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if item.action == #selector(self.editLink(_:)) {
            item.toolTip = NSLocalizedString("Image Pages don't current support links", comment: "Image Page link to page disabled tooltip")
            return false
        }
        return true
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(self.editLink(_:)) {
            menuItem.toolTip = NSLocalizedString("Image Pages don't current support links", comment: "Image Pages link to page disabled tooltip")
            return false
        }
        return true
    }
}


extension ImageEditorViewController: PageContentEditor {
    var inspectors: [Inspector] {
        guard self.enabled else {
            return []
        }
        return [self.imageEditorInspectorViewController]
    }

    func startEditing(at point: CGPoint) {
        self.editorModeViewController?.startEditing(at: point)
    }

    func stopEditing() {
        self.editorModeViewController?.stopEditing()
    }

    func contentEditorForFocusMode() -> (NSViewController & PageContentEditor)? {
        let viewModel = ImageEditorViewModel(imageContent: self.viewModel.imageContent, viewMode: .focus, documentWindowViewModel: self.viewModel.documentWindowViewModel)
        viewModel.updateMode(self.viewModel.mode)
        return ImageEditorViewController(viewModel: viewModel)
    }
}


extension ImageEditorViewController: ImageEditorViewProtocol {
    func switchToCanvasCropMode() {
        self.enterFocusMode()
    }

    func exitCanvasCropMode() {
        self.exitFocusMode()
    }
}
