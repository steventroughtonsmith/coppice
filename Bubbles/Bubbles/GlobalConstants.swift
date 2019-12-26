//
//  GlobalConstants.swift
//  Bubbles
//
//  Created by Martin Pilkington on 14/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

struct GlobalConstants {
    static let urlScheme = "bubbles"

    static let appErrorDomain = "com.mcubedsw.Bubbles"

    enum ErrorCodes: Int {
        case readingDocumentFailed = 1
    }

    static let minimumPageSize = CGSize(width: 150, height: 100)
    static let linkedPageOffset: CGFloat = 40.0


}

enum UserDefaultsKeys: String {
    case debugShowCanvasOrigin
}
