//
//  ArrowLayoutEngineTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 14/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class ArrowLayoutEngineTests: XCTestCase {
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }


    //MARK: - ArrowLayoutEngine.trees(from:)
    func test_treesFromPages_returnsTreeForEachNodeWithChildrenButNoParent() {
        XCTFail()
    }

    func test_treesFromPages_doesntReturnTreeForNodesWithNoChildrenAndNoParent() {
        XCTFail()
    }

    func test_treesFromPages_returnedTreesHaveChildrenSetUpCorrectly() {
        XCTFail()
    }


    //MARK: - calculateArrows() - Single child (Basic)
    func test_calculateArrows_childDirectlyToLeftOfParent() {
        XCTFail()
    }

    func test_calculateArrows_childDirectlyAboveParent() {
        XCTFail()
    }

    func test_calculateArrows_childDirectlyToRightOfParent() {
        XCTFail()
    }

    func test_calculateArrows_childDirectlyBelowParent() {
        XCTFail()
    }

    func test_calculateArrows_childrenAtEachSideOfParent() {
        XCTFail()
    }

    func test_calculateArrows_childToTopLeftOfParent() {
        XCTFail()
    }

    func test_calculateArrows_childToTopRightOfParent() {
        XCTFail()
    }

    func test_calculateArrows_childToBottomRightOfParent() {
        XCTFail()
    }

    func test_calculateArrows_childToBottomLeftOfParent() {
        XCTFail()
    }

    func test_calculateArrows_childrenAtEachCornerOfParent() {
        XCTFail()
    }


    //MARK: - calculateArrows() - Single child (Advanced)
    func test_calculateArrows_childInTopDirectionFromParentButBottomIsBelowParentTop() {
        XCTFail()
    }

    func test_calculateArrows_childInBottomDirectionFromParentButTopIsAboveParentBottom() {
        XCTFail()
    }

    func test_calculateArrows_childInLeftDirectionFromParentButRightIsToRightOfParentLeft() {
        XCTFail()
    }

    func test_calculateArrows_childInRightDirectionFromParentButLeftIsToLeftOfParentRight() {
        XCTFail()
    }


    //MARK: - calculateArrows() - Multiple children
    func test_calculateArrows_multipleChildrenToLeftOfParent() {
        XCTFail()
    }

    func test_calculateArrows_multipleChildrenAboveParent() {
        XCTFail()
    }

    func test_calculateArrows_multipleChildrenToRightOfParent() {
        XCTFail()
    }

    func test_calculateArrows_multipleChildrenBelowParent() {
        XCTFail()
    }


    //MARK: - calculateArrows() - Deep Trees
    func test_calculateArrows_multipleLevelsOfChildrenToLeftOfParent() {
        XCTFail()
    }

    func test_calculateArrows_multipleLevelsOfChildrenAboveParent() {
        XCTFail()
    }

    func test_calculateArrows_multipleLevelsOfChildrenToRightOfParent() {
        XCTFail()
    }

    func test_calculateArrows_childAndParentToLeftOfPage() {
        XCTFail()
    }

    func test_calculateArrows_childAndParentAbovePage() {
        XCTFail()
    }

    func test_calculateArrows_childAndParentToRightOfPage() {
        XCTFail()
    }

    func test_calculateArrows_childAndParentBelowPage() {
        XCTFail()
    }


    //MARK: - LayoutTree.addChild(_:)
    func test_addChild_setsParentOfSuppliedChildToReceiver() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 100, height: 200))
        let child = LayoutTree(frame: CGRect(x: 20, y: 30, width: 50, height: 60))
        root.addChild(child)

        XCTAssertEqual(child.parent, root)
    }

    func test_addChild_assignsChildLeftDirectionIfCenterInsideLeftOfParentRect() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: -5, y: -5, width: 20, height: 20))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .left).contains(child))
    }

    func test_addChild_assignsChildRightDirectionifCenterInsideRightOfParentRect() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: 20, y: 40, width: 15, height: 15))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildLeftDirectionIfCenterWithinTopAndBottomOfParentAndToLeft() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: -40, y: -10, width: 20, height: 30))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .left).contains(child))
    }

    func test_addChild_assignsChildRightDirectionIfCenterWithinTopAndBottomOfParentAndToRight() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: 40, y: 50, width: 10, height: 20))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildTopDirectionIfCenterWithinLeftAndRightOfParentAndToTop() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: -5, y: -30, width: 15, height: 20))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .top).contains(child))
    }

    func test_addChild_assignsChildBottomDirectionifCenterWithinLeftAndRightOfParentAndToBottom() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: 20, y: 70, width: 15, height: 30))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .bottom).contains(child))
    }

    func test_addChild_assignsChildLeftDirectionIfCenterIsToTopLeftButBelowDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: -7, y: -6, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .left).contains(child))
    }

    func test_addChild_assignsChildLeftDirectionIfCenterIsToTopLeftAndOnDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: -7, y: -7, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .left).contains(child))
    }

    func test_addChild_assignsChildTopDirectionIfCenterIsToTopLeftAndAboveDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: -7, y: -8, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .top).contains(child))
    }

    func test_addChild_assignsChildTopDirectionIfCenterIsToTopRightAndAboveDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: 27, y: -8, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .top).contains(child))
    }

    func test_addChild_assignsChildTopDirectionIfCenterIsToTopRightAndOnDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: 27, y: -7, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .top).contains(child))
    }

    func test_addChild_assignsChildRightDirectionIfCenterIsToTopRightAndBelowDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: 27, y: -6, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildRightDirectionIfCenterIsToBottomRightAndAboveDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: 27, y: 56, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildRightDirctionIfCenterIsToBottomRightAndOnDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: 27, y: 57, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .right).contains(child))
    }

    func test_addChild_assignsChildBottomDirectionIfCenterIsToBottomRightAndBelowDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: 27, y: 58, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .bottom).contains(child))
    }

    func test_addChild_assignsChildBottomDirectionIfCenterIsToBottomLeftAndBelowDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: -7, y: 58, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .bottom).contains(child))
    }

    func test_addChild_assignChildBottomDirectionIfCenterIsToBottomLeftAndOnDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: -7, y: 57, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .bottom).contains(child))
    }

    func test_addChild_assignChildLeftDirectionIfCenterIsToBottomLeftAndAboveDiagonal() {
        let root = LayoutTree(frame: CGRect(x: 0, y: 0, width: 30, height: 60))
        let child = LayoutTree(frame: CGRect(x: -7, y: 56, width: 10, height: 10))
        root.addChild(child)

        XCTAssertTrue(root.children(for: .left).contains(child))
    }
}
