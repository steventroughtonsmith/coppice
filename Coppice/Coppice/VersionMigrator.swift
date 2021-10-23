//
//  VersionMigrator.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/10/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Foundation

class VersionMigrator {
    static let shared = VersionMigrator()

    private var migrations: [Migration] = []

    func migrate() {
        for migration in self.migrations where (migration.hasRun == false) {
            migration.performMigration()
        }
    }
}

protocol Migration {
    var identifier: String { get }
    func performMigration()
}

extension Migration {
    var hasRun: Bool {
        guard let runMigrations = UserDefaults.standard.array(forKey: .runMigrations) as? [String] else {
            return false
        }
        return runMigrations.contains(self.identifier)
    }

    var isNewInstall: Bool {
        return UserDefaults.standard.bool(forKey: "SUHasLaunchedBefore") == false
    }
}


//2021.2
struct LinkControlUpgradeMigration: Migration {
    let identifier = "LinkControlUpgrade"

    func performMigration() {
        guard
            self.hasRun == false,
            self.isNewInstall == false
        else {
            return
        }

        UserDefaults.standard.set(true, forKey: .needsLinkUpgrade)
    }
}
