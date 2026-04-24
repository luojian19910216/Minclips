//
//  MCETemplateAPI.swift
//

import Alamofire
import Moya

///
public enum MCETemplateAPI {
    ///
    case pageHome(_ requestModel: MCSTemplateListRequest)
    ///
    case customLabelList
    ///
    case customList(_ requestModel: MCSTemplateListRequest)
    ///
    case searchKeywords
    ///
    case search(_ requestModel: MCSTemplateListRequest)
    ///
    case viewHistory(_ requestModel: MCSTemplateListRequest)
    ///
    case usedByWorks(_ requestModel: MCSTemplateListRequest)
    /// 非会员&成功作品的推荐
    case proList(_ requestModel: MCSTemplateDetailRequest)
    /// 生成中/失败作品的推荐
    case inspirationList(_ requestModel: MCSTemplateDetailRequest)
    ///
    case detail(_ requestModel: MCSTemplateDetailRequest)
    ///
    case report(_ requestModel: MCSTemplateReportRequest)
    ///
    case like(_ requestModel: MCSTemplateDetailRequest)
    ///
    case dislike(_ requestModel: MCSTemplateDetailRequest)
    ///
    case likeList(_ requestModel: MCSTemplateLikeListRequest)
    ///
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
        case .pageHome: return "/template/pageHome"
        case .customLabelList: return "/customTemplate/labelList"
        case .customList: return "/customTemplate/list"
        case .searchKeywords: return "/template/searchKeywords"
        case .search: return "/template/search"
        case .viewHistory: return "/template/viewHistory"
        case .usedByWorks: return "/template/usedByWorks"
        case .proList: return "/template/proList"
        case .inspirationList: return "/template/inspiration"
        case .detail: return "/template/detail"
        case .report: return "/template/report"
        case .like: return "/like/like"
        case .dislike: return "/like/disLike"
        case .likeList: return "/like/likeList"
        case .expose: return "/template/expose"
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
        case .pageHome(let requestModel): parameters = requestModel.toDictionary()
        case .customLabelList: break
        case .customList(let requestModel): parameters = requestModel.toDictionary()
        case .searchKeywords: break
        case .search(let requestModel): parameters = requestModel.toDictionary()
        case .viewHistory(let requestModel): parameters = requestModel.toDictionary()
        case .usedByWorks(let requestModel): parameters = requestModel.toDictionary()
        case .proList(let requestModel): parameters = requestModel.toDictionary()
        case .inspirationList(let requestModel): parameters = requestModel.toDictionary()
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
