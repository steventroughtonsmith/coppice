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
import M3Subscriptions

class GeneralPreferencesViewController: PreferencesViewController {
    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: "GeneralPreferencesViewController", bundle: nil)
        self.startObservation()
    }

    var activationObservation: AnyCancellable?
    private func startObservation() {
        self.activationObservation = self.subscriptionManager.$activationResponse
            .map { $0?.isActive ?? false }
            .assign(to: \.isProEnabled, on: self)
    }

    override var tabLabel: String {
        return NSLocalizedString("General", comment: "General Preferences Title")
    }

    override var tabImage: NSImage? {
        return NSImage(named: "PrefsGeneral")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSidebarSize()
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

    @objc dynamic var isProEnabled: Bool = false

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(autoLinkingTextPagesEnabled) || key == #keyPath(selectedThemeIndex)) {
            keyPaths.insert(#keyPath(isProEnabled))
        }
        return keyPaths
    }

    @objc dynamic var autoLinkingTextPagesEnabled: Bool {
        get {
            guard self.isProEnabled else {
                return false
            }
            return UserDefaults.standard.bool(forKey: .autoLinkingTextPagesEnabled)
        }
        set {
            guard self.isProEnabled else {
                return
            }
            UserDefaults.standard.set(newValue, forKey: .autoLinkingTextPagesEnabled)
        }
    }

    @objc dynamic var canvasThemes: [String] {
        return Canvas.Theme.allCases.map(\.localizedName)
    }

    @objc dynamic var selectedThemeIndex: Int {
        get {
            guard self.isProEnabled else {
                return 0
            }
            return Canvas.Theme.allCases.firstIndex(of: Canvas.defaultTheme) ?? 0
        }
        set {
            guard self.isProEnabled else {
                return
            }
            let selectedTheme = Canvas.Theme.allCases[safe: newValue] ?? .auto
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: .defaultCanvasTheme)
        }
    }

    //MARK: - Pro Upsell

    @IBAction func showLinkingProUpsell(_ sender: Any) {
        guard let control = sender as? NSView else {
            return
        }
        self.subscriptionManager.showProPopover(for: .textAutoLinking, from: control, preferredEdge: .maxX)
    }

    @IBAction func showThemeProUpsell(_ sender: Any) {
        guard let control = sender as? NSView else {
            return
        }
        self.subscriptionManager.showProPopover(for: .canvasThemes, from: control, preferredEdge: .maxX)
    }

    //MARK: - Sidebar Size
    @IBOutlet var sidebarSizePopup: NSPopUpButton!
    private func setupSidebarSize() {
        self.sidebarSizePopup.removeAllItems()

        SidebarSize.allCases.forEach { (size) in
            self.sidebarSizePopup.addItem(withTitle: size.localizedName)
            self.sidebarSizePopup.lastItem?.representedObject = size.rawValue
        }

        self.sidebarSizePopup.selectItem(at: self.sidebarSizePopup.indexOfItem(withRepresentedObject: self.selectedSidebarSize))
    }

    @objc dynamic var selectedSidebarSize: String {
        get {
            UserDefaults.standard.string(forKey: .sidebarSize) ?? SidebarSize.system.rawValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: .sidebarSize)
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
