//
//  MCCFeedAPIManager.swift
//

import Combine
import Moya

///
public final class MCCFeedAPIManager {
    ///
    public static let shared: MCCFeedAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.feedProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCFeedAPIManager {
    ///
    public func customLabels() -> AnyPublisher<MCSList<MCSFeedLabelItem>, MCENetworkError> {
        networkManager.request(.customLabels)
    }
    ///
    public func customItems(with requestModel: MCSFeedListRequest) -> AnyPublisher<MCSList<MCSFeedItem>, MCENetworkError> {
        networkManager.request(.customItems(requestModel))
    }
    ///
    public func discoverLexicon() -> AnyPublisher<[String], MCENetworkError> {
        networkManager.request(.discoverLexicon)
    }
    ///
    public func discoverSearch(with requestModel: MCSFeedListRequest) -> AnyPublisher<MCSFeedSearchResponse, MCENetworkError> {
        networkManager.request(.discoverSearch(requestModel))
    }
    ///
    public func discoverFootprints(with requestModel: MCSFeedListRequest) -> AnyPublisher<MCSList<MCSFeedItem>, MCENetworkError> {
        networkManager.request(.discoverFootprints(requestModel))
    }
    ///
    public func itemProfile(with requestModel: MCSFeedDetailRequest) -> AnyPublisher<MCSFeedItem, MCENetworkError> {
        networkManager.request(.itemProfile(requestModel))
    }
    ///
    public func itemReport(with requestModel: MCSFeedReportRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.itemReport(requestModel))
    }
    ///
    public func favorApply(with requestModel: MCSFeedDetailRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.favorApply(requestModel))
    }
    ///
    public func favorCancel(with requestModel: MCSFeedDetailRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.favorCancel(requestModel))
    }
    ///
    public func favorInventory(with requestModel: MCSFeedLikeListRequest) -> AnyPublisher<MCSList<MCSFeedItem>, MCENetworkError> {
        networkManager.request(.favorInventory(requestModel))
    }
    ///
    public func discoverImpress(with requestModel: MCSFeedExposeRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.discoverImpress(requestModel))
    }
}
