//
//  GeneralPreferencesViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

class GeneralPreferencesViewController: NSViewController {

    func createTabItem() -> NSTabViewItem {
        let item = NSTabViewItem(viewController: self)
        item.label = NSLocalizedString("General", comment: "General Preferences Title")
        item.image = NSImage(named: "PrefsGeneral")
        return item
    }

    var selectedFont: AnyCancellable?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        self.selectedFont = NSFontManager.shared.publisher(for: \.selectedFont).sink { (font) in
            print("font")
        }
    }

    @objc dynamic var fontString: String {
        let font = Page.defaultFont
        return "\(font.displayName ?? font.fontName), \(font.pointSize)pt"
    }


    @IBAction func showFontPanel(_ sender: Any) {
        NSFontManager.shared.setSelectedFont(Page.defaultFont, isMultiple: false)
        NSFontManager.shared.target = self
        NSFontManager.shared.orderFrontFontPanel(self)
    }

    @objc dynamic var canvasThemes: [String] {
        return Canvas.Theme.allCases.map(\.localizedName)
    }

    @objc dynamic var selectedThemeIndex: Int {
        get {
            return Canvas.Theme.allCases.firstIndex(of: Canvas.defaultTheme) ?? 0
        }
        set {
            let selectedTheme = Canvas.Theme.allCases[safe: newValue] ?? .auto
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: .defaultCanvasTheme)
        }
    }
}


extension GeneralPreferencesViewController: NSFontChanging {
    @objc dynamic func changeFont(_ sender: NSFontManager?) {
        guard let font = sender?.selectedFont else {
            return
        }

        let panelFont = NSFontManager.shared.convert(font)
        self.willChangeValue(for: \.fontString)
        UserDefaults.standard.set(panelFont.fontName, forKey: .defaultFontName)
        UserDefaults.standard.set(panelFont.pointSize, forKey: .defaultFontSize)
        self.didChangeValue(for: \.fontString)
    }
}
