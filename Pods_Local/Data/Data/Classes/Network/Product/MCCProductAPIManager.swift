//
//  MCCProductAPIManager.swift
//

import Combine
import Moya

///
public final class MCCProductAPIManager {
    ///
    public static let shared: MCCProductAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.productProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCProductAPIManager {
    ///
    public func findAll() -> AnyPublisher<MCSProductFindAllResponse, MCENetworkError> {
        networkManager.request(.findAll)
    }
    ///
    public func payCallback(with requestModel: MCSProductPayCallbackRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.payCallback(requestModel))
    }
    ///
    public func paySinglePurchase(with requestModel: MCSProductPayCallbackRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.paySinglePurchase(requestModel))
    }
}
