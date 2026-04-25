//
//  MCEProductAPI.swift
//

import Alamofire
import Moya

///
public enum MCEProductAPI {
    /// /product/subscription/find/allV2
    case findAll
    /// /pay/callbackV2
    case payCallback(_ requestModel: MCSProductPayCallbackRequest)
    /// /mock/pay/single/purchase
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
        case .findAll: return "/gwx/v1/shop/offer/selection"
        case .payCallback: return "/gwx/v1/shop/billing/notify"
        case .paySinglePurchase: return "/gwx/v1/shop/billing/once"
        }
    }
    ///
    public var method: Moya.Method {
        return .post
    }
    ///
    public var task: Task {
        switch self {
        case .findAll:
            return .requestPlain
        case .payCallback(let requestModel), .paySinglePurchase(let requestModel):
            return .requestParameters(parameters: requestModel.toDictionary() ?? [:], encoding: encoding)
        }
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
