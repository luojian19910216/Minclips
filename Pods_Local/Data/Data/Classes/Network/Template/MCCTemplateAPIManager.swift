//
//  MCCTemplateAPIManager.swift
//

import Combine
import Moya

///
public final class MCCTemplateAPIManager {
    ///
    public static let shared: MCCTemplateAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.templateProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCTemplateAPIManager {
    ///
    public func customLabels() -> AnyPublisher<MCSList<MCSTemplateLabelItem>, MCENetworkError> {
        networkManager.request(.customLabels)
    }
    ///
    public func customItems(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.customItems(requestModel))
    }
    ///
    public func discoverLexicon() -> AnyPublisher<[String], MCENetworkError> {
        networkManager.request(.discoverLexicon)
    }
    ///
    public func discoverSearch(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSTemplateSearchResponse, MCENetworkError> {
        networkManager.request(.discoverSearch(requestModel))
    }
    ///
    public func discoverFootprints(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.discoverFootprints(requestModel))
    }
    ///
    public func itemProfile(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSTemplateItem, MCENetworkError> {
        networkManager.request(.itemProfile(requestModel))
    }
    ///
    public func itemReport(with requestModel: MCSTemplateReportRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.itemReport(requestModel))
    }
    ///
    public func favorApply(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.favorApply(requestModel))
    }
    ///
    public func favorCancel(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.favorCancel(requestModel))
    }
    ///
    public func favorInventory(with requestModel: MCSTemplateLikeListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.favorInventory(requestModel))
    }
    ///
    public func discoverImpress(with requestModel: MCSTemplateExposeRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.discoverImpress(requestModel))
    }
}
