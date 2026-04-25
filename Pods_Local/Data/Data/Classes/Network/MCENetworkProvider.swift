//
//  MCENetworkProvider.swift
//

import Foundation
import Alamofire
import Moya
import Combine

///
enum MCENetworkProvider {
    ///
    private static func makeSession() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 30
        return Session(configuration: configuration)
    }
    ///
    private static func makePlugins(enableLogger: Bool = true) -> [PluginType] {
        var plugins: [PluginType] = [
            MCSCustomAccessTokenPlugin(tokenClosure: { _ in
                MCCAccountService.shared.currentUser.value?.authToken ?? ""
            })
        ]
        if enableLogger {
            plugins.append(MCCLoggerPlugin())
        }
        return plugins
    }
    ///
    private static func makeProvider<T: TargetType>(_ type: T.Type, enableLogger: Bool = true) -> MoyaProvider<T> {
        MoyaProvider<T>(session: makeSession(), plugins: makePlugins(enableLogger: enableLogger))
    }
    ///
    static let umProvider = makeProvider(MCEUmAPI.self)
    ///
    static let templateProvider = makeProvider(MCETemplateAPI.self)
    ///
    static let workProvider = makeProvider(MCEWorkAPI.self)
    ///
    static let productProvider = makeProvider(MCEProductAPI.self)
    ///
    static let pushProvider = makeProvider(MCEPushAPI.self)
    ///
    static let cfProvider = makeProvider(MCECfAPI.self)
}
