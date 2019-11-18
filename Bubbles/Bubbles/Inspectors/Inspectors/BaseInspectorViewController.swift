//
//  BaseInspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class BaseInspectorViewController: NSViewController, Inspector {
    @IBOutlet weak var titleContainer: NSView!
    @IBOutlet weak var rowContainer: NSStackView!

    @objc dynamic let viewModel: BaseInspectorViewModel
    init(viewModel: BaseInspectorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "BaseInspectorViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        self.updateTrackingArea()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadDataViews()
    }


    //MARK: - Row management
    func add(_ dataView: InspectorDataView) {
        let row = InspectorRowView.createFromNIB()
        row.dataView = dataView
        self.rowContainer.addArrangedSubview(row)
    }

    var dataViewsNibName: NSNib.Name? {
        return nil
    }

    var dataViewIdentifiers: [NSUserInterfaceItemIdentifier] {
        return []
    }

    private func loadDataViews() {
        guard let nibName = self.dataViewsNibName,
              let nib = NSNib(nibNamed: nibName, bundle: nil) else
        {
            return
        }

        var topLevelObjects: NSArray? = nil
        nib.instantiate(withOwner: self, topLevelObjects: &topLevelObjects)

        guard let objects = topLevelObjects else {
            return
        }
        let dataViews = objects.compactMap { $0 as? InspectorDataView }.compactDictionary { $0.identifier }
        for identifier in self.dataViewIdentifiers {
            if let view = dataViews[identifier] {
            	self.add(view)
            }
        }
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
