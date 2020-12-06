//
//  ColourGridView.swift
//  Coppice
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

    struct ColourOption {
        let hex: String
        let localizedName: String

        var colour: NSColor {
            return NSColor(hexString: self.hex)!
        }
    }

    private let colours = [
        //First Row (Greys)
        ColourOption(hex: "#000000", localizedName: NSLocalizedString("Black", comment: "Black colour name")),
        ColourOption(hex: "#545454", localizedName: NSLocalizedString("Dark Grey", comment: "Dark Grey colour name")),
        ColourOption(hex: "#7f7f7f", localizedName: NSLocalizedString("Grey", comment: "Grey colour name")),
        ColourOption(hex: "#a8a8a8", localizedName: NSLocalizedString("Pale Grey", comment: "Pale Grey colour name")),
        ColourOption(hex: "#ffffff", localizedName: NSLocalizedString("White", comment: "White colour name")),
		//Second row (Dark)
        ColourOption(hex: "#a24432", localizedName: NSLocalizedString("Dark Red", comment: "Dark Red colour name")),
        ColourOption(hex: "#a7a72a", localizedName: NSLocalizedString("Dark Yellow", comment: "Dark Yellow colour name")),
        ColourOption(hex: "#00a000", localizedName: NSLocalizedString("Dark Green", comment: "Dark Green colour name")),
        ColourOption(hex: "#005ea5", localizedName: NSLocalizedString("Dark Blue", comment: "Dark Blue colour name")),
        ColourOption(hex: "#b127b0", localizedName: NSLocalizedString("Dark Purple", comment: "Dark Purple colour name")),
		//Second row (Standard)
        ColourOption(hex: "#ff2600", localizedName: NSLocalizedString("Red", comment: "Red colour name")),
        ColourOption(hex: "#e8e81d", localizedName: NSLocalizedString("Yellow", comment: "Yellow colour name")),
        ColourOption(hex: "#37ee37", localizedName: NSLocalizedString("Green", comment: "Green colour name")),
        ColourOption(hex: "#0096ff", localizedName: NSLocalizedString("Blue", comment: "Blue colour name")),
        ColourOption(hex: "#ff40ff", localizedName: NSLocalizedString("Purple", comment: "Purple colour name")),
		//Second row (Pale)
        ColourOption(hex: "#ff7e79", localizedName: NSLocalizedString("Pale Red", comment: "Pale Red colour name")),
        ColourOption(hex: "#fffc79", localizedName: NSLocalizedString("Pale Yellow", comment: "Pale Yellow colour name")),
        ColourOption(hex: "#73fa79", localizedName: NSLocalizedString("Pale Green", comment: "Pale Green colour name")),
        ColourOption(hex: "#76d6ff", localizedName: NSLocalizedString("Pale Blue", comment: "Pale Blue colour name")),
        ColourOption(hex: "#ff85ff", localizedName: NSLocalizedString("Pale Purple", comment: "Pale Purple colour name")),

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

        var currentRowColours = [ColourOption]()
        (0..<self.colours.count).forEach {
            currentRowColours.append(self.colours[$0])
            if (currentRowColours.count % self.numberOfColumns) == 0 {
                let rowStackView = self.createRow(for: currentRowColours, roundEnds: stackView.arrangedSubviews.count == 0)
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

    private func createRow(for colours: [ColourOption], roundEnds: Bool = false) -> NSStackView {
        let stackView = NSStackView()
        stackView.orientation = .horizontal
        stackView.alignment = .top
        stackView.distribution = .equalSpacing
        stackView.spacing = 2

        var rowButtons = [ColourGridButton]()
        for colourOption in colours {
            let colourView = ColourGridButton(colour: colourOption.colour, target: self, action: #selector(selectColour(_:)))
            colourView.setAccessibilityLabel(colourOption.localizedName)
            colourView.toolTip = colourOption.localizedName
            rowButtons.append(colourView)
            stackView.addArrangedSubview(colourView)
        }
        if #available(OSX 10.16, *), roundEnds == true {
            rowButtons.first?.roundedCorner = .topLeft
            rowButtons.last?.roundedCorner = .topRight
        }
        self.buttons.append(contentsOf: rowButtons)

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
