//
//  MCCSubscriptionAPIManager.swift
//

import Combine
import Moya

///
public final class MCCSubscriptionAPIManager {
    ///
    public static let shared: MCCSubscriptionAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.subscriptionProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCSubscriptionAPIManager {
    ///
    public func fetchSubscriptionCatalog() -> AnyPublisher<MCSSubscriptionCatalogResponse, MCENetworkError> {
        networkManager.request(.subscriptionCatalog)
    }
    ///
    public func billingNotify(with request: MCSSubscriptionBillingRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.billingNotify(request))
    }
    ///
    public func billingOnce(with request: MCSSubscriptionBillingRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.billingOnce(request))
    }
}
