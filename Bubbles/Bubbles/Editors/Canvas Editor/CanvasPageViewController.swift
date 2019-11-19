//
//  CanvasPageViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol CanvasPageViewControllerDelegate: class {
    func close(_ page: CanvasPageViewController)
}

class CanvasPageViewController: NSViewController, CanvasPageView {
    weak var delegate: CanvasPageViewControllerDelegate?


    @IBOutlet weak var contentContainer: NSView!
    var uuid: UUID {
        return self.viewModel.canvasPage.id.uuid
    }

    var typedView: CanvasElementView {
        get { self.view as! CanvasElementView }
        set { self.view = newValue }
    }

    var selected: Bool = false {
        didSet {
            self.updateBorder()
        }
    }

    let viewModel: CanvasPageViewModel
    init(viewModel: CanvasPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasPageViewController", bundle: nil)
        viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBAction func close(_ sender: Any) {
        self.delegate?.close(self)
    }

    private func updateBorder() {
        let colour = self.selected ? NSColor.selectedControlColor : NSColor(named: "PageViewBorder")!
        let size: CGFloat = self.selected ? 2 : 1
        self.typedView.boxView.borderColor = colour
        self.typedView.boxView.borderWidth = size
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        //We need to make sure we stay pinned to the top left when resizing the view
        self.view.autoresizingMask = [.maxXMargin, .maxYMargin]

        self.typedView.titleLabel.stringValue = self.viewModel.title

        if let pageEditor = self.viewModel.pageEditor {
            self.typedView.contentContainer.addSubview(pageEditor.view, withInsets: NSEdgeInsetsZero)
            self.addChild(pageEditor)
        }
    }

    func apply(_ layoutPage: LayoutEnginePage) {
        self.view.frame = layoutPage.layoutFrame.rounded()
        self.selected = layoutPage.selected
        self.typedView.apply(layoutPage)
    }

    private lazy var canvasPageInspectorViewController: CanvasPageInspectorViewController = {
        return CanvasPageInspectorViewController(viewModel: self.viewModel.canvasPageInspectorViewModel)
    }()
}

extension CanvasPageViewController: Editor {
    var inspectors: [Inspector] {
        let inspectors = self.viewModel.pageEditor?.inspectors ?? []
        return inspectors + [self.canvasPageInspectorViewController]
    }
}
