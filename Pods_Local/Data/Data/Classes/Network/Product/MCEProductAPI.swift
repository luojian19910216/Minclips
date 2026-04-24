//
//  MCEProductAPI.swift
//

import Alamofire
import Moya

///
public enum MCEProductAPI {
    ///
    case findAll
    ///
    case payCallback(_ requestModel: MCSProductPayCallbackRequest)
    ///
    case paySinglePurchase(_ requestModel: MCSProductPayCallbackRequest)
}

extension MCEProductAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.baseAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .findAll: return "/product/subscription/find/allV2"
        case .payCallback: return "/pay/callbackV2"
        case .paySinglePurchase: return "/pay/single/purchase"
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
        case .findAll: break
        case .payCallback(let requestModel): parameters = requestModel.toDictionary()
        case .paySinglePurchase(let requestModel): parameters = requestModel.toDictionary()
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

extension MCEProductAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        return .custom("")
    }
}
