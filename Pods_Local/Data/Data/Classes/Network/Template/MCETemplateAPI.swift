//
//  MCETemplateAPI.swift
//

import Alamofire
import Moya

public enum MCETemplateAPI {
    /// /customTemplate/labelList
    case customLabelList
    /// /customTemplate/list
    case customList(_ requestModel: MCSTemplateListRequest)
    /// /template/searchKeywords
    case searchKeywords
    /// /template/search
    case search(_ requestModel: MCSTemplateListRequest)
    /// /template/viewHistory
    case viewHistory(_ requestModel: MCSTemplateListRequest)
    /// /template/detail
    case detail(_ requestModel: MCSTemplateDetailRequest)
    /// /template/report
    case report(_ requestModel: MCSTemplateReportRequest)
    /// /like/like
    case like(_ requestModel: MCSTemplateDetailRequest)
    /// /like/disLike
    case dislike(_ requestModel: MCSTemplateDetailRequest)
    /// /like/likeList
    case likeList(_ requestModel: MCSTemplateLikeListRequest)
    /// /template/expose
    case expose(_ requestModel: MCSTemplateExposeRequest)
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
        case .customLabelList: return "/gwx/v1/feed/custom/labels"
        case .customList: return "/gwx/v1/feed/custom/items"
        case .searchKeywords: return "/gwx/v1/feed/discover/lexicon"
        case .search: return "/gwx/v1/feed/discover/search"
        case .viewHistory: return "/gwx/v1/feed/discover/footprints"
        case .detail: return "/gwx/v1/feed/item/profile"
        case .report: return "/gwx/v1/feed/item/report"
        case .like: return "/gwx/v1/engage/favor/apply"
        case .dislike: return "/gwx/v1/engage/favor/cancel"
        case .likeList: return "/gwx/v1/engage/favor/inventory"
        case .expose: return "/gwx/v1/feed/discover/impress"
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
        case .customLabelList: break
        case .customList(let requestModel): parameters = requestModel.toDictionary()
        case .searchKeywords: break
        case .search(let requestModel): parameters = requestModel.toDictionary()
        case .viewHistory(let requestModel): parameters = requestModel.toDictionary()
        case .detail(let requestModel): parameters = requestModel.toDictionary()
        case .report(let requestModel): parameters = requestModel.toDictionary()
        case .like(let requestModel): parameters = requestModel.toDictionary()
        case .dislike(let requestModel): parameters = requestModel.toDictionary()
        case .likeList(let requestModel): parameters = requestModel.toDictionary()
        case .expose(let requestModel): parameters = requestModel.toDictionary()
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
