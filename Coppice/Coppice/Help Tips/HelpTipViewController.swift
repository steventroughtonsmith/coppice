//
//  HelpTipViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import AVKit

class HelpTipViewController: NSViewController {
    struct HelpTip {
        let title: String
        let body: String
        let movieName: String
    }

    @IBOutlet var playerView: AVPlayerView!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var bodyLabel: NSTextField!

    let helpTip: HelpTip
    init(helpTip: HelpTip) {
        self.helpTip = helpTip
        super.init(nibName: "HelpTipView", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var didEndPlayingNotification: NSObjectProtocol?
    override func viewDidLoad() {
        super.viewDidLoad()

        self.titleLabel.stringValue = self.helpTip.title
        self.bodyLabel.stringValue = self.helpTip.body

        guard let movieURL = Bundle.main.url(forResource: self.helpTip.movieName, withExtension: "mp4") else {
            return
        }

        let playerItem = AVPlayerItem(url: movieURL)
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none
        self.playerView.player = player

        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: playerItem, queue: .main) { (notification) in
            playerItem.seek(to: .zero, completionHandler: nil)
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.perform(#selector(play), with: nil, afterDelay: 1)
    }

    @objc dynamic private func play() {
//        self.previewImageView.isHidden = true
        self.playerView.player?.play()
    }
}
