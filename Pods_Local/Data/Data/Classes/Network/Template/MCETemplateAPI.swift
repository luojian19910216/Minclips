//
//  MCETemplateAPI.swift
//

import Alamofire
import Moya

public enum MCETemplateAPI {
    /// /customTemplate/labelList
    case customLabels
    /// /customTemplate/list
    case customItems(_ requestModel: MCSTemplateListRequest)
    /// /template/searchKeywords
    case discoverLexicon
    /// /template/search
    case discoverSearch(_ requestModel: MCSTemplateListRequest)
    /// /template/viewHistory
    case discoverFootprints(_ requestModel: MCSTemplateListRequest)
    /// /template/detail
    case itemProfile(_ requestModel: MCSTemplateDetailRequest)
    /// /template/report
    case itemReport(_ requestModel: MCSTemplateReportRequest)
    /// /like/like
    case favorApply(_ requestModel: MCSTemplateDetailRequest)
    /// /like/disLike
    case favorCancel(_ requestModel: MCSTemplateDetailRequest)
    /// /like/likeList
    case favorInventory(_ requestModel: MCSTemplateLikeListRequest)
    /// /template/expose
    case discoverImpress(_ requestModel: MCSTemplateExposeRequest)
}

///
extension MCETemplateAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.baseAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .customLabels: return "/gwx/v1/feed/custom/labels"
        case .customItems: return "/gwx/v1/feed/custom/items"
        case .discoverLexicon: return "/gwx/v1/feed/discover/lexicon"
        case .discoverSearch: return "/gwx/v1/feed/discover/search"
        case .discoverFootprints: return "/gwx/v1/feed/discover/footprints"
        case .itemProfile: return "/gwx/v1/feed/item/profile"
        case .itemReport: return "/gwx/v1/feed/item/report"
        case .favorApply: return "/gwx/v1/engage/favor/apply"
        case .favorCancel: return "/gwx/v1/engage/favor/cancel"
        case .favorInventory: return "/gwx/v1/engage/favor/inventory"
        case .discoverImpress: return "/gwx/v1/feed/discover/impress"
        }
    }
    ///
    public var method: Moya.Method {
        return .post
    }
    ///
    public var task: Task {
        var parameters: [String: Any]?
        switch self {
        case .customLabels: break
        case .customItems(let requestModel): parameters = requestModel.toDictionary()
        case .discoverLexicon: break
        case .discoverSearch(let requestModel): parameters = requestModel.toDictionary()
        case .discoverFootprints(let requestModel): parameters = requestModel.toDictionary()
        case .itemProfile(let requestModel): parameters = requestModel.toDictionary()
        case .itemReport(let requestModel): parameters = requestModel.toDictionary()
        case .favorApply(let requestModel): parameters = requestModel.toDictionary()
        case .favorCancel(let requestModel): parameters = requestModel.toDictionary()
        case .favorInventory(let requestModel): parameters = requestModel.toDictionary()
        case .discoverImpress(let requestModel): parameters = requestModel.toDictionary()
        }
        return .requestParameters(parameters: parameters ?? [:], encoding: encoding)
    }
    ///
    public var encoding: Alamofire.ParameterEncoding {
        return JSONEncoding.default
    }
    ///
    public var headers: [String : String]? {
        return MCCNetworkConfig.shared.defaultHeader
    }
}

extension MCETemplateAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        return .custom("")
    }
}
