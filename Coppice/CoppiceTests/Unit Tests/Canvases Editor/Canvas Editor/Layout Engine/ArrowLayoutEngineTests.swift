//
//  ArrowLayoutEngineTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 14/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice
@testable import CoppiceCore

class ArrowLayoutEngineTests: XCTestCase {

    var layoutEngine: CanvasLayoutEngine!
    var rootPage: LayoutEnginePage!
    override func setUpWithError() throws {
        self.layoutEngine = self.createLayoutEngine()
        self.rootPage = LayoutEnginePage(id: UUID(), contentFrame: CGRect(x: 0, y: 0, width: 20, height: 40), minimumContentSize: .zero)
        self.layoutEngine.add([self.rootPage])
    }

    override func tearDownWithError() throws {
        self.layoutEngine = nil
        self.rootPage = nil
    }


    //MARK: - calculateArrows() - Single child (Basic)
    func test_calculateArrows_childDirectlyToLeftOfParent() throws {
        let child1 = self.createPage(frame: CGRect(x: -30, y: 5, width: 10, height: 10), parent: self.rootPage)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)
        let arrow = try XCTUnwrap(arrows.first)

        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 0, y: 20)))
        XCTAssertEqual(arrow.startPoint.edge, .left)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: -20, y: 10)))
        XCTAssertEqual(arrow.endPoint.edge, .right)
        XCTAssertEqual(arrow.endPoint.pageID, child1.id)
    }

    func test_calculateArrows_childDirectlyAboveParent() throws {
        let child1 = self.createPage(frame: CGRect(x: 5, y: -25, width: 10, height: 10), parent: self.rootPage)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)
        let arrow = try XCTUnwrap(arrows.first)

        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 10, y: 0)))
        XCTAssertEqual(arrow.startPoint.edge, .top)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: 10, y: -15)))
        XCTAssertEqual(arrow.endPoint.edge, .bottom)
        XCTAssertEqual(arrow.endPoint.pageID, child1.id)
    }

    func test_calculateArrows_childDirectlyToRightOfParent() throws {
        let child1 = self.createPage(frame: CGRect(x: 30, y: 7, width: 10, height: 10), parent: self.rootPage)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)
        let arrow = try XCTUnwrap(arrows.first)

        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 20, y: 20)))
        XCTAssertEqual(arrow.startPoint.edge, .right)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: 30, y: 12)))
        XCTAssertEqual(arrow.endPoint.edge, .left)
        XCTAssertEqual(arrow.endPoint.pageID, child1.id)
    }

    func test_calculateArrows_childDirectlyBelowParent() throws {
        let child1 = self.createPage(frame: CGRect(x: 3, y: 55, width: 10, height: 10), parent: self.rootPage)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)
        let arrow = try XCTUnwrap(arrows.first)

        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 10, y: 40)))
        XCTAssertEqual(arrow.startPoint.edge, .bottom)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: 8, y: 55)))
        XCTAssertEqual(arrow.endPoint.edge, .top)
        XCTAssertEqual(arrow.endPoint.pageID, child1.id)
    }

    func test_calculateArrows_childrenAtEachSideOfParent() throws {
        let left = self.createPage(frame: CGRect(x: -22, y: 4, width: 10, height: 10), parent: self.rootPage)
        let top = self.createPage(frame: CGRect(x: 4, y: -22, width: 10, height: 10), parent: self.rootPage)
        let right = self.createPage(frame: CGRect(x: 32, y: 4, width: 10, height: 10), parent: self.rootPage)
        let bottom = self.createPage(frame: CGRect(x: 4, y: 52, width: 10, height: 10), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, left, top, right, bottom])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 4)
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 0, y: 20, edge:  .left, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: -12, y: 9, edge:  .right, page: left))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 10, y: 0, edge:  .top, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 9, y: -12, edge:  .bottom, page: top))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 20, y: 20, edge:  .right, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 32, y: 9, edge:  .left, page: right))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 10, y: 40, edge:  .bottom, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 9, y: 52, edge:  .top, page: bottom))))
    }

    func test_calculateArrows_childToTopLeftOfParent() throws {
        let child = self.createPage(frame: CGRect(x: -10, y: -20, width: 10, height: 10), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, child])
        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)

        let arrow = try XCTUnwrap(arrows.first)
        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 10, y: 0)))
        XCTAssertEqual(arrow.startPoint.edge, .top)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: -5, y: -10)))
        XCTAssertEqual(arrow.endPoint.edge, .bottom)
        XCTAssertEqual(arrow.endPoint.pageID, child.id)
    }

    func test_calculateArrows_childToTopRightOfParent() throws {
        let child = self.createPage(frame: CGRect(x: 40, y: -40, width: 10, height: 10), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, child])
        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)

        let arrow = try XCTUnwrap(arrows.first)
        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 10, y: 0)))
        XCTAssertEqual(arrow.startPoint.edge, .top)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: 45, y: -30)))
        XCTAssertEqual(arrow.endPoint.edge, .bottom)
        XCTAssertEqual(arrow.endPoint.pageID, child.id)
    }

    func test_calculateArrows_childToBottomRightOfParent() throws {
        let child = self.createPage(frame: CGRect(x: 40, y: 70, width: 10, height: 10), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, child])
        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)

        let arrow = try XCTUnwrap(arrows.first)
        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 10, y: 40)))
        XCTAssertEqual(arrow.startPoint.edge, .bottom)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: 45, y: 70)))
        XCTAssertEqual(arrow.endPoint.edge, .top)
        XCTAssertEqual(arrow.endPoint.pageID, child.id)
    }

    func test_calculateArrows_childToBottomLeftOfParent() throws {
        let child = self.createPage(frame: CGRect(x: -10, y: 70, width: 10, height: 10), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, child])
        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)

        let arrow = try XCTUnwrap(arrows.first)
        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 10, y: 40)))
        XCTAssertEqual(arrow.startPoint.edge, .bottom)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: -5, y: 70)))
        XCTAssertEqual(arrow.endPoint.edge, .top)
        XCTAssertEqual(arrow.endPoint.pageID, child.id)
    }

    func test_calculateArrows_childrenAtEachCornerOfParent() {
        let leftTop = self.createPage(frame: CGRect(x: -50, y: -20, width: 10, height: 10), parent: self.rootPage)
        let topRight = self.createPage(frame: CGRect(x: 25, y: -43, width: 10, height: 10), parent: self.rootPage)
        let rightBottom = self.createPage(frame: CGRect(x: 80, y: 42, width: 10, height: 10), parent: self.rootPage)
        let bottomLeft = self.createPage(frame: CGRect(x: -15, y: 82, width: 10, height: 10), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, leftTop, topRight, rightBottom, bottomLeft])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 4)
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 0, y: 20, edge:  .left, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: -40, y: -15, edge:  .right, page: leftTop))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 10, y: 0, edge:  .top, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 30, y: -33, edge:  .bottom, page: topRight))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 20, y: 20, edge:  .right, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 80, y: 47, edge:  .left, page: rightBottom))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 10, y: 40, edge:  .bottom, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: -10, y: 82, edge: .top, page: bottomLeft))))
    }


    //MARK: - calculateArrows() - Single child (Advanced)
    func test_calculateArrows_childInTopDirectionFromParentButBottomIsBelowParentTop() throws {
        let child = self.createPage(frame: CGRect(x: -10, y: -27, width: 10, height: 30), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, child])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)
        let arrow = try XCTUnwrap(arrows.first)
        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 10, y: 0)))
        XCTAssertEqual(arrow.startPoint.edge, .top)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: -5, y: 3)))
        XCTAssertEqual(arrow.endPoint.edge, .bottom)
        XCTAssertEqual(arrow.endPoint.pageID, child.id)
    }

    func test_calculateArrows_childInBottomDirectionFromParentButTopIsAboveParentBottom() throws {
        let child = self.createPage(frame: CGRect(x: 25, y: 37, width: 10, height: 30), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, child])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)
        let arrow = try XCTUnwrap(arrows.first)
        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 10, y: 40)))
        XCTAssertEqual(arrow.startPoint.edge, .bottom)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: 30, y: 37)))
        XCTAssertEqual(arrow.endPoint.edge, .top)
        XCTAssertEqual(arrow.endPoint.pageID, child.id)
    }

    func test_calculateArrows_childInLeftDirectionFromParentButRightIsToRightOfParentLeft() throws {
        let child = self.createPage(frame: CGRect(x: -27, y: 45, width: 30, height: 10), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, child])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)
        let arrow = try XCTUnwrap(arrows.first)
        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 0, y: 20)))
        XCTAssertEqual(arrow.startPoint.edge, .left)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: 3, y: 50)))
        XCTAssertEqual(arrow.endPoint.edge, .right)
        XCTAssertEqual(arrow.endPoint.pageID, child.id)
    }

    func test_calculateArrows_childInRightDirectionFromParentButLeftIsToLeftOfParentRight() throws {
        let child = self.createPage(frame: CGRect(x: 27, y: -15, width: 30, height: 10), parent: self.rootPage)

        let engine = ArrowLayoutEngine(pages: [self.rootPage, child])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 1)
        let arrow = try XCTUnwrap(arrows.first)
        XCTAssertEqual(arrow.startPoint.point, self.convertPoint(CGPoint(x: 20, y: 20)))
        XCTAssertEqual(arrow.startPoint.edge, .right)
        XCTAssertEqual(arrow.startPoint.pageID, self.rootPage.id)
        XCTAssertEqual(arrow.endPoint.point, self.convertPoint(CGPoint(x: 27, y: -10)))
        XCTAssertEqual(arrow.endPoint.edge, .left)
        XCTAssertEqual(arrow.endPoint.pageID, child.id)
    }


    //MARK: - calculateArrows() - Multiple children
    func test_calculateArrows_multipleChildrenToLeftOfParent() {
        let child1 = self.createPage(frame: CGRect(x: -20, y: -18, width: 10, height: 10), parent: self.rootPage)
        let child2 = self.createPage(frame: CGRect(x: -40, y: 0, width: 10, height: 10), parent: self.rootPage)
        let child3 = self.createPage(frame: CGRect(x: -20, y: 25, width: 10, height: 10), parent: self.rootPage)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, child2, child3])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 3)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 0, y: 7, edge:  .left, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: -10, y: -13, edge:  .right, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 0, y: 20, edge:  .left, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: -30, y: 5, edge:  .right, page: child2))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 0, y: 33, edge:  .left, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: -10, y: 30, edge:  .right, page: child3))))
    }

    func test_calculateArrows_multipleChildrenAboveParent() {
        let child1 = self.createPage(frame: CGRect(x: -5, y: -20, width: 10, height: 10), parent: self.rootPage)
        let child2 = self.createPage(frame: CGRect(x: 22, y: -40, width: 10, height: 10), parent: self.rootPage)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, child2])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 2)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 5, y: 0, edge:  .top, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 0, y: -10, edge:  .bottom, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 15, y: 0, edge:  .top, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 27, y: -30, edge:  .bottom, page: child2))))
    }

    func test_calculateArrows_multipleChildrenToRightOfParent() {
        let child1 = self.createPage(frame: CGRect(x: 30, y: -18, width: 10, height: 10), parent: self.rootPage)
        let child2 = self.createPage(frame: CGRect(x: 40, y: 0, width: 10, height: 10), parent: self.rootPage)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, child2])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 2)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 20, y: 10, edge:  .right, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 30, y: -13, edge:  .left, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 20, y: 30, edge:  .right, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 40, y: 5, edge:  .left, page: child2))))
    }

    func test_calculateArrows_multipleChildrenBelowParent() {
        let child1 = self.createPage(frame: CGRect(x: -5, y: 50, width: 10, height: 10), parent: self.rootPage)
        let child2 = self.createPage(frame: CGRect(x: 22, y: 60, width: 10, height: 10), parent: self.rootPage)
        let child3 = self.createPage(frame: CGRect(x: 10, y: 90, width: 10, height: 10), parent: self.rootPage)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, child2, child3])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 3)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 3, y: 40, edge:  .bottom, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 0, y: 50, edge:  .top, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 17, y: 40, edge:  .bottom, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 27, y: 60, edge:  .top, page: child2))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 10, y: 40, edge:  .bottom, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 15, y: 90, edge:  .top, page: child3))))
    }


    //MARK: - calculateArrows() - Deep Trees
    func test_calculateArrows_multipleLevelsOfChildrenToLeftOfParent() throws {
        let child1 = self.createPage(frame: CGRect(x: -30, y: 5, width: 10, height: 10), parent: self.rootPage)
        let grandChild1 = self.createPage(frame: CGRect(x: -80, y: 10, width: 10, height: 10), parent: child1)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, grandChild1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 2)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 0, y: 20, edge:  .left, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: -20, y: 10, edge:  .right, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: -30, y: 10, edge:  .left, page: child1),
                                            endPoint: self.arrowPoint(x: -70, y: 15, edge:  .right, page: grandChild1))))
    }

    func test_calculateArrows_multipleLevelsOfChildrenAboveParent()  throws {
        let child1 = self.createPage(frame: CGRect(x: 5, y: -15, width: 10, height: 10), parent: self.rootPage)
        let grandChild1 = self.createPage(frame: CGRect(x: 5, y: -40, width: 10, height: 10), parent: child1)
        let grandChild2 = self.createPage(frame: CGRect(x: 20, y: -40, width: 10, height: 10), parent: child1)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, grandChild1, grandChild2])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 3)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 10, y: 0, edge:  .top, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 10, y: -5, edge:  .bottom, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 8, y: -15, edge:  .top, page: child1),
                                            endPoint: self.arrowPoint(x: 10, y: -30, edge:  .bottom, page: grandChild1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 13, y: -15, edge:  .top, page: child1),
                                            endPoint: self.arrowPoint(x: 25, y: -30, edge:  .bottom, page: grandChild2))))
    }

    func test_calculateArrows_multipleLevelsOfChildrenToRightOfParent()  throws {
        let child1 = self.createPage(frame: CGRect(x: 40, y: 5, width: 10, height: 10), parent: self.rootPage)
        let grandChild1 = self.createPage(frame: CGRect(x: 80, y: 10, width: 10, height: 10), parent: child1)
        let greatGrandChild1 = self.createPage(frame: CGRect(x: 120, y: 15, width: 10, height: 10), parent: grandChild1)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, grandChild1, greatGrandChild1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 3)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 20, y: 20, edge:  .right, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 40, y: 10, edge:  .left, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 50, y: 10, edge:  .right, page: child1),
                                            endPoint: self.arrowPoint(x: 80, y: 15, edge:  .left, page: grandChild1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 90, y: 15, edge:  .right, page: grandChild1),
                                            endPoint: self.arrowPoint(x: 120, y: 20, edge:  .left, page: greatGrandChild1))))
    }

    func test_calculateArrows_multipleLevelsOfChildrenBelowParent()  throws {
        let child1 = self.createPage(frame: CGRect(x: -5, y: 50, width: 10, height: 10), parent: self.rootPage)
        let grandChild1 = self.createPage(frame: CGRect(x: 20, y: 90, width: 10, height: 10), parent: child1)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, grandChild1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 2)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 10, y: 40, edge:  .bottom, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 0, y: 50, edge:  .top, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 0, y: 60, edge:  .bottom, page: child1),
                                            endPoint: self.arrowPoint(x: 25, y: 90, edge:  .top, page: grandChild1))))
    }

    func test_calculateArrows_childToLeftOfGrandChildAndParent() {
        let child1 = self.createPage(frame: CGRect(x: -100, y: 5, width: 10, height: 10), parent: self.rootPage)
        let grandChild1 = self.createPage(frame: CGRect(x: -40, y: 15, width: 10, height: 10), parent: child1)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, grandChild1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 2)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 0, y: 20, edge:  .left, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: -90, y: 8, edge:  .right, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: -90, y: 13, edge:  .right, page: child1),
                                            endPoint: self.arrowPoint(x: -40, y: 20, edge:  .left, page: grandChild1))))
    }

    func test_calculateArrows_childAboveGrandchildAndParent() {
        let child1 = self.createPage(frame: CGRect(x: 15, y: -100, width: 10, height: 10), parent: self.rootPage)
        let grandChild1 = self.createPage(frame: CGRect(x: 0, y: -20, width: 10, height: 10), parent: child1)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, grandChild1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 2)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 10, y: 0, edge:  .top, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 23, y: -90, edge:  .bottom, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 18, y: -90, edge:  .bottom, page: child1),
                                            endPoint: self.arrowPoint(x: 5, y: -20, edge:  .top, page: grandChild1))))
    }

    func test_calculateArrows_childToRightOfGrandchildAndParent() {
        let child1 = self.createPage(frame: CGRect(x: 100, y: 15, width: 10, height: 10), parent: self.rootPage)
        let grandChild1 = self.createPage(frame: CGRect(x: 40, y: -10, width: 10, height: 10), parent: child1)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, grandChild1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 2)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 20, y: 20, edge:  .right, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 100, y: 23, edge:  .left, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 100, y: 18, edge:  .left, page: child1),
                                            endPoint: self.arrowPoint(x: 50, y: -5, edge:  .right, page: grandChild1))))
    }

    func test_calculateArrows_childBelowGrandchildAndParent() {
        let child1 = self.createPage(frame: CGRect(x: 15, y: 100, width: 10, height: 10), parent: self.rootPage)
        let grandChild1 = self.createPage(frame: CGRect(x: 16, y: 50, width: 10, height: 10), parent: child1)
        let engine = ArrowLayoutEngine(pages: [self.rootPage, child1, grandChild1])

        let arrows = engine.calculateArrows()
        XCTAssertEqual(arrows.count, 2)

        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 10, y: 40, edge:  .bottom, page: self.rootPage),
                                            endPoint: self.arrowPoint(x: 18, y: 100, edge:  .top, page: child1))))
        XCTAssertTrue(arrows.contains(LayoutEngineArrow(startPoint: self.arrowPoint(x: 23, y: 100, edge:  .top, page: child1),
                                            endPoint: self.arrowPoint(x: 21, y: 60, edge:  .bottom, page: grandChild1))))
    }


    //MARK: - Helpers
    func createLayoutEngine() -> CanvasLayoutEngine {
        let engine = CanvasLayoutEngine(configuration: .init(page: .init(titleHeight: 0, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 0, cornerResizeHandleSize: 0),
                                                             contentBorder: 0,
                                                             arrow: .standard))
        return engine
    }

    func createPage(frame: CGRect, parent: LayoutEnginePage? = nil) -> LayoutEnginePage {
        let page = LayoutEnginePage(id: UUID(), contentFrame: frame, minimumContentSize: .zero)
        parent?.addChild(page)
        self.layoutEngine.add([page])
        return page
    }

    func arrowPoint(x: CGFloat, y: CGFloat, edge: LayoutEnginePage.Edge, page: LayoutEnginePage) -> ArrowPoint {
        return ArrowPoint(point: self.convertPoint(CGPoint(x: x, y: y)), edge: edge, pageID: page.id)
    }

    func convertPoint(_ point: CGPoint) -> CGPoint {
        return self.layoutEngine.convertPointToCanvasSpace(point)
    }
}
