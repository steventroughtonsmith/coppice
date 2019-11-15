//
//  InspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class InspectorViewController: NSViewController {
    @IBOutlet weak var titleContainer: NSView!
    @IBOutlet weak var inspectorContainer: NSView!

    convenience init(inspector: Inspector) {
        self.init(viewModel: InspectorViewModel(inspector: inspector))
    }

    @objc dynamic let viewModel: InspectorViewModel
    init(viewModel: InspectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "InspectorViewController", bundle: nil)
        self.viewModel.view = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let inspectorVC = self.viewModel.inspector as? NSViewController else {
            return
        }

        self.addChild(inspectorVC)
        self.inspectorContainer.addSubview(inspectorVC.view, withInsets: NSEdgeInsetsZero)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        self.updateTrackingArea()
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


    //MARK: - Key Paths
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == "showCollapseButton") {
            keyPaths.insert("mouseIsOverTitle")
            keyPaths.insert("viewModel.collapsed")
        }
        return keyPaths
    }
}


extension InspectorViewController: InspectorView {

}
