//
//  NSObject+M3Extensions.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 21/12/2023.
//

import Combine
import Foundation

extension _KeyValueCodingAndObserving {
    public func notifyOfChange<T>(to keyPath: KeyPath<Self, T>) {
        self.willChangeValue(for: keyPath)
        self.didChangeValue(for: keyPath)
    }
}

extension Publisher where Failure == Never {
    public func notify<Object: NSObject, T>(_ object: Object, ofChangeTo keyPath: KeyPath<Object, T>) -> AnyCancellable {
        return self.sink { [weak object] _ in
            object?.notifyOfChange(to: keyPath)
        }
    }
}
