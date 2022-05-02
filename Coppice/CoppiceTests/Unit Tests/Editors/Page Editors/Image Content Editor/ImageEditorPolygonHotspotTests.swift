//
//  ImageEditorPolygonHotspotTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 19/03/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import XCTest

@testable import Coppice
import CoppiceCore

class ImageEditorPolygonHotspotTests: XCTestCase {
    var layoutEngine: ImageEditorHotspotLayoutEngine!
    override func setUpWithError() throws {
        try super.setUpWithError()

        self.layoutEngine = ImageEditorHotspotLayoutEngine()
        self.layoutEngine.isEditable = true
    }

    //MARK: - Helpers
    private func createHotspot(points: [CGPoint]? = nil, mode: ImageEditorHotspotMode = .complete) -> ImageEditorPolygonHotspot {
        let defaultPoints = [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ]
        let hotspot = ImageEditorPolygonHotspot(points: points ?? defaultPoints, mode: mode, imageSize: CGSize(width: 200, height: 200))
        hotspot.layoutEngine = self.layoutEngine
        return hotspot
    }


    //MARK: - hitTest(at:)
    func test_hitTest_returnsTrueIfPointInsidePolygonAndNotEditable() {
        self.layoutEngine.isEditable = false
        let hotspot = self.createHotspot()
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 90, y: 90)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 80, y: 140)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 80, y: 50)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 45, y: 80)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 150, y: 95)))
    }

    func test_hitTest_returnsFalseIfPointOutsidePolygonAndNotEditable() throws {
        self.layoutEngine.isEditable = false
        let hotspot = self.createHotspot()
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 110, y: 102)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 80, y: 152)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 80, y: 37)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 37, y: 80)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 162, y: 100)))
    }

    func test_hitTest_returnsTrueIfPointInsidePolygonOrEditingHandlesAndEditable() throws {
        let hotspot = self.createHotspot()
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 90, y: 90)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 80, y: 140)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 80, y: 50)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 45, y: 80)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 150, y: 95)))

        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 102, y: 102)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 80, y: 152)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 80, y: 37)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 37, y: 80)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 162, y: 100)))
    }

    func test_hitTest_returnsFalseIfPointOutsidePolygonAndEditingHandlesAndEditable() throws {
        let hotspot = self.createHotspot()
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 110, y: 110)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 80, y: 160)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 80, y: 30)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 30, y: 80)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 170, y: 100)))
    }

    //MARK: - editingHandleRects(forScale:)
    func test_editingHandleRects_returnsEmptyArrayIfNotEditable() throws {
        self.layoutEngine.isEditable = false
        let hotspot = self.createHotspot()
        XCTAssertEqual(hotspot.editingHandleRects(forScale: 1), [])
    }

    func test_editingHandleRects_returnsEmptyArrayIfModeIsCreating() throws {
        let hotspot = self.createHotspot(mode: .creating)
        let editingHandleRects = hotspot.editingHandleRects(forScale: 1)
        let handleSize = CGSize(width: hotspot.resizeHandleSize, height: hotspot.resizeHandleSize)
        XCTAssertEqual(editingHandleRects, [
            CGRect(origin: CGPoint(x: 95, y: 95), size: handleSize),
            CGRect(origin: CGPoint(x: 155, y: 95), size: handleSize),
            CGRect(origin: CGPoint(x: 75, y: 35), size: handleSize),
            CGRect(origin: CGPoint(x: 35, y: 75), size: handleSize),
            CGRect(origin: CGPoint(x: 75, y: 145), size: handleSize),
        ])
    }

    func test_editingHandleRects_returnsRectForEachPointInPolygonIfModeIsComplete() throws {
        let hotspot = self.createHotspot()
        let editingHandleRects = hotspot.editingHandleRects(forScale: 1)
        let handleSize = CGSize(width: hotspot.resizeHandleSize, height: hotspot.resizeHandleSize)
        XCTAssertEqual(editingHandleRects, [
            CGRect(origin: CGPoint(x: 95, y: 95), size: handleSize),
            CGRect(origin: CGPoint(x: 155, y: 95), size: handleSize),
            CGRect(origin: CGPoint(x: 75, y: 35), size: handleSize),
            CGRect(origin: CGPoint(x: 35, y: 75), size: handleSize),
            CGRect(origin: CGPoint(x: 75, y: 145), size: handleSize),
        ])
    }

    //MARK: - .imageHotspot
    func test_imageHotspot_returnsCorrectHotspotIfNotEditable() throws {
        self.layoutEngine.isEditable = false
        let hotspot = self.createHotspot()
        hotspot.url = URL(string: "https://www.coppiceapp.com")

        let imageHotspot = hotspot.imageHotspot
        XCTAssertEqual(imageHotspot?.kind, .polygon)
        XCTAssertEqual(imageHotspot?.link, URL(string: "https://www.coppiceapp.com"))
        XCTAssertEqual(imageHotspot?.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ])
    }

    func test_imageHotspot_returnsCorrectHotspotIfEditableAndModeIsComplete() throws {
        let hotspot = self.createHotspot()
        hotspot.url = URL(string: "https://www.mcubedsw.com")

        let imageHotspot = hotspot.imageHotspot
        XCTAssertEqual(imageHotspot?.kind, .polygon)
        XCTAssertEqual(imageHotspot?.link, URL(string: "https://www.mcubedsw.com"))
        XCTAssertEqual(imageHotspot?.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ])
    }

    func test_imageHotspot_returnsNilIfEditableButModeIsCreating() throws {
        let hotspot = self.createHotspot(mode: .creating)
        XCTAssertNil(hotspot.imageHotspot)
    }

    //MARK: - Events

    //MARK: - Editing point
    func test_editPoint_draggingPointToLeftMovesToLeft() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 100, y: 100), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 90, y: 100), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 90, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ])
    }

    func test_editPoint_draggingPointToLeftDoesntGoBeyondImageBounds() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 100, y: 100), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: -20, y: 100), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 0, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ])
    }

    func test_editPoint_draggingPointToRightMovesToRight() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 80, y: 40), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 120, y: 40), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 120, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ])
    }

    func test_editPoint_draggingPointToRightDoesntGoBeyondImageBounds() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 80, y: 40), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 250, y: 40), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 199, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ])
    }

    func test_editPoint_draggingPointUpMovesUp() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 160, y: 100), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 160, y: 90), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 90),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ])
    }

    func test_editPoint_draggingPointUpDoesntGoBeyondImageBounds() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 160, y: 100), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 160, y: -20), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 0),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ])
    }

    func test_editPoint_draggingPointDownMovesDown() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 80, y: 150), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 80, y: 170), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 170),
        ])
    }

    func test_editPoint_draggingPointDownDoesntGoBeyondImageBounds() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 80, y: 150), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 80, y: 250), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 199),
        ])
    }

    //MARK: - Creating
    func test_createHotspot_addsPointOnMouseDown() throws {
        let hotspot = ImageEditorPolygonHotspot(points: [], mode: .creating, imageSize: CGSize(width: 200, height: 200))
        hotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [CGPoint(x: 30, y: 40)])
    }

    func test_createHotspot_modifiesPointOnDragAndMouseUp() throws {
        let hotspot = ImageEditorPolygonHotspot(points: [], mode: .creating, imageSize: CGSize(width: 200, height: 200))
        hotspot.layoutEngine = self.layoutEngine
        hotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [CGPoint(x: 30, y: 40)])

        hotspot.draggedEvent(at: CGPoint(x: 40, y: 50), modifiers: [], eventCount: 1)
        XCTAssertEqual(hotspot.points, [CGPoint(x: 40, y: 50)])
    }

    func test_createHotspot_clickingOnFirstPointCompletes() throws {
        let hotspot = ImageEditorPolygonHotspot(points: [], mode: .creating, imageSize: CGSize(width: 200, height: 200))
        hotspot.layoutEngine = self.layoutEngine
        hotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)
        XCTAssertFalse(hotspot.upEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1))
        XCTAssertEqual(hotspot.mode, .creating)

        hotspot.downEvent(at: CGPoint(x: 130, y: 140), modifiers: [], eventCount: 1)
        XCTAssertFalse(hotspot.upEvent(at: CGPoint(x: 130, y: 140), modifiers: [], eventCount: 1))
        XCTAssertEqual(hotspot.mode, .creating)

        hotspot.downEvent(at: CGPoint(x: 30, y: 140), modifiers: [], eventCount: 1)
        XCTAssertFalse(hotspot.upEvent(at: CGPoint(x: 30, y: 140), modifiers: [], eventCount: 1))
        XCTAssertEqual(hotspot.mode, .creating)

        hotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)
		XCTAssertTrue(hotspot.upEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1))

        XCTAssertEqual(hotspot.points, [CGPoint(x: 30, y: 40), CGPoint(x: 130, y: 140), CGPoint(x: 30, y: 140)])
        XCTAssertEqual(hotspot.mode, .complete)
    }

    func test_createHotspot_doubleClickingPointCompletes() throws {
        let hotspot = ImageEditorPolygonHotspot(points: [], mode: .creating, imageSize: CGSize(width: 200, height: 200))
        hotspot.layoutEngine = self.layoutEngine
        hotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)
        XCTAssertFalse(hotspot.upEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1))

        hotspot.downEvent(at: CGPoint(x: 130, y: 140), modifiers: [], eventCount: 1)
        XCTAssertFalse(hotspot.upEvent(at: CGPoint(x: 130, y: 140), modifiers: [], eventCount: 1))

        hotspot.downEvent(at: CGPoint(x: 30, y: 140), modifiers: [], eventCount: 1)
        XCTAssertFalse(hotspot.upEvent(at: CGPoint(x: 30, y: 140), modifiers: [], eventCount: 1))

        hotspot.downEvent(at: CGPoint(x: 30, y: 140), modifiers: [], eventCount: 2)
        XCTAssertTrue(hotspot.upEvent(at: CGPoint(x: 30, y: 140), modifiers: [], eventCount: 2))

        XCTAssertEqual(hotspot.points, [CGPoint(x: 30, y: 40), CGPoint(x: 130, y: 140), CGPoint(x: 30, y: 140)])
        XCTAssertEqual(hotspot.mode, .complete)
    }

    func test_createHotspot_doesntAllowDraggingBeyondLeft() throws {
        let hotspot = ImageEditorPolygonHotspot(points: [], mode: .creating, imageSize: CGSize(width: 200, height: 200))
        hotspot.layoutEngine = self.layoutEngine
        hotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [CGPoint(x: 30, y: 40)])

        hotspot.draggedEvent(at: CGPoint(x: -20, y: 50), modifiers: [], eventCount: 1)
        XCTAssertEqual(hotspot.points, [CGPoint(x: 0, y: 50)])
    }

    func test_createHotspot_doesntAllowDraggingBeyondRight() throws {
        let hotspot = ImageEditorPolygonHotspot(points: [], mode: .creating, imageSize: CGSize(width: 200, height: 200))
        hotspot.layoutEngine = self.layoutEngine
        hotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [CGPoint(x: 30, y: 40)])

        hotspot.draggedEvent(at: CGPoint(x: 240, y: 50), modifiers: [], eventCount: 1)
        XCTAssertEqual(hotspot.points, [CGPoint(x: 199, y: 50)])
    }

    func test_createHotspot_doesntAllowDraggingBeyondTop() throws {
        let hotspot = ImageEditorPolygonHotspot(points: [], mode: .creating, imageSize: CGSize(width: 200, height: 200))
        hotspot.layoutEngine = self.layoutEngine
        hotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [CGPoint(x: 30, y: 40)])

        hotspot.draggedEvent(at: CGPoint(x: 40, y: -50), modifiers: [], eventCount: 1)
        XCTAssertEqual(hotspot.points, [CGPoint(x: 40, y: 0)])
    }

    func test_createHotspot_doesntAllowDraggingBeyondBottom() throws {
        let hotspot = ImageEditorPolygonHotspot(points: [], mode: .creating, imageSize: CGSize(width: 200, height: 200))
        hotspot.layoutEngine = self.layoutEngine
        hotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [CGPoint(x: 30, y: 40)])

        hotspot.draggedEvent(at: CGPoint(x: 40, y: 250), modifiers: [], eventCount: 1)
        XCTAssertEqual(hotspot.points, [CGPoint(x: 40, y: 199)])
    }


    //MARK: - Moving
    func test_moving_draggingInsideHotspotPathButNotInEditingHandleRectMovesHotspot() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 75, y: 75), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 90, y: 90),
            CGPoint(x: 150, y: 90),
            CGPoint(x: 70, y: 30),
            CGPoint(x: 30, y: 70),
            CGPoint(x: 70, y: 140),
        ])
    }

    func test_moving_doesntMoveBeyondLeftOfImageBound() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: -45, y: 85), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 60, y: 100),
            CGPoint(x: 120, y: 100),
            CGPoint(x: 40, y: 40),
            CGPoint(x: 0, y: 80),
            CGPoint(x: 40, y: 150),
        ])
    }

    func test_moving_doesntMoveBeyondTopOfImageBound() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 85, y: -45), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 60),
            CGPoint(x: 160, y: 60),
            CGPoint(x: 80, y: 0),
            CGPoint(x: 40, y: 40),
            CGPoint(x: 80, y: 110),
        ])
    }

    func test_moving_doesntMoveBeyondRightOfImageBound() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 250, y: 85), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 140, y: 100),
            CGPoint(x: 200, y: 100),
            CGPoint(x: 120, y: 40),
            CGPoint(x: 80, y: 80),
            CGPoint(x: 120, y: 150),
        ])
    }

    func test_moving_doesntMoveBeyondBottomOfImageBound() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 85, y: 155), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 150),
            CGPoint(x: 160, y: 150),
            CGPoint(x: 80, y: 90),
            CGPoint(x: 40, y: 130),
            CGPoint(x: 80, y: 200),
        ])
    }

    func test_moving_doesntMoveIfNotEditable() throws {
        self.layoutEngine.isEditable = false
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 75, y: 75), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
        ])
    }

    func test_moving_doesntMoveIfModeIsCreating() throws {
        let hotspot = self.createHotspot(mode: .creating)
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        hotspot.draggedEvent(at: CGPoint(x: 75, y: 75), modifiers: [], eventCount: 1)

        XCTAssertEqual(hotspot.points, [
            CGPoint(x: 100, y: 100),
            CGPoint(x: 160, y: 100),
            CGPoint(x: 80, y: 40),
            CGPoint(x: 40, y: 80),
            CGPoint(x: 80, y: 150),
            CGPoint(x: 75, y: 75), //It should add this point instead
        ])
    }


    //MARK: - Selecting
    func test_selecting_clickingWithoutDraggingSetsIsSelectedToTrue() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        XCTAssertTrue(hotspot.upEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1))

        XCTAssertTrue(hotspot.isSelected)
    }

    func test_selecting_holdingShiftWhileClickingSetsSelectedToTrueIfFalse() throws {
        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: .shift, eventCount: 1)
        XCTAssertTrue(hotspot.upEvent(at: CGPoint(x: 85, y: 85), modifiers: .shift, eventCount: 1))

        XCTAssertTrue(hotspot.isSelected)
    }

    func test_selecting_holdingShiftWhilcClickingSetsSelectedToFalseIfTrue() throws {
        let hotspot = self.createHotspot()
        hotspot.isSelected = true
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: .shift, eventCount: 1)
        XCTAssertTrue(hotspot.upEvent(at: CGPoint(x: 85, y: 85), modifiers: .shift, eventCount: 1))

        XCTAssertFalse(hotspot.isSelected)
    }

    func test_selecting_clickingWithNoShiftModifierTellsLayoutEngineToDeselectOtherHotspots() throws {
        let mockLayoutEngine = MockImageEditorHotspotLayoutEngine()
        mockLayoutEngine.isEditable = true

        let hotspot = self.createHotspot()
        hotspot.layoutEngine = mockLayoutEngine
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        XCTAssertTrue(hotspot.upEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1))

        XCTAssertTrue(mockLayoutEngine.deselectAllMock.wasCalled)
    }

    func test_selecting_hodlingShiftWhileClickingDoesNotTellLayoutEngineToDeselectOtherHotspots() throws {
        let mockLayoutEngine = MockImageEditorHotspotLayoutEngine()
        mockLayoutEngine.isEditable = true

        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: .shift, eventCount: 1)
        XCTAssertTrue(hotspot.upEvent(at: CGPoint(x: 85, y: 85), modifiers: .shift, eventCount: 1))

        XCTAssertFalse(mockLayoutEngine.deselectAllMock.wasCalled)
    }

    func test_selecting_doesNotSelectIfClickedWithNoModifiersWhileNotEditable() throws {
        self.layoutEngine.isEditable = false

        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        XCTAssertTrue(hotspot.upEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1))

        XCTAssertFalse(hotspot.isSelected)
    }

    func test_selecting_selectsIfClickedWithOptionModifierWhileNotEditable() throws {
        self.layoutEngine.isEditable = false

        let hotspot = self.createHotspot()
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: .option, eventCount: 1)
        XCTAssertTrue(hotspot.upEvent(at: CGPoint(x: 85, y: 85), modifiers: .option, eventCount: 1))

        XCTAssertTrue(hotspot.isSelected)
    }

    func test_selecting_doesNotSelectInCreateMode() throws {
        let hotspot = self.createHotspot(mode: .creating)
        hotspot.downEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1)
        XCTAssertFalse(hotspot.upEvent(at: CGPoint(x: 85, y: 85), modifiers: [], eventCount: 1))

        XCTAssertFalse(hotspot.isSelected)
    }
}
