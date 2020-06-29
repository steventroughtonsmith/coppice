//
//  BaseInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class BaseInspectorViewController: NSViewController, Inspector {
    @IBOutlet weak var titleContainer: NSView!
    @IBOutlet weak var rowContainer: NSStackView!
    @IBOutlet weak var contentContainer: NSView!

    @objc dynamic let viewModel: BaseInspectorViewModel
    init(viewModel: BaseInspectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "BaseInspectorViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        self.updateTrackingArea()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadContentView()
        self.setupAccessibility()
    }

    var ranking: InspectorRanking { return InspectorRanking(rawValue: 0)! }


    @IBOutlet var firstKeyView: NSView?
    @IBOutlet var lastKeyView: NSView?


    //MARK: - Row management
    var contentViewNibName: NSNib.Name? {
        return nil
    }

    private func loadContentView() {
        guard let nibName = self.contentViewNibName,
              let nib = NSNib(nibNamed: nibName, bundle: nil) else
        {
            return
        }

        var topLevelObjects: NSArray? = nil
        nib.instantiate(withOwner: self, topLevelObjects: &topLevelObjects)

        guard let contentView = topLevelObjects?.first(where: { $0 is NSView}) as? NSView else {
            return
        }
        self.contentContainer.addSubview(contentView, withInsets: NSEdgeInsets(top: 0, left: 0, bottom: 20, right: 0))
    }


    //MARK: - Collapse Button Visibility
    @objc dynamic private var mouseIsOverTitle = false
    @objc dynamic var showCollapseButton: Bool {
        return self.mouseIsOverTitle || self.viewModel.collapsed
    }


    //MARK: - Mouse Hovering
    private var trackingArea: NSTrackingArea?
    private func updateTrackingArea() {
        if let trackingArea = self.trackingArea {
            self.titleContainer.removeTrackingArea(trackingArea)
        }
        self.trackingArea = NSTrackingArea(rect: self.titleContainer.bounds, options: [.mouseEnteredAndExited, .activeInKeyWindow], owner: self, userInfo: nil)
        self.titleContainer.addTrackingArea(self.trackingArea!)
    }

    override func mouseEntered(with event: NSEvent) {
        self.mouseIsOverTitle = true
    }

    override func mouseExited(with event: NSEvent) {
        self.mouseIsOverTitle = false
    }

    @IBAction func updateHidden(_ sender: NSButton) {
        //Collapsed state set via bindings
        NSView.animate(withDuration: 0.3) {
            self.view.superview?.layoutSubtreeIfNeeded()
            self.contentContainer.alphaValue = (self.viewModel.collapsed ? 0 : 1)
        }
    }


    //MARK: - Key Paths
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == "showCollapseButton") {
            keyPaths.insert("mouseIsOverTitle")
            keyPaths.insert("viewModel.collapsed")
        }
        return keyPaths
    }


    //MARK: - Accessibility
    func setupAccessibility() {
        guard let contentContainer = self.contentContainer else {
            return
        }
        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(self.viewModel.title)
        self.view.setAccessibilityChildren(contentContainer.accessibilityChildren())
    }
}
