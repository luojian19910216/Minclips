//
//  MCCCfAPIManager.swift
//

import Combine
import Moya

///
public final class MCCCfAPIManager {
    ///
    public static let shared: MCCCfAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.cfProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCCfAPIManager {
    ///
    public func launcher() -> AnyPublisher<MCSCfLauncherResponse, MCENetworkError> {
        networkManager.request(.launcher)
    }
    ///
    public func studioToolbox() -> AnyPublisher<MCSList<MCSCfToolboxGroup>, MCENetworkError> {
        networkManager.request(.studioToolbox)
    }
    ///
    public func creationLegacy(with requestModel: MCSCfCreationLegacyRequest) -> AnyPublisher<MCSFeedItem, MCENetworkError> {
        networkManager.request(.creationLegacy(requestModel))
    }
    ///
    public func creationModern() -> AnyPublisher<MCSFeedItem, MCENetworkError> {
        networkManager.request(.creationModern)
    }
    ///
    public func ossToken(with requestModel: MCSCfOssTokenRequest) -> AnyPublisher<MCSCfOssTokenResponse, MCENetworkError> {
        networkManager.request(.ossToken(requestModel))
    }
    ///
    public func cdnObject(with imageData: Data) -> AnyPublisher<MCSCfCdnObjectResponse, MCENetworkError> {
        networkManager.request(.cdnObject(imageData))
    }
}
