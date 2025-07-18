//
//  AppDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore
import M3Subscriptions
import Sparkle


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var newLinkedPageMenuDelegate: NewPageMenuDelegate!
    @IBOutlet weak var updaterController: SPUStandardUpdaterController!

    lazy var documentController = CoppiceDocumentController()

    override init() {
        super.init()
        do {
            try CoppiceSubscriptionManager.initializeManager()
        } catch {
            let alert = NSAlert()
            alert.messageText = "Coppice encountered a problem"
            alert.informativeText = "Coppice was unable to correctly start as it couldn't access vital files. Please check your disk permissions. If the problem persists contact M Cubed Support"
            alert.runModal()
            NSApplication.shared.terminate(self)
        }
        self.setupDefaults()
    }

    private func setupDefaults() {
        UserDefaults.standard.register(defaults: [
            .defaultFontName: Page.fallbackFontName,
            .defaultFontSize: Page.fallbackFontSize,
            .defaultCanvasTheme: Canvas.Theme.auto.rawValue,
            .autoLinkingTextPagesEnabled: true,
            .showWelcomeScreenOnLaunch: true,
            .sidebarSize: SidebarSize.system.rawValue,
            .showProFeaturesInInspector: true,
            .needsLinkUpgrade: false,
        ])
    }


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if DEBUG
        if let mainMenu = NSApplication.shared.mainMenu, let windowMenu = mainMenu.item(withTitle: "Window") {
            let index = mainMenu.index(of: windowMenu) + 1

            let menuItem = mainMenu.insertItem(withTitle: "**DEBUG**", action: nil, keyEquivalent: "", at: index)
            menuItem.submenu = DebugMenuBuilder().buildMenu()
        }
        #endif

        self.newLinkedPageMenuDelegate.action = #selector(TextEditorViewController.createNewLinkedPage(_:))
        self.newLinkedPageMenuDelegate.includeKeyEquivalents = false

        CoppiceSubscriptionManager.shared.delegate = self

        UserDefaults.standard.set(true, forKey: "NSTextViewAvoidLayoutWhileDrawing")
        NSApplication.shared.registerUserInterfaceItemSearchHandler(HelpController.shared)

        self.whatsNewWindow.showIfNeeded()

        //Documents should be restored by the next run loop
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            if (self.documentController.documents.count == 0) && UserDefaults.standard.bool(forKey: .showWelcomeScreenOnLaunch) {
                self.welcomeWindow.showWindow(nil)
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        #if TEST
        if (UserDefaults.standard.bool(forKey: "DisableOpeningWindowAtLaunch")) {
            return false
        }
        #endif
        return !UserDefaults.standard.bool(forKey: .showWelcomeScreenOnLaunch)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard
            UserDefaults.standard.bool(forKey: .showWelcomeScreenOnLaunch),
            (flag == false)
        else {
            return true
        }

        self.welcomeWindow.showWindow(nil)
        return false
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        let coppiceURLs = urls.filter { $0.scheme == GlobalConstants.urlScheme }
        if urls.count == 1, (try? API.V2.Licence(url: urls[0])) != nil {
            self.preferencesWindow.showWindow(self)
            self.preferencesWindow.activate(withLicenceURL: urls[0])
        }


        let documents = CoppiceDocumentController.shared.documents.compactMap { $0 as? Document }

        coppiceURLs.forEach { (url) in
            for document in documents {
                if document.handle(url) {
                    break
                }
            }
        }
    }

    //MARK: - Preferences
    lazy var preferencesWindow: PreferencesWindowController = {
        return PreferencesWindowController(updaterController: self.updaterController)
    }()

    @IBAction func showPreferences(_ sender: Any?) {
        self.preferencesWindow.showWindow(sender)
    }

    @IBAction func showCoppiceProTrial(_ sender: Any?) {
        self.showPreferences(sender)
        self.preferencesWindow.showCoppicePro()
        self.preferencesWindow.coppiceProPreferences.coppiceProViewController.showTrialInfo(sender)
    }


    //MARK: - About
    lazy var aboutWindow: AboutWindowController = {
        return AboutWindowController()
    }()

    @IBAction func showAboutWindow(_ sender: Any?) {
        self.aboutWindow.showWindow(sender)
    }


    //MARK: - Welcome
    lazy var welcomeWindow: WelcomeWindowController = {
        return WelcomeWindowController()
    }()

    @IBAction func showWelcomeWindow(_ sender: Any?) {
        self.welcomeWindow.showWindow(sender)
    }


    //MARK: - Tour
    var currentTourWindow: TourWindowController?
    var tourCloseNotification: NSObjectProtocol?
    @IBAction func showTour(_ sender: Any?) {
        let tourWindow = TourWindowController()
        self.currentTourWindow = tourWindow
        tourWindow.showWindow(sender)
        self.tourCloseNotification = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: tourWindow.window, queue: .main) { [weak self] (notification) in
            self?.currentTourWindow = nil
            self?.tourCloseNotification = nil
        }
    }

    //MARK: - What's New
    var whatsNewWindow = WhatsNewWindowController()
    @IBAction func whatsNewInCoppice(_ sender: Any?) {
        self.whatsNewWindow.showWindow(sender)
    }

    #if DEBUG
    @IBAction func checkSubscription(_ sender: Any?) {
        CoppiceSubscriptionManager.shared.checkSubscription()
    }

    @IBAction func toggleProDisabled(_ sender: NSMenuItem) {
        CoppiceSubscriptionManager.shared.proDisabled.toggle()
        sender.state = (CoppiceSubscriptionManager.shared.proDisabled ? .on : .off)
    }
    #endif

    @IBAction func openSampleDocument(_ sender: Any?) {
        //Close the tour if needed
        self.currentTourWindow?.close()

        guard let sampleDocumentURL = Bundle.main.url(forResource: "Sample Document", withExtension: "coppicedoc") else {
            return
        }

        guard let temporaryDirectory = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(sampleDocumentURL.lastPathComponent) else {
            return
        }

        if (!FileManager.default.fileExists(atPath: temporaryDirectory.path)) {
            try? FileManager.default.copyItem(at: sampleDocumentURL, to: temporaryDirectory)
        }

        self.documentController.openDocument(withContentsOf: temporaryDirectory, display: true) { (document, boolean, error) in
            (document as? Document)?.selectFirstCanvas()
        }
//        guard let document = try? self.documentController.duplicateDocument(withContentsOf: sampleDocumentURL, copying: true, displayName: "Sample Document") else {
//            return
//        }


//        self.documentController.addDocument(document)
//        document.makeWindowControllers()
    }


    //MARK: - Help Menu
    @IBAction func contactSupport(_ sender: Any?) {
        let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "Unknown"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "N/A"
        let bodyValue = "Coppice Version: \(versionString) (\(version))\nOS Version: \(ProcessInfo.processInfo.operatingSystemVersionString)\n\nPlease provide your feedback below:\n"

        let subjectItem = URLQueryItem(name: "subject", value: "[Coppice Feedback]")
        let bodyItem = URLQueryItem(name: "body", value: bodyValue)

        var urlComponents = URLComponents()
        urlComponents.scheme = "mailto"
        urlComponents.path = "support@mcubedsw.com"
        urlComponents.queryItems = [subjectItem, bodyItem]
        guard let url = urlComponents.url else {
            let alert = NSAlert()
            alert.messageText = "Something went wrong"
            alert.informativeText = "Please contact M Cubed Software at support@mcubedsw.com"
            alert.runModal()
            return
        }
        NSWorkspace.shared.open(url)
    }

    @IBAction func openCoppiceBlog(_ sender: Any?) {
        NSWorkspace.shared.open(.blog)
    }

    @IBAction func openMCubedMastodon(_ sender: Any?) {
        NSWorkspace.shared.open(.socials)
    }

    @IBAction func showHelpViewer(_ sender: Any?) {
        HelpController.shared.showHelpViewer()
    }
}


extension AppDelegate: CoppiceSubscriptionManagerDelegate {
    func showCoppicePro(with error: NSError, for subscriptionManager: CoppiceSubscriptionManager) {
        self.preferencesWindow.showWindow(nil)
        self.preferencesWindow.showCoppicePro()

        let alert = NSAlert(error: error)
        if let window = self.preferencesWindow.window {
            alert.beginSheetModal(for: window)
        } else {
            alert.runModal()
        }
    }

    func showInfoAlert(_ infoAlert: InfoAlert, for subscriptionManager: CoppiceSubscriptionManager) {
        NSApplication.shared.enumerateWindows(options: .orderedFrontToBack) { (window, stop) in
            guard let windowController = window.windowController as? DocumentWindowController else {
                return
            }

            windowController.displayInfoAlert(infoAlert)
            stop.pointee = true
        }
    }

    func presentViewController(_ viewController: NSViewController, for subscriptionManager: CoppiceSubscriptionManager) -> Bool {
        self.preferencesWindow.showWindow(nil)
        self.preferencesWindow.showCoppicePro()

        guard let vc = self.preferencesWindow.contentViewController else {
            return false
        }

        vc.presentAsSheet(viewController)
        return true
    }
}

