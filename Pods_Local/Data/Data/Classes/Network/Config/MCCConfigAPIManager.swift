//
//  MCCConfigAPIManager.swift
//

import Combine
import Moya

///
public final class MCCConfigAPIManager {
    ///
    public static let shared: MCCConfigAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.configProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCConfigAPIManager {
    ///
    public func appConfig() -> AnyPublisher<MCSConfigAppResponse, MCENetworkError> {
        networkManager.request(.appConfig)
    }
    ///
    public func toolsConfig() -> AnyPublisher<MCSList<MCSConfigToolsGroup>, MCENetworkError> {
        networkManager.request(.toolsConfig)
    }
    ///
    public func creatConfig(with requestModel: MCSConfigCreateRequest) -> AnyPublisher<MCSTemplateItem, MCENetworkError> {
        networkManager.request(.creatConfig(requestModel))
    }
    ///
    public func ossstsConfig(with requestModel: MCSConfigOssstsRequest) -> AnyPublisher<MCSConfigOssstsResponse, MCENetworkError> {
        networkManager.request(.ossstsConfig(requestModel))
    }
    ///
    public func fileUpload(with imageData: Data) -> AnyPublisher<MCSConfigFileUploadResponse, MCENetworkError> {
        networkManager.request(.fileUpload(imageData))
    }
}
