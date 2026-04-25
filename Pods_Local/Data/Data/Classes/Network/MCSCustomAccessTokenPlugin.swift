//
//  MCSCustomAccessTokenPlugin.swift
//

import Foundation
import Moya

///
public struct MCSCustomAccessTokenPlugin: PluginType {
    ///
    public typealias TokenClosure = (TargetType) -> String
    ///
    public let tokenClosure: TokenClosure
    ///
    public init(tokenClosure: @escaping TokenClosure) {
        self.tokenClosure = tokenClosure
    }
    ///
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard
            let authorizable = target as? AccessTokenAuthorizable,
            let authorizationType = authorizable.authorizationType
        else { return request }
        let realTarget = (target as? MultiTarget)?.target ?? target
        let authValue = [authorizationType.value, tokenClosure(realTarget)].filter {!$0.isEmpty}.joined(separator: " ")
        guard !authValue.isEmpty else { return request }
        var request = request
        request.addValue(authValue, forHTTPHeaderField: "X-Mnc-Access-Token")
        return request
    }
}
