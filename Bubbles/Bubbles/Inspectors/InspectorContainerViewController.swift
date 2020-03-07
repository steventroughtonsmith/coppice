//
//  InspectorContainerViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 11/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class InspectorContainerViewController: NSViewController, RootViewController {
    let viewModel: InspectorContainerViewModel

    @IBOutlet weak var stackView: NSStackView!
    init(viewModel: InspectorContainerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "InspectorContainerViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupObservation()
    }


    private var inspectorObservation: AnyCancellable?
    private func setupObservation() {
        self.inspectorObservation = self.viewModel.$inspectors.sink { inspectors in
            self.inspectorViewControllers = inspectors.compactMap { $0 as? BaseInspectorViewController }
        }
    }

    var inspectorViewControllers: [BaseInspectorViewController] = [] {
        didSet {
            oldValue.forEach { $0.view.removeFromSuperview() }
            self.children = self.inspectorViewControllers
            var previous: BaseInspectorViewController? = nil
            self.inspectorViewControllers.forEach {
                self.stackView.addArrangedSubview($0.view)
                let constraints = [
                    $0.view.leadingAnchor.constraint(equalTo: self.stackView.leadingAnchor),
                    $0.view.trailingAnchor.constraint(equalTo: self.stackView.trailingAnchor)
                ]
                NSLayoutConstraint.activate(constraints)

                //Do this after the code above so the NIBs are loaded
                previous?.lastKeyView?.nextKeyView = $0.firstKeyView
                previous = $0
            }

            self.view.nextKeyView = self.inspectorViewControllers.first?.firstKeyView
        }
    }


    //MARK: - RootViewController
    lazy var splitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(viewController: self)
        item.holdingPriority = NSLayoutConstraint.Priority(260)
        item.canCollapse = true
        return item
    }()
}

extension InspectorContainerViewController: InspectorContainerView {
}
