//
//  MCEWorkAPI.swift
//

import Alamofire
import Moya

///
public enum MCEWorkAPI {
    ///
    case create(_ requestModel: MCSWorkCreateRequest)
    ///
    case list(_ requestModel: MCSWorkListRequest)
    ///
    case infos(_ requestModel: MCSWorkInfosRequest)
    ///
    case info(_ requestModel: MCSWorkInfoRequest)
    ///
    case delete(_ requestModel: MCSWorkDeleteRequest)
}

extension MCEWorkAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.baseAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .create: return "/work/createV2"
        case .list: return "/work/list"
        case .infos: return "/work/infos"
        case .info: return "/work/info"
        case .delete: return "/work/delete"
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
        case .create(let requestModel): parameters = requestModel.toDictionary()
        case .list(let requestModel): parameters = requestModel.toDictionary()
        case .infos(let requestModel): parameters = requestModel.toDictionary()
        case .info(let requestModel): parameters = requestModel.toDictionary()
        case .delete(let requestModel): parameters = requestModel.toDictionary()
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

extension MCEWorkAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        return .custom("")
    }
}
