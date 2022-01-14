//
//  CoreGraphics+M3ExtensionsTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 10/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class CoreGraphics_M3ExtensionsTests: XCTestCase {
    //MARK: - CGPoint.identity
    func test_point_identity_valuesAreOne() {
        XCTAssertEqual(CGPoint.identity, CGPoint(x: 1, y: 1))
    }

    //MARK: - CGPoint.plus(_:)
    func test_point_plus_addsXAndYToReceiver() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.plus(CGPoint(x: 5, y: 4)), CGPoint(x: 15, y: 19))
    }

    func test_point_plus_subtractsXAndYFromReceiverIfNegative() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.plus(CGPoint(x: -5, y: -4)), CGPoint(x: 5, y: 11))
    }

    //MARK: - CGPoint.plus(x:y:)
    func test_point_plusXY_addsXAndYToReceiver() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.plus(x: 5, y: 4), CGPoint(x: 15, y: 19))
    }

    func test_point_plusXY_subtractsXAndYFromReceiverIfNegative() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.plus(x: -5, y: -4), CGPoint(x: 5, y: 11))
    }

    //MARK: - CGPoint.minus(_:)
    func test_point_minus_subtractsXAndYFromReceiver() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.minus(CGPoint(x: 5, y: 4)), CGPoint(x: 5, y: 11))
    }

    func test_point_minus_addsXAndYToReceiverIfNegative() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.minus(CGPoint(x: -5, y: -4)), CGPoint(x: 15, y: 19))
    }

    //MARK: - CGPoint.minus(x:y:)
    func test_point_minusXY_subtractsXAndYFromReceiver() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.minus(x: 5, y: 4), CGPoint(x: 5, y: 11))
    }

    func test_point_minusXY_addsXAndYToReceiverIfNegative() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.minus(x: -5, y: -4), CGPoint(x: 15, y: 19))
    }

    //MARK: - CGPoint.multipled(by:)
    func test_point_multiplied_multipliesXAndYIfFactorIsAbove1() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.multiplied(by: 2), CGPoint(x: 20, y: 30))
    }

    func test_point_multiplied_dividesXAndYIfFactorIsBelow1() {
        let point = CGPoint(x: 10, y: 15)
        XCTAssertEqual(point.multiplied(by: 0.2), CGPoint(x: 2, y: 3))
    }

    //MARK: - CGPoint.rounded()
    func test_point_rounded_roundsXAndYToNearestValue() {
        XCTAssertEqual(CGPoint(x: 12.892, y: 21.241).rounded(), CGPoint(x: 13, y: 21))
    }

    //MARK: - CGPoint.bounded(within:)
    func test_point_boundedWithinRect_reducesXToMaxXIfOutsideRect() {
        let rect = CGRect(x: 5, y: 5, width: 20, height: 20)
        XCTAssertEqual(CGPoint(x: 40, y: 0).bounded(within: rect).x, 24)
    }

    func test_point_boundedWithinRect_increasesXToMatchMinXIfOutsideRect() {
        let rect = CGRect(x: 5, y: 5, width: 20, height: 20)
        XCTAssertEqual(CGPoint(x: 0, y: 0).bounded(within: rect).x, 5)
    }

    func test_point_boundedWithinRect_doesntChangeXIfInsideRect() {
        let rect = CGRect(x: 5, y: 5, width: 20, height: 20)
        XCTAssertEqual(CGPoint(x: 17, y: 0).bounded(within: rect).x, 17)
    }

    func test_point_boundedWithinRect_reducesYToMaxYIfOutsideRect() {
        let rect = CGRect(x: 5, y: 5, width: 20, height: 20)
        XCTAssertEqual(CGPoint(x: 0, y: 92).bounded(within: rect).y, 24)
    }

    func test_point_boundedWithinRect_increasesYToMatchMinYIfOutsideRect() {
        let rect = CGRect(x: 5, y: 5, width: 20, height: 20)
        XCTAssertEqual(CGPoint(x: 0, y: -92).bounded(within: rect).y, 5)
    }

    func test_point_boundedWithinRect_doesntChangeYIfInsideRect() {
        let rect = CGRect(x: 5, y: 5, width: 20, height: 20)
        XCTAssertEqual(CGPoint(x: 0, y: 13).bounded(within: rect).y, 13)
    }

    //MARK: - CGPoint.toRect(with:)
    func test_point_toRectWithSize_createsRectWithReceiverAsOriginAndSuppliedSize() {
        let point = CGPoint(x: 13, y: 14)
        let size = CGSize(width: 15, height: 16)
        XCTAssertEqual(point.toRect(with: size), CGRect(x: 13, y: 14, width: 15, height: 16))
    }

    //MARK: - CGPoint.toSize()
    func test_point_toSize_createsSizeWithXAsWidthAndYAsHeight() {
        let point = CGPoint(x: 42, y: 31)
        XCTAssertEqual(point.toSize(), CGSize(width: 42, height: 31))
    }

    //MARK: - CGPoint.distance(to:)
    func test_distanceToOtherPoint_returnsCorrectDistanceIfPointToUpperRightOfSelf() throws {
        let point = CGPoint(x: 42, y: 31)
        let otherPoint = CGPoint(x: 46, y: 34)
        XCTAssertEqual(point.distance(to: otherPoint), 5)
    }

    func test_distanceToOtherPoint_returnsCorrectDistanceIfPointToLowerLeftOfSelf() throws {
        let point = CGPoint(x: -42, y: -31)
        let otherPoint = CGPoint(x: -46, y: -34)
        XCTAssertEqual(point.distance(to: otherPoint), 5)
    }



    //MARK: - CGSize.identity
    func test_size_identity_valuesAreOne() {
        XCTAssertEqual(CGSize.identity, CGSize(width: 1, height: 1))
    }

    //MARK: - CGSize.plus(_:)
    func test_size_plus_addsWidthAndHeightToReceiver() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.plus(CGSize(width: 5, height: 4)), CGSize(width: 15, height: 19))
    }

    func test_size_plus_subtractsWidthAndHeightFromReceiverIfNegative() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.plus(CGSize(width: -5, height: -4)), CGSize(width: 5, height: 11))
    }

    //MARK: - CGSize.plus(width:height:)
    func test_size_plusXY_addsWidthAndHeightToReceiver() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.plus(width: 5, height: 4), CGSize(width: 15, height: 19))
    }

    func test_size_plusXY_subtractsWidthAndHeightFromReceiverIfNegative() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.plus(width: -5, height: -4), CGSize(width: 5, height: 11))
    }

    //MARK: - CGSize.minus(_:)
    func test_size_minus_subtractsWidthAndHeightFromReceiver() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.minus(CGSize(width: 5, height: 4)), CGSize(width: 5, height: 11))
    }

    func test_size_minus_addsWidthAndHeightToReceiverIfNegative() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.minus(CGSize(width: -5, height: -4)), CGSize(width: 15, height: 19))
    }

    //MARK: - CGSize.minus(width:height:)
    func test_size_minusXY_subtractsWidthAndHeightFromReceiver() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.minus(width: 5, height: 4), CGSize(width: 5, height: 11))
    }

    func test_size_minusXY_addsWidthAndHeightToReceiverIfNegative() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.minus(width: -5, height: -4), CGSize(width: 15, height: 19))
    }

    //MARK: - CGSize.multiplied(by:)
    func test_size_multiplied_multipliesWidthAndHeightIfFactorIsAbove1() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.multiplied(by: 2), CGSize(width: 20, height: 30))
    }

    func test_size_multiplied_dividesWidthAndHeightIfFactorIsBelow1() {
        let size = CGSize(width: 10, height: 15)
        XCTAssertEqual(size.multiplied(by: 0.2), CGSize(width: 2, height: 3))
    }

    //MARK: - CGSize.rounded()
    func test_size_rounded_roundsWidthAndHeightToNearestValue() {
        XCTAssertEqual(CGSize(width: 12.892, height: 21.241).rounded(), CGSize(width: 13, height: 21))
    }

    //MARK: - CGSize.toRect(withOrigin:)
    func test_size_toRectWithOrigin_createsRectWithReceiverAsSizeAndSuppliedOrigin() {
        let size = CGSize(width: 13, height: 14)
        let point = CGPoint(x: 15, y: 16)
        XCTAssertEqual(size.toRect(withOrigin: point), CGRect(x: 15, y: 16, width: 13, height: 14))
    }

    //MARK: - CGSize.toPoint()
    func test_size_toSize_createsSizeWithWidthAsXAndHeightAsY() {
        let size = CGSize(width: 42, height: 31)
        XCTAssertEqual(size.toPoint(), CGPoint(x: 42, y: 31))
    }

    //MARK: - CGSize.scaleDownToFit(width:height:)
    func test_size_scaleDownToFit_doesntChangeSizeIfWidthAndHeightGreaterThanSelf() throws {
        let size = CGSize(width: 120, height: 90)
        let scaled = size.scaleDownToFit(width: 121, height: 91)
        XCTAssertEqual(scaled, size)
    }

    func test_size_scaleDownToFit_doesntChangeSizeIfWidthAndHeightEqualToSelf() throws {
        let size = CGSize(width: 120, height: 90)
        let scaled = size.scaleDownToFit(width: 120, height: 90)
        XCTAssertEqual(scaled, size)
    }

    func test_size_scaleDownToFit_setsWidthToSuppliedWidthAndScalesHeightIfTooWide() throws {
        let size = CGSize(width: 120, height: 90)
        let scaled = size.scaleDownToFit(width: 60, height: 100)
        XCTAssertEqual(scaled, CGSize(width: 60, height: 45))
    }

    func test_size_scaleDownToFit_setsHeightToSuppliedHeightAndScalesWidthIfTooTall() throws {
        let size = CGSize(width: 120, height: 90)
        let scaled = size.scaleDownToFit(width: 150, height: 60)
        XCTAssertEqual(scaled, CGSize(width: 80, height: 60))
    }

    func test_size_scaleDownToFit_setsHeightToSuppliedHeightAndScalesWidthIfTooWideAndTooTall() throws {
        let size = CGSize(width: 120, height: 90)
        let scaled = size.scaleDownToFit(width: 60, height: 30)
        XCTAssertEqual(scaled, CGSize(width: 40, height: 30))
    }

    func test_size_scaleDownToFit_scalesDownWidthAndHeightIfUsingCGSizeVersion() throws {
        let size = CGSize(width: 120, height: 90)
        let scaled = size.scaleDownToFit(CGSize(width: 60, height: 30))
        XCTAssertEqual(scaled, CGSize(width: 40, height: 30))
    }

    //MARK: - CGSize.centred(in:)
    func test_size_centredInRect_centresInRectBiggerThanSize() throws {
        let size = CGSize(width: 120, height: 33)
        let rect = CGRect(x: -10, y: 30, width: 200, height: 200)

        let centredRect = size.centred(in: rect)
        XCTAssertEqual(centredRect, CGRect(origin: CGPoint(x: 30, y: 113.5), size: size))
    }

    func test_size_centredInRect_centresInRectSameSizeAsSize() throws {
        let size = CGSize(width: 120, height: 33)
        let rect = CGRect(x: -10, y: 30, width: 120, height: 33)

        let centredRect = size.centred(in: rect)
        XCTAssertEqual(centredRect, CGRect(origin: CGPoint(x: -10, y: 30), size: size))
    }

    func test_size_centredInRect_centresInRectSmallerThanSize() throws {
        let size = CGSize(width: 120, height: 33)
        let rect = CGRect(x: -10, y: 30, width: 51, height: 27)

        let centredRect = size.centred(in: rect)
        XCTAssertEqual(centredRect, CGRect(origin: CGPoint(x: -44.5, y: 27), size: size))
    }



    //MARK: - CGRect.init(width:height:centredIn:)
    func test_rect_initWidthHeightCentredIn_rectHasSuppliedWidthAndHeight() {
        let outerRect = CGRect(x: 18, y: 20, width: 22, height: 10)
        let innerRect = CGRect(width: 5, height: 8, centredIn: outerRect)

        XCTAssertEqual(innerRect.size, CGSize(width: 5, height: 8))
    }

    func test_rect_initWidthHeightCentredIn_rectHasSameCentrePointAsSuppliedRect() {
        let outerRect = CGRect(x: 18, y: 20, width: 22, height: 10)
        let innerRect = CGRect(width: 5, height: 8, centredIn: outerRect)

        XCTAssertEqual(innerRect.midPoint, outerRect.midPoint)
    }

    //MARK: - CGRect.init?(points:)
    func test_rect_initPoints_returnsNilIfEmptyArrayProvided() {
        XCTAssertNil(CGRect(points: []))
    }

    func test_rect_initPoints_returnsRectWithPointAsOriginAndZeroSizeIfOnePointSupplied() {
        let rect = CGRect(points: [CGPoint(x: 23, y: 31)])
        XCTAssertEqual(rect, CGRect(x: 23, y: 31, width: 0, height: 0))
    }

    func test_rect_initPoints_returnsRectBoundingTwoPoints() {
        let rect = CGRect(points: [CGPoint(x: -10, y: 20), CGPoint(x: 20, y: -10)])
        XCTAssertEqual(rect, CGRect(x: -10, y: -10, width: 30, height: 30))
    }

    func test_rect_initPoints_returnsRectBounding2OutmostPointsIfOtherPointsInside() {
        let rect = CGRect(points: [CGPoint(x: -10, y: 20), CGPoint(x: 20, y: -10), CGPoint(x: 10, y: 10)])
        XCTAssertEqual(rect, CGRect(x: -10, y: -10, width: 30, height: 30))
    }

    func test_rect_initPoints_rectKeepsGrowingIfPointsKeepMovingOutside() {
        let rect = CGRect(points: [
            CGPoint(x: 3, y: -2),
            CGPoint(x: 10, y: -2),
            CGPoint(x: 5, y: 14),
            CGPoint(x: -2, y: -3),
        ])
        XCTAssertEqual(rect, CGRect(x: -2, y: -3, width: 12, height: 17))
    }

    //MARK: - CGRect.rounded()
    func test_rect_rounded_roundsXYWidthAndHeight() {
        let rect = CGRect(x: 13.5, y: -12.214, width: 99.692, height: 17.241)
        XCTAssertEqual(rect.rounded(), CGRect(x: 14, y: -12, width: 100, height: 17))
    }

    //MARK: - CGRect.point(atX:y:)
    func test_rect_pointAtXY_returnsMinXPoint() {
        let rect = CGRect(x: 15, y: 12, width: 42, height: 9)
        XCTAssertEqual(rect.point(atX: .min, y: .min).x, 15)
    }

    func test_rect_pointAtXY_returnsMidXPoint() {
        let rect = CGRect(x: 15, y: 12, width: 42, height: 9)
        XCTAssertEqual(rect.point(atX: .mid, y: .min).x, 36)
    }

    func test_rect_pointAtXY_returnsMaxXPoint() {
        let rect = CGRect(x: 15, y: 12, width: 42, height: 9)
        XCTAssertEqual(rect.point(atX: .max, y: .min).x, 57)
    }

    func test_rect_pointAtXY_returnsMinYPoint() {
        let rect = CGRect(x: 15, y: 12, width: 42, height: 9)
        XCTAssertEqual(rect.point(atX: .min, y: .min).y, 12)
    }

    func test_rect_pointAtXY_returnsMidYPoint() {
        let rect = CGRect(x: 15, y: 12, width: 42, height: 9)
        XCTAssertEqual(rect.point(atX: .min, y: .mid).y, 16.5)
    }

    func test_rect_pointAtXY_returnsMaxYPoint() {
        let rect = CGRect(x: 15, y: 12, width: 42, height: 9)
        XCTAssertEqual(rect.point(atX: .min, y: .max).y, 21)
    }

    //MARK: - midPoint
    func test_rect_midPoint_returnsMiddleOfRect() {
        let rect = CGRect(x: 22, y: 13, width: 8, height: 7)
        XCTAssertEqual(rect.midPoint, CGPoint(x: 26, y: 16.5))
    }

    //MARK: - insetBy(_:flipped:)
    func test_rect_insetByEdgeInsets_insetsPositiveInsets() {
        let rect = CGRect(x: 41, y: 52, width: 89, height: 62)
        let insets = NSEdgeInsets(top: 2, left: 3, bottom: 5, right: 6)
        XCTAssertEqual(rect.insetBy(insets), CGRect(x: 44, y: 54, width: 80, height: 55))
    }

    func test_rect_insetByEdgeInsets_insetsNegativeInsets() throws {
        let rect = CGRect(x: 41, y: 52, width: 89, height: 62)
        let insets = NSEdgeInsets(top: -7, left: -2, bottom: -4, right: -5)
        XCTAssertEqual(rect.insetBy(insets), CGRect(x: 39, y: 45, width: 96, height: 73))
    }

    func test_rect_insetByEdgeInsets_usesBottomToAdjustOriginIfNotFlipped() throws {
        let rect = CGRect(x: 41, y: 52, width: 89, height: 62)
        let insets = NSEdgeInsets(top: 2, left: 3, bottom: 5, right: 6)
        XCTAssertEqual(rect.insetBy(insets, flipped: false), CGRect(x: 44, y: 57, width: 80, height: 55))
    }
}
