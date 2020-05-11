//
//  ColourGridView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 18/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

protocol ColourGridViewDelegate: class {
    func didSelect(_ colour: NSColor, in gridView: ColourGridView)
}

class ColourGridView: NSView {
    weak var delegate: ColourGridViewDelegate?
    let numberOfColumns = 5

    private let colours = [
        NSColor(hexString: "#000000")!, NSColor(hexString: "#545454")!, NSColor(hexString: "#7f7f7f")!, NSColor(hexString: "#a8a8a8")!, NSColor(hexString: "#ffffff")!,
        NSColor(hexString: "#a24432")!, NSColor(hexString: "#a7a72a")!, NSColor(hexString: "#00a000")!, NSColor(hexString: "#005ea5")!, NSColor(hexString: "#b127b0")!,
        NSColor(hexString: "#ff2600")!, NSColor(hexString: "#e8e81d")!, NSColor(hexString: "#37ee37")!, NSColor(hexString: "#0096ff")!, NSColor(hexString: "#ff40ff")!,
        NSColor(hexString: "#ff7e79")!, NSColor(hexString: "#fffc79")!, NSColor(hexString: "#73fa79")!, NSColor(hexString: "#76d6ff")!, NSColor(hexString: "#ff85ff")!,
    ]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setupGrid()
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }


    //MARK: - Setup Views
    private lazy var stackView: NSStackView = {
        let stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.spacing = 2
        return stackView
    }()

    private lazy var button: NSButton = {
        let button = NSButton(title: NSLocalizedString("Show Color Panel…", comment: "Show Color Panel button title"),
                              target: self,
                              action: #selector(showColorPanel(_:)))
        button.translatesAutoresizingMaskIntoConstraints = false
        button.controlSize = .small
        button.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        return button
    }()

    private var buttons = [ColourGridButton]()

    func setupGrid() {
        let stackView = self.stackView

        var currentRowColours = [NSColor]()
        (0..<self.colours.count).forEach {
            currentRowColours.append(self.colours[$0])
            if (currentRowColours.count % self.numberOfColumns) == 0 {
                let rowStackView = self.createRow(for: currentRowColours)
                stackView.addArrangedSubview(rowStackView)
                currentRowColours = []
            }
        }

        if (currentRowColours.count > 0) {
            let rowStackView = self.createRow(for: currentRowColours)
            stackView.addArrangedSubview(rowStackView)
        }

        self.addSubview(stackView)
        self.addSubview(self.button)

        let views = ["stackView": stackView, "button": self.button]
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "|-5-[stackView]-5-|",
                                                                   options: [], metrics: nil, views: views))
        NSLayoutConstraint.activate(NSLayoutConstraint.constraints(withVisualFormat: "V:|-5-[stackView]-5-[button]-5-|",
                                                                   options: .alignAllCenterX, metrics: nil, views: views))

        self.updateSelection()
    }

    private func createRow(for colours: [NSColor]) -> NSStackView {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .top
        stackView.distribution = .equalSpacing
        stackView.spacing = 2

        for colour in colours {
            let colourView = ColourGridButton(colour: colour, target: self, action: #selector(selectColour(_:)))
            self.buttons.append(colourView)
            stackView.addArrangedSubview(colourView)
        }

        return stackView
    }


    //MARK: - Selection
    var selectedColour: NSColor? {
        didSet {
            self.updateSelection()
        }
    }

    private func updateSelection() {
        for button in self.buttons {
            button.selected = (button.colour == self.selectedColour)
        }
    }

    @objc dynamic func selectColour(_ sender: ColourGridButton?) {
        if let colour = sender?.colour {
            self.delegate?.didSelect(colour, in: self)
        }
    }

    //MARK: - Colour Panel
    @IBAction func showColorPanel(_ sender: Any?) {
//        NSColorPanel.shared.setTarget(self)
//        NSColorPanel.shared.setAction(#selector(colourPanelSelected(_:)))
        NSColorPanel.shared.makeKeyAndOrderFront(self)
        if let colour = self.selectedColour {
            NSColorPanel.shared.color = colour
        }
    }

    @IBAction func colourPanelSelected(_ sender: Any?) {
        self.delegate?.didSelect(NSColorPanel.shared.color, in: self)
    }
}
