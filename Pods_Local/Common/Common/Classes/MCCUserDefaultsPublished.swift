//
//  MCCUserDefaultsPublished.swift
//

import Foundation
import Combine

@propertyWrapper
public final class MCCUserDefaultsPublished<Value: Codable>: ObservableObject {
    ///
    private let storage: UserDefaults
    ///
    private let key: String
    ///
    private let defaultValue: Value
    ///
    @Published public var wrappedValue: Value {
        didSet {
            save(value: wrappedValue)
        }
    }
    ///
    public var projectedValue: AnyPublisher<Value, Never> {
        $wrappedValue.eraseToAnyPublisher()
    }
    ///
    public init(storage: UserDefaults = .standard, key: String, default defaultValue: Value, ) {
        self.storage = storage
        self.key = key
        self.defaultValue = defaultValue
        if let data = storage.data(forKey: key),
           let value = try? JSONDecoder().decode(Value.self, from: data) {
            self.wrappedValue = value
        } else {
            self.wrappedValue = defaultValue
        }
    }
    ///
    private func save(value: Value) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        storage.set(data, forKey: key)
    }
}
