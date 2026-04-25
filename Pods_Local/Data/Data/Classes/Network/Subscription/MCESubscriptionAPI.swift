//
//  MCESubscriptionAPI.swift
//

import Alamofire
import Moya

///
public enum MCESubscriptionAPI {
    /// findAll /product/subscription/find/allV2
    case subscriptionCatalog
    /// payCallback /pay/callbackV2
    case billingNotify(_ request: MCSSubscriptionBillingRequest)
    /// paySinglePurchase /mock/pay/single/purchase
    case billingOnce(_ request: MCSSubscriptionBillingRequest)
}

extension MCESubscriptionAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.baseAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .subscriptionCatalog: return "/gwx/v1/shop/subscription/catalog"
        case .billingNotify: return "/gwx/v1/shop/billing/notify"
        case .billingOnce: return "/gwx/v1/shop/billing/once"
        }
    }
    ///
    public var method: Moya.Method {
        return .post
    }
    ///
    public var task: Task {
        switch self {
        case .subscriptionCatalog:
            return .requestPlain
        case .billingNotify(let request), .billingOnce(let request):
            return .requestParameters(parameters: request.toDictionary() ?? [:], encoding: encoding)
        }
    }
    ///
    public var encoding: Alamofire.ParameterEncoding {
        return JSONEncoding.default
    }
    ///
    public var headers: [String: String]? {
        return MCCNetworkConfig.shared.defaultHeader
    }
}

extension MCESubscriptionAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        return .custom("")
    }
}
