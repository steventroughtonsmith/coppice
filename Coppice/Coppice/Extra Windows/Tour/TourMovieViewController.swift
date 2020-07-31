//
//  TourLinksViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 27/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

#warning("Disabled AVKit due to bug in Xcode 12.0b3")
import Cocoa
//import AVKit
import CoppiceCore

class TourMovieViewController: TourPanelViewController {

    let tourIdentifier: String
    init(tourIdentifier: String) {
        self.tourIdentifier = tourIdentifier
        let nibName = "\(self.tourIdentifier)View"
        super.init(nibName: nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

//        guard let url = Bundle.main.url(forResource: self.tourIdentifier, withExtension: "mp4") else {
//            return
//        }
//
//        let player = AVPlayer(url: url)
//        self.playerView.player = player
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.perform(#selector(play), with: nil, afterDelay: 1)
    }

    @objc dynamic private func play() {
        self.previewImageView.isHidden = true
//        self.playerView.player?.play()


    }


    @IBOutlet weak var previewImageView: NSImageView!
//    @IBOutlet weak var playerView: AVPlayerView!

}
