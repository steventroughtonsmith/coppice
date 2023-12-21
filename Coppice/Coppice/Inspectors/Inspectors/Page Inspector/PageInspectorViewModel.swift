//
//  PageInspectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import CoppiceCore
import Foundation
import M3Data

protocol PageInspectorView: AnyObject {}


class PageInspectorViewModel: BaseInspectorViewModel {
    weak var view: PageInspectorView?

    let page: Page
    let modelController: ModelController
    init(page: Page, modelController: ModelController) {
        self.page = page
        self.modelController = modelController
        super.init()

        self.subscribers[.pageTitle] = page.changePublisher(for: \.title)?.notify(self, ofChangeTo: \.pageTitle)
        self.subscribers[.allowsAutoLinking] = page.changePublisher(for: \.allowsAutoLinking)?.notify(self, ofChangeTo: \.allowsAutoLinking)
    }

    override var title: String? {
        return NSLocalizedString("Page Info", comment: "Page inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.page"
    }

    @objc dynamic var pageTitle: String? {
        get {
            let title = self.page.title
            return (title.count > 0) ? title : nil
        }
        set { self.page.title = newValue ?? "" }
    }

    @objc dynamic var allowsAutoLinking: Bool {
        get { self.page.allowsAutoLinking }
        set { self.page.allowsAutoLinking = newValue }
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case pageTitle
        case allowsAutoLinking
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}
