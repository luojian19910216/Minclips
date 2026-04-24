//
//  MCCKeychainManager.swift
//

import UIKit
import KeychainAccess

///
private enum MCEKeychainConfig {
    ///
    static let service = "com.minclips.keychain"
    ///
    static let deviceId = "device_id"
}

///
public final class MCCKeychainManager {
    ///
    public static let shared = MCCKeychainManager()
    ///
    private let keychain = Keychain(service: MCEKeychainConfig.service)
    ///
    private init() {}
    ///
    public func get(_ key: String) -> String? {
        try? keychain.get(key)
    }
    ///
    public func set(_ value: String, forKey key: String) {
        try? keychain.set(value, key: key)
    }
    ///
    public func remove(_ key: String) {
        try? keychain.remove(key)
    }
    ///
    public var deviceId: String {
        if let id = get(MCEKeychainConfig.deviceId), !id.isEmpty {
            return id
        }
        let newId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        set(newId, forKey: MCEKeychainConfig.deviceId)
        return newId
    }
}
