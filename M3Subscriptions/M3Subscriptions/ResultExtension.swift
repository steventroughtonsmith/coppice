//
//  ResultExtension.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension Result where Success == Void {
    public static var success: Result<Success, Failure> { .success(()) }
}
