//
//  HelpTopicViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import WebKit

protocol HelpTopicViewControllerDelegate: AnyObject {
    func openTopic(withIdentifier identifier: String, from helpTopicViewController: HelpTopicViewController)
}


class HelpTopicViewController: NSViewController {
    weak var delegate: HelpTopicViewControllerDelegate?

    var topic: HelpBook.Topic? {
        didSet {
            self.reloadData()
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.reloadData()
        self.webView.wantsLayer = true
        self.webView.navigationDelegate = self
    }


    @IBAction func toggleFavourite(_ sender: Any?) {}

    let htmlGenerator = TopicHTMLGenerator()

    @IBOutlet var webView: WKWebView!
    private func reloadData() {
        guard
            self.isViewLoaded,
            let topic = self.topic,
            let content = self.htmlGenerator.generateHTML(for: topic)
        else {
            return
        }
        self.webView.loadHTMLString(content, baseURL: topic.helpBook?.url.appendingPathComponent(topic.id))
    }

    private func generateHTML(for topic: HelpBook.Topic) -> String? {
        let content = topic.helpBook?.content(for: topic) ?? "<p>Topic not found</p>"

        let rootHTML = """
<html>
<head>
    <meta charset="utf-8">
    <title>\(topic.title)</title>
    <link rel="stylesheet" href="../_resources/stylesheet.css">
</head>
<body>
\(content)
</body>
</html>
"""
        return rootHTML
    }
}


extension HelpTopicViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        if (navigationAction.navigationType == .other) && (url.scheme == "file") {
            decisionHandler(.allow)
            return
        }

        if (navigationAction.navigationType == .linkActivated) {
            if (url.scheme == "coppice-help") {
                if let identifier = url.host {
                    self.delegate?.openTopic(withIdentifier: identifier, from: self)
                }
            } else {
                NSWorkspace.shared.open(url)
            }
        }

        decisionHandler(.cancel)
    }
}
