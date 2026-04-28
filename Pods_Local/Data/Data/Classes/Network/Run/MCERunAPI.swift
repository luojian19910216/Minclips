//
//  MCERunAPI.swift
//

import Alamofire
import Moya

///
public enum MCERunAPI {
    /// POST `/gwx/v1/runs/compose/seed`
    case composeSeed(_ requestModel: MCSComposeSeedRequest)
    /// /work/list
    case inventory(_ requestModel: MCSRunListRequest)
    /// /work/infos
    case aggregate(_ requestModel: MCSRunInfosRequest)
    /// /work/info
    case detail(_ requestModel: MCSRunInfoRequest)
    /// /work/delete
    case retire(_ requestModel: MCSRunDeleteRequest)
}

extension MCERunAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.baseAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .composeSeed: return "/gwx/v1/runs/compose/seed"
        case .inventory: return "/gwx/v1/runs/inventory"
        case .aggregate: return "/gwx/v1/runs/aggregate"
        case .detail: return "/gwx/v1/runs/detail"
        case .retire: return "/gwx/v1/runs/retire"
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
        case .composeSeed(let requestModel): parameters = requestModel.toDictionary()
        case .inventory(let requestModel): parameters = requestModel.toDictionary()
        case .aggregate(let requestModel): parameters = requestModel.toDictionary()
        case .detail(let requestModel): parameters = requestModel.toDictionary()
        case .retire(let requestModel): parameters = requestModel.toDictionary()
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

extension MCERunAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        return .custom("")
    }
}
