//
//  SidebarViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

protocol SidebarView: AnyObject {
    func displaySourceList()
    func displaySearchResults(forSearchString searchString: String)
}

class SidebarViewModel: ViewModel {
    weak var view: SidebarView?

    private var searchStringObserver: AnyCancellable?
    override func setup() {
        self.searchStringObserver = self.documentWindowViewModel.publisher(for: \.searchString).sink { [weak self] _ in
            self?.updateSidebar()
        }
    }

    deinit {
        self.searchStringObserver?.cancel()
    }

    func updateSidebar() {
        guard let searchString = self.documentWindowViewModel.searchString else {
            self.view?.displaySourceList()
            return
        }
        self.view?.displaySearchResults(forSearchString: searchString)
    }
}
