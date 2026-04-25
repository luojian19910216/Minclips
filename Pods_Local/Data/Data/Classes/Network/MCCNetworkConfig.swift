//
//  MCCNetworkConfig.swift
//

import Foundation
import UIKit
import DeviceKit

///
public enum MCEChannel: Int {
    ///
    case develop
    ///
    case isolation
    ///
    public static var current: MCEChannel {
#if ENV_D
        return .develop
#else
        return .isolation
#endif
    }
}

///
public enum MCEEnvironment {
    ///
    case D
    ///
    case T
    ///
    case P
    ///
    case R
    ///
    public static var current: MCEEnvironment {
#if ENV_D
        return .D
#elseif ENV_T
        return .T
#elseif ENV_P
        return .P
#else
        return .R
#endif
    }
    ///
    public var baseAPIUrl: String {
        switch self {
        case .D: return "https://gw-rd.minclips.video"
        case .T: return "https://gw-rd.minclips.video"
        case .P: return "https://gw-rd.minclips.video"
        case .R: return "https://gw.minclips.video"
        }
    }
    ///
    public var pushAPIUrl: String {
        switch self {
        case .D: return "https://push-rd.minclips.video"
        case .T: return "https://push-rd.minclips.video"
        case .P: return "https://push.minclips.video"
        case .R: return "https://push.minclips.video"
        }
    }
    ///
    public var isDevelopment: Bool {
#if ENV_D || ENV_T
        return true
#else
        return false
#endif
    }
}

///
public final class MCCNetworkConfig {
    ///
    public static let shared: MCCNetworkConfig = .init()
    ///
    public var channel: MCEChannel = .current
    ///
    public var environment: MCEEnvironment = .current
    ///
    private init() {}
    ///
    public func start(with channel: MCEChannel, environment: MCEEnvironment) {
        self.channel = channel
        self.environment = environment
    }
    ///
    public lazy var defaultHeader: [String: String] = [
        "X-Mnc-Platform": Self.platform,
        "X-Mnc-Client-Version": Self.appShortVersion,
        "X-Mnc-Device-Id": MCCKeychainManager.shared.deviceId,
        "X-Mnc-Platform-Version": Self.platformVersion,
        "X-Mnc-Platform-Model": Self.platformModel,
        "X-Mnc-Platform-Brand": Self.platformBrand,
        "X-Mnc-Bundle": Self.appBundleId,
        "X-Mnc-Network-Type": "--",
        "X-Mnc-Utm-Source": "Apple",
        "X-Mnc-Zone": Self.timeZone.urlEncoded,
        "X-Mnc-Language": "en",
        "X-Mnc-Carrier": "--",
        "X-Mnc-Webview-Ua": "",
        "X-Mnc-App-Name": Self.appName.lowercased(),
        "X-Te-Device-Id": MCCKeychainManager.shared.deviceId,
        "X-Te-Distinct-Id": MCCKeychainManager.shared.deviceId,
        "Content-Type": "application/json"
    ]
    ///
    public static var platform: String = "iOS"
    ///
    public static var platformBrand: String {
        let device = Device.current.realDevice
        if device.isPhone { return "iPhone" }
        if device.isPad   { return "iPad"   }
        if device.isPod   { return "iPod touch" }
        return "iPhone"
    }
    ///
    public static var platformModel: String {
        Device.current.safeDescription
    }
    ///
    public static var platformVersion: String {
        UIDevice.current.systemName + " " + UIDevice.current.systemVersion
    }
    ///
    public static var timeZone: String {
        let seconds = TimeZone.current.secondsFromGMT()
        let hours = seconds / 3600
        let minutes = abs(seconds / 60) % 60
        let sign = seconds >= 0 ? "+" : "-"
        return String(format: "GMT%@%02d:%02d", sign, abs(hours), minutes)
    }
    ///
    public static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? ""
    }
    ///
    public static var appBundleId: String {
        Bundle.main.bundleIdentifier ?? ""
    }
    ///
    public static var appShortVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
    ///
    public static var appBuildVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }
}

extension String {
    ///
    var urlEncoded: String {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.~")
        return addingPercentEncoding(withAllowedCharacters: allowed) ?? self
    }
}
