//
//  MCEUmAPI.swift
//

import Alamofire
import Moya

///
public enum MCEUmAPI {
    /// /user/login
    case identityEstablish
    /// /user/refresh
    case credentialRenew(_ requestModel: MCSUmCredentialRenewRequest)
    /// /user/integral/query
    case integralStatement
    /// /user/update
    case profilePatch(_ requestModel: MCSUmProfilePatchRequest)
    /// /user/bindEmail/sendCode
    case mailOtpDispatch(_ requestModel: MCSUmMailOtpDispatchRequest)
    /// /user/bindEmail
    case mailAttachConfirm(_ requestModel: MCSUmMailAttachConfirmRequest)
    /// /user/suggest/add
    case feedbackAppend(_ requestModel: MCSUmFeedbackAppendRequest)
    /// /user/deleteAccount
    case safetyRetire(_ requestModel: MCSUmSafetyRetireRequest)
}

extension MCEUmAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.baseAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .identityEstablish: return "/gwx/v1/um/identity/establish"
        case .credentialRenew: return "/gwx/v1/um/credential/renew"
        case .integralStatement: return "/gwx/v1/um/integral/statement"
        case .profilePatch: return "/gwx/v1/um/profile/patch"
        case .mailOtpDispatch: return "/gwx/v1/um/mail/otp/dispatch"
        case .mailAttachConfirm: return "/gwx/v1/um/mail/attach/confirm"
        case .feedbackAppend: return "/gwx/v1/um/feedback/append"
        case .safetyRetire: return "/gwx/v1/um/safety/retire"
        }
    }
    ///
    public var method: Moya.Method {
        switch self {
        case .profilePatch: return .patch
        default: return .post
        }
    }
    ///
    public var task: Task {
        var parameters: [String: Any]?
        switch self {
        case .identityEstablish: break
        case .credentialRenew(let requestModel): parameters = requestModel.toDictionary()
        case .integralStatement: break
        case .profilePatch(let requestModel): parameters = requestModel.toDictionary()
        case .mailOtpDispatch(let requestModel): parameters = requestModel.toDictionary()
        case .mailAttachConfirm(let requestModel): parameters = requestModel.toDictionary()
        case .feedbackAppend(let requestModel): parameters = requestModel.toDictionary()
        case .safetyRetire(let requestModel): parameters = requestModel.toDictionary()
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

extension MCEUmAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        if case .identityEstablish = self { return nil }
        return .custom("")
    }
}
