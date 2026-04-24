//
//  MCEConfigAPI.swift
//

import Alamofire
import Moya

///
public enum MCEConfigAPI {
    ///
    case appConfig
    ///
    case toolsConfig
    ///
    case creatConfig(_ requestModel: MCSConfigCreateRequest)
    ///
    case ossstsConfig(_ requestModel: MCSConfigOssstsRequest)
    ///
    case fileUpload(_ imageData: Data)
}

extension MCEConfigAPI: TargetType {
    ///
    public var baseURL: URL {
        return URL(string: MCCNetworkConfig.shared.environment.baseAPIUrl)!
    }
    ///
    public var path: String {
        switch self {
        case .appConfig: return "/config/appConfig"
        case .toolsConfig: return "/config/tools"
        case .creatConfig: return "/config/creatConfig"
        case .ossstsConfig: return "/oss/sts"
        case .fileUpload: return "/file/upload"
        }
    }
    ///
    public var method: Moya.Method {
        return .post
    }
    ///
    public var task: Task {
        if case .fileUpload(let imageData) = self {
            let formData = MultipartFormData(
                provider: .data(imageData),
                name: "file",
                fileName: "image.png",
                mimeType: "image/png"
            )
            return .uploadMultipart([formData])
        }
        var parameters: [String: Any]?
        switch self {
        case .appConfig: break
        case .toolsConfig: break
        case .creatConfig(let requestModel): parameters = requestModel.toDictionary()
        case .ossstsConfig(let requestModel): parameters = requestModel.toDictionary()
        case .fileUpload: break
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

extension MCEConfigAPI: AccessTokenAuthorizable {
    ///
    public var authorizationType: AuthorizationType? {
        return .custom("")
    }
}
