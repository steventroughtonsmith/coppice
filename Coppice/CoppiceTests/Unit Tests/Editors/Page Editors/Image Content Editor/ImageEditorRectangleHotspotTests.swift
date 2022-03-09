//
//  ImageEditorRectangleHotspotTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 25/02/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import XCTest

@testable import Coppice
import CoppiceCore

class ImageEditorRectangleHotspotTests: XCTestCase {
    //MARK: - Helpers
    struct TestDrag {
        var startPoint: (x: CGRect.RectPoint, y: CGRect.RectPoint)
        var deltaX: CGFloat = 0
        var deltaY: CGFloat = 0
        var secondDeltaX: CGFloat = 0
        var secondDeltaY: CGFloat = 0
        var modifiers: LayoutEventModifiers = []
    }

    private func createHotspot(shape: ImageEditorRectangleHotspot.Shape, rect: CGRect = CGRect(x: 50, y: 50, width: 100, height: 100), mode: ImageEditorHotspotMode, drag: TestDrag? = nil) -> ImageEditorRectangleHotspot {
        let hotspot = ImageEditorRectangleHotspot(shape: shape, rect: rect, mode: mode, imageSize: CGSize(width: 200, height: 200))
        if let drag = drag {
            hotspot.downEvent(at: hotspot.rect.point(atX: drag.startPoint.x, y: drag.startPoint.y), modifiers: drag.modifiers, eventCount: 1)

            var dragPoint = hotspot.rect.point(atX: drag.startPoint.x, y: drag.startPoint.y).plus(x: drag.deltaX, y: drag.deltaY)
            if (drag.deltaX != 0) || (drag.deltaY != 0) {
                hotspot.draggedEvent(at: dragPoint, modifiers: drag.modifiers, eventCount: 1)
            }

            if (drag.secondDeltaX != 0) || (drag.secondDeltaY != 0) {
                dragPoint = dragPoint.plus(x: drag.secondDeltaX, y: drag.secondDeltaY)
                hotspot.draggedEvent(at: dragPoint, modifiers: drag.modifiers, eventCount: 1)
            }

            hotspot.upEvent(at: dragPoint, modifiers: drag.modifiers, eventCount: 1)
        }
        return hotspot
    }


