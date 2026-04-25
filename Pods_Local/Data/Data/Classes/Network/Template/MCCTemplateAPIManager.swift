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
    public func customLabelList() -> AnyPublisher<MCSList<MCSTemplateLabelItem>, MCENetworkError> {
        networkManager.request(.customLabels)
    }
    ///
    public func customList(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.customItems(requestModel))
    }
    ///
    public func searchKeywords() -> AnyPublisher<[String], MCENetworkError> {
        networkManager.request(.discoverLexicon)
    }
    ///
    public func search(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSTemplateSearchResponse, MCENetworkError> {
        networkManager.request(.discoverSearch(requestModel))
    }
    ///
    public func viewHistory(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.discoverFootprints(requestModel))
    }
    ///
    public func detail(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSTemplateItem, MCENetworkError> {
        networkManager.request(.itemProfile(requestModel))
    }
    ///
    public func report(with requestModel: MCSTemplateReportRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.itemReport(requestModel))
    }
    ///
    public func like(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.favorApply(requestModel))
    }
    ///
    public func dislike(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.favorCancel(requestModel))
    }
    ///
    public func likeList(with requestModel: MCSTemplateLikeListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.favorInventory(requestModel))
    }
    ///
    public func expose(with requestModel: MCSTemplateExposeRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.discoverImpress(requestModel))
    }
}
