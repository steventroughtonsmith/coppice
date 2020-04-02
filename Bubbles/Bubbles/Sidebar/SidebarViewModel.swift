//
//  SidebarViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 02/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

protocol SidebarView: class {
    func displaySourceList()
    func displaySearchResults(forSearchTerm searchTerm: String)
}

class SidebarViewModel: ViewModel {
    weak var view: SidebarView?

    private var searchTermObserver: AnyCancellable?
    override func setup() {
        self.searchTermObserver = self.documentWindowViewModel.publisher(for: \.searchString).sink { [weak self] _ in
            self?.updateSidebar()
        }
    }

    func updateSidebar() {
        guard let searchString = self.documentWindowViewModel.searchString, searchString.count > 2 else {
            self.view?.displaySourceList()
            return
        }
        self.view?.displaySearchResults(forSearchTerm: searchString)
    }
}
