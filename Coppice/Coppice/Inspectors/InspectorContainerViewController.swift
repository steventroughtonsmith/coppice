//
//  InspectorContainerViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 11/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class InspectorContainerViewController: NSViewController, SplitViewContainable {
    @objc dynamic let viewModel: InspectorContainerViewModel

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

    @IBOutlet var topConstraint: NSLayoutConstraint!

    override func viewDidAppear() {
        super.viewDidAppear()
        if #available(macOS 11.0, *) {
            self.topConstraint.constant = self.view.safeAreaInsets.top
        }
    }


    private var inspectorObservation: AnyCancellable?
    private func setupObservation() {
        self.inspectorObservation = self.viewModel.$inspectors.sink { [weak self] inspectors in
            self?.inspectorViewControllers = inspectors.compactMap { $0 as? BaseInspectorViewController }
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
                    $0.view.trailingAnchor.constraint(equalTo: self.stackView.trailingAnchor),
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
    func createSplitViewItem() -> NSSplitViewItem {
        let item = NSSplitViewItem(viewController: self)
        item.holdingPriority = NSLayoutConstraint.Priority(260)
        item.canCollapse = true
        return item
    }


    //MARK: - Pro
    @IBOutlet weak var showProInfoButton: RoundButton! {
        didSet {
            self.showProInfoButton.attributedTitle = NSAttributedString(string: "Find Out More…", attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.white.withAlphaComponent(0.75),
            ])
        }
    }

    @IBAction func showProInfo(_ sender: Any) {
        CoppiceSubscriptionManager.shared.openProPage()
    }

    @objc dynamic var showProFeatures: Bool {
        get {
            return UserDefaults.standard.bool(forKey: .showProFeaturesInInspector)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: .showProFeaturesInInspector)
        }
    }

    @IBOutlet weak var proGreenView: CoppiceGreenView! {
        didSet {
            self.proGreenView.shape = .curveBottom
        }
    }
}

extension InspectorContainerViewController: InspectorContainerView {}
