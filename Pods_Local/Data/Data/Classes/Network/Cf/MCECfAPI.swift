//
//  MCECfAPI.swift
//

import Alamofire
import Moya

public enum MCECfAPI {
    /// /config/appConfig
    case launcher
    /// /config/tools
    case studioToolbox
    /// /config/creatConfig
    case creationLegacy(_ requestModel: MCSCfCreationLegacyRequest)
    /// /config/creatConfigV2
    case creationModern
    /// /oss/sts
    case ossToken(_ requestModel: MCSCfOssTokenRequest)
    /// /file/upload
    case cdnObject(_ imageData: Data)
}

extension MCECfAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.baseAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .launcher: return "/gwx/v1/cf/launcher"
        case .studioToolbox: return "/gwx/v1/cf/studio/toolbox"
        case .creationLegacy: return "/gwx/v1/cf/studio/creation/legacy"
        case .creationModern: return "/gwx/v1/cf/creation/modern"
        case .ossToken: return "/gwx/v1/st/oss/token"
        case .cdnObject: return "/gwx/v1/st/cdn/object"
        }
    }
    ///
    public var method: Moya.Method {
        switch self {
        case .launcher, .studioToolbox, .creationModern: return .get
        default: return .post
        }
    }
    ///
    public var task: Task {
        if case .cdnObject(let imageData) = self {
            let formData = MultipartFormData(
                provider: .data(imageData),
                name: "file",
                fileName: "image.png",
                mimeType: "image/png"
            )
            return .uploadMultipart([formData])
        }
        if case .launcher = self {
            return .requestPlain
        }
        if case .studioToolbox = self {
            return .requestPlain
        }
        if case .creationModern = self {
            return .requestPlain
        }
        var parameters: [String: Any]?
        switch self {
        case .creationLegacy(let requestModel): parameters = requestModel.toDictionary()
        case .ossToken(let requestModel): parameters = requestModel.toDictionary()
        case .launcher, .studioToolbox, .creationModern, .cdnObject: break
        }
        return .requestParameters(parameters: parameters ?? [:], encoding: encoding)
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

extension MCECfAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        return .custom("")
    }
}
