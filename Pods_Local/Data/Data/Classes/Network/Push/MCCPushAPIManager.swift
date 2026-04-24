//
//  MCCPushAPIManager.swift
//

import Combine
import Moya

///
public final class MCCPushAPIManager {
    ///
    public static let shared: MCCPushAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.pushProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCPushAPIManager {
    ///
    public func register(with requestModel: MCSPushRegisterRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.register(requestModel))
    }
}