    //MARK: - hitTest(at:)
    func test_hitTest_returnsTrueIfPointInRectAndInEditMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .edit)
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 50, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 150, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 50)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 150)))
    }

    func test_hitTest_returnsFalseIfPointOutsideOfRectAndEditingHandlesAndInEditMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .edit)
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 49, y: 100)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 151, y: 100)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 100, y: 49)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 100, y: 151)))

        let handleOffset = hotspot.resizeHandleSize / 2
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 49 - handleOffset, y: 49 - handleOffset)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 151 + handleOffset, y: 49 - handleOffset)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 151 + handleOffset, y: 151 + handleOffset)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 49 - handleOffset, y: 151 + handleOffset)))
    }

    func test_hitTest_returnsTrueIfPointInEditingHandlesAndSelectedInEditMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .edit)
        let handleOffset = hotspot.resizeHandleSize / 2
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 50 - handleOffset, y: 50 - handleOffset)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 150 + handleOffset, y: 50 - handleOffset)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 150 + handleOffset, y: 150 + handleOffset)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 50 - handleOffset, y: 150 + handleOffset)))
    }

    func test_hitTest_returnsTrueIfPointInRectAndInCreateMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .create)
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 50, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 150, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 50)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 150)))
    }

    func test_hitTest_returnsFalseIfPointOutsideOfRectAndInCreateMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .create)
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 49, y: 49)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 49, y: 151)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 151, y: 49)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 151, y: 151)))
    }

    func test_hitTest_returnsTrueIfPointInRectAndShapeIsRectangleInViewMode() throws {
        let hotspot = self.createHotspot(shape: .rectangle, mode: .view)
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 50, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 150, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 50)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 150)))
    }

    func test_hitTest_returnsTrueIfPointInOvalAndShapeIsOvalInViewMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .view)
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 51, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 149, y: 100)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 51)))
        XCTAssertTrue(hotspot.hitTest(at: CGPoint(x: 100, y: 149)))
    }

    func test_hitTest_returnsFalseIfPointOutsideRectAndShapeIsRectangleInViewMode() throws {
        let hotspot = self.createHotspot(shape: .rectangle, mode: .view)
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 49, y: 49)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 49, y: 151)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 151, y: 49)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 151, y: 151)))
    }

    func test_hitTest_returnsFalseIfPointOutsideOvalButInsideRectAndShapeIsOvalInViewMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .view)
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 55, y: 55)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 145, y: 145)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 55, y: 145)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 145, y: 55)))
    }

    func test_hitTest_returnsFalseIfPointOutsideRectAndShapeIsOvalInViewMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .view)
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 49, y: 49)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 49, y: 151)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 151, y: 49)))
        XCTAssertFalse(hotspot.hitTest(at: CGPoint(x: 151, y: 151)))
    }


    //MARK: - .editingBoundsPath
    func test_editingBoundsPath_returnsNilIfInViewMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .view)
        XCTAssertNil(hotspot.editingBoundsPath)
    }

    func test_editingBoundsPath_returnsPathForRectIfShapeIsRectangleAndInEditMode() throws {
        let hotspot = self.createHotspot(shape: .rectangle, mode: .edit)
        XCTAssertEqual(hotspot.editingBoundsPath?.bounds, CGRect(x: 50, y: 50, width: 100, height: 100))
    }

    func test_editingBoundsPath_returnsPathForRectInRectIfShapeIsOvalAndInEditMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .edit)
        XCTAssertEqual(hotspot.editingBoundsPath?.bounds, CGRect(x: 50, y: 50, width: 100, height: 100))
    }

    func test_editingBoundsPath_returnsPathForRectIfShapeIsRectangleAndInCreateMode() throws {
        let hotspot = self.createHotspot(shape: .rectangle, mode: .create)
        XCTAssertEqual(hotspot.editingBoundsPath?.bounds, CGRect(x: 50, y: 50, width: 100, height: 100))
    }

    func test_editingBoundsPath_returnsPathForRectInRectIfShapeIsOvalAndInCreateMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .create)
        XCTAssertEqual(hotspot.editingBoundsPath?.bounds, CGRect(x: 50, y: 50, width: 100, height: 100))
    }


    //MARK: - .editingHandleRects
    func test_editingHandleRects_returnsEmptyArrayIfInViewMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .view)
        XCTAssertEqual(hotspot.editingHandleRects, [])
    }

    func test_editingHandleRects_returnsRectsAt4CornersOfEditingBoundsPathIfShapeIsRectangleAndInEditMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .edit)
        let handleSize = hotspot.resizeHandleSize
        XCTAssertEqual(hotspot.editingHandleRects, [
            CGRect(x: 150 - (handleSize / 2), y: 150 - (handleSize / 2), width: handleSize, height: handleSize),
            CGRect(x: 150 - (handleSize / 2), y: 50 - (handleSize / 2), width: handleSize, height: handleSize),
            CGRect(x: 50 - (handleSize / 2), y: 150 - (handleSize / 2), width: handleSize, height: handleSize),
            CGRect(x: 50 - (handleSize / 2), y: 50 - (handleSize / 2), width: handleSize, height: handleSize),
        ])
    }

    func test_editingHandleRects_returnsRectsAt4CornersOfEditingBoundsPathIfShapeIsOvalAndInEditMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .edit)
        let handleSize = hotspot.resizeHandleSize
        XCTAssertEqual(hotspot.editingHandleRects, [
            CGRect(x: 150 - (handleSize / 2), y: 150 - (handleSize / 2), width: handleSize, height: handleSize),
            CGRect(x: 150 - (handleSize / 2), y: 50 - (handleSize / 2), width: handleSize, height: handleSize),
            CGRect(x: 50 - (handleSize / 2), y: 150 - (handleSize / 2), width: handleSize, height: handleSize),
            CGRect(x: 50 - (handleSize / 2), y: 50 - (handleSize / 2), width: handleSize, height: handleSize),
        ])
    }

    func test_editingHandleRects_returnsEmptyArrayIfInCreateMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .create)
        XCTAssertEqual(hotspot.editingHandleRects, [])
    }


    //MARK: - .imageHotspot
    func test_imageHotspot_returnsCorrectHotspotIfInViewMode() throws {
        let hotspot = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(x: 120, y: 30, width: 100, height: 80), url: URL(string: "https://www.coppiceapp.com"), mode: .view, imageSize: CGSize(width: 200, height: 200))
        let imageHotspot = hotspot.imageHotspot
        XCTAssertEqual(imageHotspot?.kind, .oval)
        XCTAssertEqual(imageHotspot?.link, URL(string: "https://www.coppiceapp.com"))
        XCTAssertEqual(imageHotspot?.points, [CGPoint(x: 120, y: 30), CGPoint(x: 220, y: 30), CGPoint(x: 220, y: 110), CGPoint(x: 120, y: 110)])
    }

    func test_imageHotspot_returnsCorrectHotspotIfInEditMode() throws {
        let hotspot = ImageEditorRectangleHotspot(shape: .rectangle, rect: CGRect(x: 120, y: 30, width: 100, height: 80), url: URL(string: "https://www.mcubedsw.com"), mode: .edit, imageSize: CGSize(width: 200, height: 200))
        let imageHotspot = hotspot.imageHotspot
        XCTAssertEqual(imageHotspot?.kind, .rectangle)
        XCTAssertEqual(imageHotspot?.link, URL(string: "https://www.mcubedsw.com"))
        XCTAssertEqual(imageHotspot?.points, [CGPoint(x: 120, y: 30), CGPoint(x: 220, y: 30), CGPoint(x: 220, y: 110), CGPoint(x: 120, y: 110)])
    }

    func test_imageHotspot_returnsNilIfInCreateMode() throws {
        let hotspot = self.createHotspot(shape: .oval, mode: .create)
        XCTAssertNil(hotspot.imageHotspot)
    }



    //MARK: - EVENTS

    //MARK: - Resizing (Left Points)
    func test_resizingLeft_movingToLeftDecreasesXAndIncreasesWidth() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaX: -10))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 40, y: 50, width: 110, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaX: -10))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 40, y: 50, width: 110, height: 100))
    }

    func test_resizingLeft_movingToRightButNotBeyondRectBoundsIncreasesXAndDecreasesWidth() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaX: 10))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 60, y: 50, width: 90, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaX: 10))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 60, y: 50, width: 90, height: 100))
    }

    func test_resizingLeft_movingToRightBeyondRectBoundsFixesXAtOldRightAndIncreaseWidth() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaX: 120))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 150, y: 50, width: 20, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaX: 120))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 150, y: 50, width: 20, height: 100))
    }

    func test_resizingLeft_movingToLeftWhileBeyondBoundsFixesXAtOldRightAndDecreasesWidth() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaX: 120, secondDeltaX: -10, secondDeltaY: 0))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 150, y: 50, width: 10, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaX: 120, secondDeltaX: -10, secondDeltaY: 0))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 150, y: 50, width: 10, height: 100))
    }

    func test_resizingLeft_doesNotAllowResizingLeftBeyondImageBounds() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaX: -60))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 0, y: 50, width: 150, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaX: -60))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 0, y: 50, width: 150, height: 100))
    }

    func test_resizingLeft_doesNotAllowResizingRightBeyondImageBounds() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaX: 200))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 150, y: 50, width: 50, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaX: 200))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 150, y: 50, width: 50, height: 100))
    }

    func test_resizingLeft_holdingOptionWhileResizingResizesAroundCentreOfOriginalRect() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaX: -20, modifiers: .option))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 30, y: 50, width: 140, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaX: -20, modifiers: .option))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 30, y: 50, width: 140, height: 100))
    }

    func test_resizingLeft_doesNotAllowResizingInViewMode() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .min, y: .min), deltaX: -40))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .min, y: .max), deltaX: 40))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 100))
    }


    //MARK: - Resizing (Right Points)
    func test_resizingRight_movingToRightIncreasesWidth() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaX: 10))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 50, y: 50, width: 110, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaX: 10))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 50, y: 50, width: 110, height: 100))
    }

    func test_resizingRight_movingToLeftButNotBeyondRectBoundsDecreasesWidth() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaX: -10))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 50, y: 50, width: 90, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaX: -10))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 50, y: 50, width: 90, height: 100))
    }

    func test_resizingRight_movingToLeftBeyondRectBoundsFixesMaxXAtOldLeftAndIncreaseWidth() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaX: -120))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 30, y: 50, width: 20, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaX: -120))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 30, y: 50, width: 20, height: 100))
    }

    func test_resizingRight_movingToRightWhileBeyondBoundsFixesMaxXAtOldLeftAndDecreasesWidth() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaX: -120, secondDeltaX: 10))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 40, y: 50, width: 10, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaX: -120, secondDeltaX: 10))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 40, y: 50, width: 10, height: 100))
    }

    func test_resizingRight_doesNotAllowResizingLeftBeyondImageBounds() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaX: -200))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 0, y: 50, width: 50, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaX: -200))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 0, y: 50, width: 50, height: 100))
    }

    func test_resizingRight_doesNotAllowResizingRightBeyondImageBounds() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaX: 60))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 50, y: 50, width: 150, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaX: 60))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 50, y: 50, width: 150, height: 100))
    }

    func test_resizingRight_holdingOptionWhileResizingResizesAroundCentreOfOriginalRect() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaX: 10, modifiers: .option))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 40, y: 50, width: 120, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaX: 10, modifiers: .option))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 40, y: 50, width: 120, height: 100))
    }

    func test_resizingRight_doesNotAllowResizingInViewMode() throws {
        let topHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .max, y: .min), deltaX: 10))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .max, y: .max), deltaX: -10))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 100))
    }


    //MARK: - Resizing (Top Points)
    func test_resizingTop_movingUpDecreasesYAndIncreasesHeight() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaY: -10))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 40, width: 100, height: 110))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaY: -10))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 40, width: 100, height: 110))
    }

    func test_resizingTop_movingDownButNotBeyondRectBoundsIncreasesYAndDecreasesHeight() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaY: 10))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 60, width: 100, height: 90))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaY: 10))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 60, width: 100, height: 90))
    }

    func test_resizingTop_movingDownBeyondRectBoundsFixesYAtOldBottomAndIncreaseHeight() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaY: 120))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 150, width: 100, height: 20))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaY: 120))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 150, width: 100, height: 20))
    }

    func test_resizingTop_movingUpWhileBeyondBoundsFixesYAtOldBottomAndDecreasesHeight() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaY: 120, secondDeltaY: -10))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 150, width: 100, height: 10))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaY: 120, secondDeltaY: -10))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 150, width: 100, height: 10))
    }

    func test_resizingTop_doesNotAllowResizingUpBeyondImageBounds() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaY: -60))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 0, width: 100, height: 150))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaY: -60))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 0, width: 100, height: 150))
    }

    func test_resizingTop_doesNotAllowResizingDownBeyondImageBounds() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaY: 200))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 150, width: 100, height: 50))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaY: 200))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 150, width: 100, height: 50))
    }

    func test_resizingTop_holdingOptionWhileResizingResizesAroundCentreOfOriginalRect() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaY: -10, modifiers: .option))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 40, width: 100, height: 120))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaY: -10, modifiers: .option))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 40, width: 100, height: 120))
    }

    func test_resizingTop_doesNotAllowResizingInViewMode() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .min, y: .min), deltaY: 10))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 100))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .max, y: .min), deltaY: -10))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 100))
    }


    //MARK: - Resizing (Bottom Points)
    func test_resizingBottom_movingDownIncreasesHeight() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaY: 10))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 110))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaY: 10))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 110))
    }

    func test_resizingBottom_movingUpButNotBeyondRectBoundsDecreasesHeight() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaY: -10))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 90))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaY: -10))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 90))
    }

    func test_resizingBottom_movingUpBeyondRectBoundsFixesYAtOldTopAndIncreaseHeight() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaY: -120))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 30, width: 100, height: 20))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaY: -120))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 30, width: 100, height: 20))
    }

    func test_resizingBottom_movingDownWhileBeyondBoundsFixesYAtOldTopAndDecreasesHeight() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaY: -120, secondDeltaY: 10))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 40, width: 100, height: 10))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaY: -120, secondDeltaY: 10))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 40, width: 100, height: 10))
    }

    func test_resizingBottom_doesNotAllowResizingDownBeyondImageBounds() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaY: 60))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 150))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaY: 60))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 150))
    }

    func test_resizingBottom_doesNotAllowResizingUpBeyondImageBounds() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaY: -200))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 0, width: 100, height: 50))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaY: -200))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 0, width: 100, height: 50))
    }

    func test_resizingBottom_holdingOptionWhileResizingResizesAroundCentreOfOriginalRect() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaY: 10, modifiers: .option))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 40, width: 100, height: 120))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaY: 10, modifiers: .option))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 40, width: 100, height: 120))
    }

    func test_resizingBottom_holdingOptionWhileResizingResizesAroundCentreOfOriginalRectIfDraggingAboveCentreLine() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaY: -70, modifiers: .option))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 80, width: 100, height: 40))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .max), deltaY: -70, modifiers: .option))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 80, width: 100, height: 40))
    }

    func test_resizingBottom_doesNotAllowResizingInViewMode() throws {
        let leftHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .min, y: .max), deltaY: 10))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 100))

        let rightHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .max, y: .max), deltaY: -10))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 100))
    }


    //MARK: - Resizing Edge Cases
    func test_resizing_favoursBottomHandleIfHeightTooSmallToNotOverlap() throws {
        let leftHotspot = self.createHotspot(shape: .oval, rect: CGRect(x: 50, y: 50, width: 100, height: 1), mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaY: 10))
        XCTAssertRectEqual(leftHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 11))

        let rightHotspot = self.createHotspot(shape: .oval, rect: CGRect(x: 50, y: 50, width: 100, height: 1), mode: .edit, drag: TestDrag(startPoint: (x: .max, y: .min), deltaY: 10))
        XCTAssertRectEqual(rightHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 11))
    }

    func test_resizing_favoursRightHandleIfWidthTooSmallToNotOverlap() throws {
        let topHotspot = self.createHotspot(shape: .oval, rect: CGRect(x: 50, y: 50, width: 1, height: 100), mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .min), deltaX: 10))
        XCTAssertRectEqual(topHotspot.rect, CGRect(x: 50, y: 50, width: 11, height: 100))

        let bottomHotspot = self.createHotspot(shape: .oval, rect: CGRect(x: 50, y: 50, width: 1, height: 100), mode: .edit, drag: TestDrag(startPoint: (x: .min, y: .max), deltaX: 10))
        XCTAssertRectEqual(bottomHotspot.rect, CGRect(x: 50, y: 50, width: 11, height: 100))
    }


    //MARK: - Creating hotspot
    func test_creatingHotspot_resizesAwayFromClickPointIfInCreateMode() throws {
        let createdHotspot = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(x: 30, y: 40, width: 0, height: 0), mode: .create, imageSize: CGSize(width: 200, height: 200))
        createdHotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)
        createdHotspot.draggedEvent(at: CGPoint(x: 50, y: 140), modifiers: [], eventCount: 1)
        createdHotspot.upEvent(at: CGPoint(x: 50, y: 140), modifiers: [], eventCount: 1)

        XCTAssertRectEqual(createdHotspot.rect, CGRect(x: 30, y: 40, width: 20, height: 100))
    }

    func test_creatingHotspot_switchesToEditModeOnMouseUp() throws {
        let createdHotspot = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(x: 30, y: 40, width: 0, height: 0), mode: .create, imageSize: CGSize(width: 200, height: 200))
        createdHotspot.downEvent(at: CGPoint(x: 30, y: 40), modifiers: [], eventCount: 1)
        createdHotspot.draggedEvent(at: CGPoint(x: 50, y: 140), modifiers: [], eventCount: 1)
        createdHotspot.upEvent(at: CGPoint(x: 50, y: 140), modifiers: [], eventCount: 1)

        XCTAssertEqual(createdHotspot.mode, .edit)
    }


    //MARK: - Moving
    func test_moving_draggingInsideHotspotPathButNotInEditingHandleRectMovesHotspot() throws {
        let movedHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .mid, y: .mid), deltaX: 10, deltaY: 10))
        XCTAssertRectEqual(movedHotspot.rect, CGRect(x: 60, y: 60, width: 100, height: 100))
    }

    func test_moving_doesntMoveBeyondLeftOfImageBound() throws {
        let movedHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .mid, y: .mid), deltaX: -60, deltaY: 0))
        XCTAssertRectEqual(movedHotspot.rect, CGRect(x: 0, y: 50, width: 100, height: 100))
    }

    func test_moving_doesntMoveBeyondTopOfImageBound() throws {
        let movedHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .mid, y: .mid), deltaX: 0, deltaY: -60))
        XCTAssertRectEqual(movedHotspot.rect, CGRect(x: 50, y: 0, width: 100, height: 100))
    }

    func test_moving_doesntMoveBeyondRightOfImageBound() throws {
        let movedHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .mid, y: .mid), deltaX: 60, deltaY: 0))
        XCTAssertRectEqual(movedHotspot.rect, CGRect(x: 100, y: 50, width: 100, height: 100))
    }

    func test_moving_doesntMoveBeyondBottomOfImageBound() throws {
        let movedHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .mid, y: .mid), deltaX: 0, deltaY: 60))
        XCTAssertRectEqual(movedHotspot.rect, CGRect(x: 50, y: 100, width: 100, height: 100))
    }

    func test_moving_doesntMoveIfInViewMode() throws {
        let movedHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .mid, y: .mid), deltaX: 10, deltaY: 10))
        XCTAssertRectEqual(movedHotspot.rect, CGRect(x: 50, y: 50, width: 100, height: 100))
    }

    func test_moving_doesntMoveIfInCreateMode() throws {
        let movedHotspot = self.createHotspot(shape: .oval, mode: .create, drag: TestDrag(startPoint: (x: .mid, y: .mid), deltaX: 10, deltaY: 10))
        //We just check the origin here as this will technically do a resize but we don't care if it does that, we just care that we aren't moving
        XCTAssertEqual(movedHotspot.rect.origin, CGPoint(x: 50, y: 50))
    }


    //MARK: - Selecting
    func test_selecting_clickingWithoutDraggingSetsIsSelectedToTrue() throws {
        let selectedHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .mid, y: .mid)))
        XCTAssertTrue(selectedHotspot.isSelected)
    }

    func test_selecting_holdingShiftWhileClickingSetsSelectedToTrueIfFalse() throws {
        let selectedHotspot = self.createHotspot(shape: .oval, mode: .edit, drag: TestDrag(startPoint: (x: .mid, y: .mid), modifiers: .shift))
        XCTAssertTrue(selectedHotspot.isSelected)
    }

    func test_selecting_holdingShiftWhileClickingSetsSelectedToFalseIfTrue() throws {
        let selectedHotspot = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(x: 50, y: 50, width: 100, height: 100), mode: .edit, imageSize: CGSize(width: 200, height: 200))
        selectedHotspot.isSelected = true
        selectedHotspot.downEvent(at: CGPoint(x: 100, y: 100), modifiers: .shift, eventCount: 1)
        selectedHotspot.upEvent(at: CGPoint(x: 100, y: 100), modifiers: .shift, eventCount: 1)

        XCTAssertFalse(selectedHotspot.isSelected)
    }

    func test_selecting_clickingWithNoModifiersTellsLayoutEngineToDeselectOtherHotspots() throws {
        let mockLayoutEngine = MockLayoutEngine()

        let selectedHotspot = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(x: 50, y: 50, width: 100, height: 100), mode: .edit, imageSize: CGSize(width: 200, height: 200))
        selectedHotspot.layoutEngine = mockLayoutEngine
        selectedHotspot.downEvent(at: CGPoint(x: 100, y: 100), modifiers: [], eventCount: 1)
        selectedHotspot.upEvent(at: CGPoint(x: 100, y: 100), modifiers: [], eventCount: 1)

        XCTAssertTrue(mockLayoutEngine.deselectAllMock.wasCalled)
    }

    func test_selecting_holdingShiftWhileClickingDoesNotTellLayoutEngineToDeselectOtherHotspots() throws {
        let mockLayoutEngine = MockLayoutEngine()

        let selectedHotspot = ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(x: 50, y: 50, width: 100, height: 100), mode: .edit, imageSize: CGSize(width: 200, height: 200))
        selectedHotspot.layoutEngine = mockLayoutEngine
        selectedHotspot.downEvent(at: CGPoint(x: 100, y: 100), modifiers: .shift, eventCount: 1)
        selectedHotspot.upEvent(at: CGPoint(x: 100, y: 100), modifiers: .shift, eventCount: 1)

        XCTAssertFalse(mockLayoutEngine.deselectAllMock.wasCalled)
    }

    func test_selecting_doesNotSelectIfClickedInViewMode() throws {
        let selectedHotspot = self.createHotspot(shape: .oval, mode: .view, drag: TestDrag(startPoint: (x: .mid, y: .mid)))
        XCTAssertFalse(selectedHotspot.isSelected)
    }

    func test_selecting_doesNotSelectIfClickedInCreateMode() throws {
        let selectedHotspot = self.createHotspot(shape: .oval, mode: .create, drag: TestDrag(startPoint: (x: .mid, y: .mid)))
        XCTAssertFalse(selectedHotspot.isSelected)
    }
}

extension ImageEditorRectangleHotspotTests {
    class MockLayoutEngine: ImageEditorHotspotLayoutEngine {
        let deselectAllMock = MockDetails<Void, Void>()
        override func deselectAll() {
            self.deselectAllMock.called()
            super.deselectAll()
        }
    }
}

func XCTAssertRectEqual(_ r1: CGRect, _ r2: CGRect) {
    XCTAssertEqual(r1.origin, r2.origin)
    XCTAssertEqual(r1.size, r2.size)
}
