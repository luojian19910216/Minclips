//
//  MCCLanguageTool.swift
//

import Foundation
import Combine

extension Notification.Name {
    public static let languageUpdated = Notification.Name("com.minclips.locale.changed")
}

public struct MCSLanguage: Codable {
    public var name: String = ""
    public var code: String = ""
    public var codeToService: String = ""
}

public extension MCSLanguage {
    static let en = MCSLanguage(name: "English", code: "en", codeToService: "en_US")
}

public class MCCLanguageTool: NSObject {

    public static let shared: MCCLanguageTool = .init()

    public static var languages: [MCSLanguage] = [.en]

    public static var defaultLanguage: MCSLanguage = .en

    @Published public private(set) var currentLanguage: MCSLanguage

    override init() {
        if let code = UserDefaults.standard.string(forKey: "com.minclips.locale.code"),
           let language = Self.languages.first(where: { $0.code == code }) {
            currentLanguage = language
        } else if let localeLanguage = Locale.preferredLanguages.first,
                  let language = Self.languages.first(where: { localeLanguage.hasPrefix($0.code) }) {
            currentLanguage = language
        } else {
            currentLanguage = Self.defaultLanguage
        }
        super.init()
    }

    public func changeLanguage(with language: MCSLanguage) {
        guard currentLanguage.code != language.code else { return }
        currentLanguage = language
        NotificationCenter.default.post(name: .languageUpdated, object: nil)
        UserDefaults.standard.set(language.code, forKey: "com.minclips.locale.code")
    }

}
