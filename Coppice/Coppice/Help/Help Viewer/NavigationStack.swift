//
//  NavigationStack.swift
//  Coppice
//
//  Created by Martin Pilkington on 23/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class NavigationStack: NSObject {
    enum NavigationItem: Equatable {
        case home
        case topic(HelpBook.Topic)
        case search(String)
    }

    @Published var currentNavigationItem: NavigationItem?

    private var navigationStack: [NavigationItem] = []
    private var currentIndex: Int = -1 {
        didSet {
            guard
                (self.navigationStack.count > 0),
                (self.currentIndex >= 0),
                (self.currentIndex < self.navigationStack.count)
            else {
                self.currentNavigationItem = nil
                return
            }
            self.currentNavigationItem = self.navigationStack[self.currentIndex]
        }
    }

    func navigate(to item: NavigationItem) {
        guard item != self.currentNavigationItem else {
            return
        }

        if self.currentIndex != (self.navigationStack.count - 1) {
            self.navigationStack = Array(self.navigationStack[0...self.currentIndex])
        }
        self.navigationStack.append(item)
        self.currentIndex = self.navigationStack.count - 1
    }

    @IBAction func back(_ sender: Any?) {
        self.currentIndex = max(self.currentIndex - 1, 0)
    }

    @IBAction func forward(_ sender: Any?) {
        self.currentIndex = min(self.currentIndex + 1, self.navigationStack.count - 1)
    }
}

extension NavigationStack: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        if (item.action == #selector(back(_:))) {
            return self.currentIndex > 0
        }
        if (item.action == #selector(forward(_:))) {
            return self.currentIndex < (self.navigationStack.count - 1)
        }
        return true
    }
}
