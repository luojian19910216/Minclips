//
//  MCSLoadState.swift
//

import Foundation
import Combine
import Data

///
public struct MCSLoadState<T> {
    ///
    var isLoading: Bool = false
    ///
    var error: MCENetworkError?
    ///
    var model: T?
    ///
    public init(isLoading: Bool = false, error: MCENetworkError? = nil, model: T? = nil) {
        self.isLoading = isLoading
        self.error = error
        self.model = model
    }
}

extension Publisher {
    ///
    public func asLoadState() -> AnyPublisher<MCSLoadState<Output>, Never> {
        self
            .map { value in
                MCSLoadState(isLoading: false, error: nil, model: value)
            }
            .catch { error in
                Just(MCSLoadState(isLoading: false, error: error as? MCENetworkError, model: nil))
            }
            .prepend(MCSLoadState(isLoading: true, error: nil, model: nil))
            .eraseToAnyPublisher()
    }
}
