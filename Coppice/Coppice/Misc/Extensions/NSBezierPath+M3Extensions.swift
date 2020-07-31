//
//  NSBezierPath+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 01/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

extension NSBezierPath {
    convenience init(roundedRect rect: CGRect, topLeftRadius: CGFloat? = nil, topRightRadius: CGFloat? = nil, bottomLeftRadius: CGFloat? = nil, bottomRightRadius: CGFloat? = nil) {
        self.init()
        
        let radiusFactor: CGFloat = 0.66
        
        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)
        
        if let radius = topLeftRadius {
            var start = topLeft
            start.x += radius
            move(to: start)
        } else {
            move(to: topLeft)
        }
        
        if let radius = topRightRadius {
            var start = topRight
            start.x -= radius
            
            var end = topRight
            end.y += radius
            
            var startControl = start
            startControl.x += radius * radiusFactor
            
            var endControl = end
            endControl.y -= radius * radiusFactor
            line(to: start)
            curve(to: end, controlPoint1: startControl, controlPoint2: endControl)
        } else {
            line(to: topRight)
        }
        
        if let radius = bottomRightRadius {
            var start = bottomRight
            start.y -= radius
            
            var end = bottomRight
            end.x -= radius
            
            var startControl = start
            startControl.y += radius * radiusFactor
            
            var endControl = end
            endControl.x += radius * radiusFactor
            line(to: start)
            curve(to: end, controlPoint1: startControl, controlPoint2: endControl)
        } else {
            line(to: bottomRight)
        }

        if let radius = bottomLeftRadius {
            var start = bottomLeft
            start.x += radius
            
            var end = bottomLeft
            end.y -= radius
            
            var startControl = start
            startControl.x -= radius * radiusFactor
            
            var endControl = end
            endControl.y += radius * radiusFactor
            line(to: start)
            curve(to: end, controlPoint1: startControl, controlPoint2: endControl)
        } else {
            line(to: bottomLeft)
        }
        
        if let radius = topLeftRadius {
            var start = topLeft
            start.y += radius
            
            var end = topLeft
            end.x += radius
            
            var startControl = start
            startControl.y -= radius * radiusFactor
            
            var endControl = end
            endControl.x -= radius * radiusFactor
            line(to: start)
            curve(to: end, controlPoint1: startControl, controlPoint2: endControl)
            
        } else {
            line(to: topLeft)
        }
        close()
    }
}
