//
//  MCCRunAPIManager.swift
//

import Combine
import Moya

///
public final class MCCRunAPIManager {
    ///
    public static let shared: MCCRunAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.runProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCRunAPIManager {
    ///
    public func composeSeed(with requestModel: MCSRunCreateRequest) -> AnyPublisher<MCSRunItem, MCENetworkError> {
        networkManager.request(.composeSeed(requestModel))
    }
    ///
    public func inventory(with requestModel: MCSRunListRequest) -> AnyPublisher<MCSList<MCSRunItem>, MCENetworkError> {
        networkManager.request(.inventory(requestModel))
    }
    ///
    public func aggregate(with requestModel: MCSRunInfosRequest) -> AnyPublisher<MCSList<MCSRunItem>, MCENetworkError> {
        networkManager.request(.aggregate(requestModel))
    }
    ///
    public func detail(with requestModel: MCSRunInfoRequest) -> AnyPublisher<MCSRunItem, MCENetworkError> {
        networkManager.request(.detail(requestModel))
    }
    ///
    public func retire(with requestModel: MCSRunDeleteRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.retire(requestModel))
    }
}
