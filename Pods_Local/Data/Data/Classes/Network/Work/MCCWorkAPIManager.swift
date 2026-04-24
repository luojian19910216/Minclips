//
//  MCCWorkAPIManager.swift
//

import Combine
import Moya

///
public final class MCCWorkAPIManager {
    ///
    public static let shared: MCCWorkAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.workProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCWorkAPIManager {
    ///
    public func create(with requestModel: MCSWorkCreateRequest) -> AnyPublisher<MCSWorkItem, MCENetworkError> {
        networkManager.request(.create(requestModel))
    }
    ///
    public func list(with requestModel: MCSWorkListRequest) -> AnyPublisher<MCSList<MCSWorkItem>, MCENetworkError> {
        networkManager.request(.list(requestModel))
    }
    ///
    public func infos(with requestModel: MCSWorkInfosRequest) -> AnyPublisher<MCSList<MCSWorkItem>, MCENetworkError> {
        networkManager.request(.infos(requestModel))
    }
    ///
    public func info(with requestModel: MCSWorkInfoRequest) -> AnyPublisher<MCSWorkItem, MCENetworkError> {
        networkManager.request(.info(requestModel))
    }
    ///
    public func delete(with requestModel: MCSWorkDeleteRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.delete(requestModel))
    }
}
