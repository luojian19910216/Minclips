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
    public func pageHome(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.pageHome(requestModel))
    }
    ///
    public func customLabelList() -> AnyPublisher<MCSList<MCSTemplateLabelItem>, MCENetworkError> {
        networkManager.request(.customLabelList)
    }
    ///
    public func customList(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.customList(requestModel))
    }
    ///
    public func searchKeywords() -> AnyPublisher<[String], MCENetworkError> {
        networkManager.request(.searchKeywords)
    }
    ///
    public func search(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSTemplateSearchResponse, MCENetworkError> {
        networkManager.request(.search(requestModel))
    }
    ///
    public func viewHistory(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.viewHistory(requestModel))
    }
    ///
    public func usedByWorks(with requestModel: MCSTemplateListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.usedByWorks(requestModel))
    }
    ///
    public func proList(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.proList(requestModel))
    }
    ///
    public func inspirationList(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.inspirationList(requestModel))
    }
    ///
    public func detail(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSTemplateItem, MCENetworkError> {
        networkManager.request(.detail(requestModel))
    }
    ///
    public func report(with requestModel: MCSTemplateReportRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.report(requestModel))
    }
    ///
    public func like(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.like(requestModel))
    }
    ///
    public func dislike(with requestModel: MCSTemplateDetailRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.dislike(requestModel))
    }
    ///
    public func likeList(with requestModel: MCSTemplateLikeListRequest) -> AnyPublisher<MCSList<MCSTemplateItem>, MCENetworkError> {
        networkManager.request(.likeList(requestModel))
    }
    ///
    public func expose(with requestModel: MCSTemplateExposeRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.expose(requestModel))
    }
}
