//
//  CanvasPageViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

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
            self.typedView.selected = self.selected
        }
    }

    var enabled: Bool = false {
        didSet {
            self.viewModel.pageEditor?.enabled = self.enabled
            self.typedView.enabled = self.enabled
        }
    }

    @objc dynamic let viewModel: CanvasPageViewModel
    init(viewModel: CanvasPageViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasPageViewController", bundle: nil)
        viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    private var labelBinding: AnyCancellable!
    override func viewDidLoad() {
        super.viewDidLoad()

        self.typedView.drawsShadow = (self.viewModel.mode == .editing)

        //We need to make sure we stay pinned to the top left when resizing the view
        self.view.autoresizingMask = [.maxXMargin, .maxYMargin]

        if let pageEditor = self.viewModel.pageEditor {
            self.typedView.contentContainer.addSubview(pageEditor.view, withInsets: NSEdgeInsetsZero)
            self.addChild(pageEditor)
        }

        self.labelBinding = self.viewModel.publisher(for: \.title).assign(to: \.title, on: self.typedView.titleView)

        self.typedView.titleView.delegate = self
    }

    deinit {
        self.labelBinding?.cancel()
    }

    func apply(_ layoutPage: LayoutEnginePage) {
        self.view.frame = layoutPage.layoutFrame.rounded()
        self.selected = layoutPage.selected
        self.enabled = layoutPage.enabled
        self.typedView.apply(layoutPage)
    }

    private lazy var canvasPageInspectorViewController: CanvasPageInspectorViewController = {
        return CanvasPageInspectorViewController(viewModel: self.viewModel.canvasPageInspectorViewModel)
    }()

    func flash() {
        let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.transform))
        var transform = CATransform3DIdentity
        transform = CATransform3DTranslate(transform, self.view.bounds.width/2, self.view.bounds.height/2, 0)
        transform = CATransform3DScale(transform, 1.1, 1.1, 1)
        transform = CATransform3DTranslate(transform, -self.view.bounds.width/2, -self.view.bounds.height/2, 0)

        animation.values = [CATransform3DIdentity, transform, CATransform3DIdentity]
        animation.keyTimes = [0, 0.3, 1]
        animation.duration = 0.5
        animation.timingFunctions = [CAMediaTimingFunction(name: .linear), CAMediaTimingFunction(name: .easeOut)]

        self.view.layer?.add(animation, forKey: "flashAnimation")
    }
}

extension CanvasPageViewController: Editor {
    var inspectors: [Inspector] {
        let inspectors = self.viewModel.pageEditor?.inspectors ?? []
        return inspectors + [self.canvasPageInspectorViewController]
    }

    func open(_ link: PageLink) {
        self.parentEditor?.open(link.withSource(self.viewModel.canvasPage.id))
    }
}

extension CanvasPageViewController: CanvasPageTitleViewDelegate {
    func closeClicked(in titleView: CanvasPageTitleView) {
        self.delegate?.close(self)
    }

    func didChangeTitle(to newTitle: String, in titleView: CanvasPageTitleView) {
        self.viewModel.title = newTitle
    }
}
