//
//  MCEUserAPI.swift
//

import Alamofire
import Moya

///
public enum MCEUserAPI {
    ///
    case login(_ requestModel: MCSUserLoginRequest)
    ///
    case refresh(_ requestModel: MCSUserRefreshRequest)
    ///
    case integralQuery
    ///
    case update(_ requestModel: MCSUserUpdateRequest)
    ///
    case bindEmailSendCode(_ requestModel: MCSUserBindEmailSendCodeRequest)
    ///
    case bindEmail(_ requestModel: MCSUserBindEmailRequest)
    ///
    case suggestAdd(_ requestModel: MCSUserSuggestAddRequest)
    ///
    case deleteAccount(_ requestModel: MCSUserDeleteAccountRequest)
}

extension MCEUserAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.baseAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .login: return "/user/login"
        case .refresh: return "/user/refresh"
        case .integralQuery: return "/user/integral/query"
        case .update: return "/user/update"
        case .bindEmailSendCode: return "/user/bindEmail/sendCode"
        case .bindEmail: return "/user/bindEmail"
        case .suggestAdd: return "/user/suggest/add"
        case .deleteAccount: return "/user/deleteAccount"
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
        case .login(let requestModel): parameters = requestModel.toDictionary()
        case .refresh(let requestModel): parameters = requestModel.toDictionary()
        case .integralQuery: break
        case .update(let requestModel): parameters = requestModel.toDictionary()
        case .bindEmailSendCode(let requestModel): parameters = requestModel.toDictionary()
        case .bindEmail(let requestModel): parameters = requestModel.toDictionary()
        case .suggestAdd(let requestModel): parameters = requestModel.toDictionary()
        case .deleteAccount(let requestModel): parameters = requestModel.toDictionary()
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

extension MCEUserAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        if case .login = self { return nil }
        return .custom("")
    }
}
