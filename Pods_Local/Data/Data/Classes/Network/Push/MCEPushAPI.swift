//
//  MCEPushAPI.swift
//

import Alamofire
import Moya

///
public enum MCEPushAPI {
    ///
    case register(_ requestModel: MCSPushRegisterRequest)
}

extension MCEPushAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.pushAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .register: return "/push/register"
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
        case .register(let requestModel): parameters = requestModel.toDictionary()
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

extension MCEPushAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        return .custom("")
    }
}
