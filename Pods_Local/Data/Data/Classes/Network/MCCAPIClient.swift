//
//  MCCAPIClient.swift
//

import Foundation
import Combine
import Moya

extension JSONDecoder {
    ///
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()
}

///
public protocol MCPAccessTokenRefreshable: AnyObject {
    ///
    func refreshToken(_ error: MCENetworkError) -> AnyPublisher<Void, MCENetworkError>
}

///
public final class MCCAPIClient<Target: TargetType> {
    ///
    private let provider: MoyaProvider<Target>
    ///
    private weak var tokenRefresher: MCPAccessTokenRefreshable?
    ///
    public init(
        provider: MoyaProvider<Target>,
        tokenRefresher: MCPAccessTokenRefreshable? = nil
    ) {
        self.provider = provider
        self.tokenRefresher = tokenRefresher
    }
    ///
    public func request<T: Decodable>(_ target: Target) -> AnyPublisher<T, MCENetworkError> {
        return self.provider.requestPublisher(target)
            .subscribe(on: DispatchQueue.global(qos: .utility))
            .tryMap { response -> Data in
                let code = response.statusCode
                if [502, 503].contains(code) {
                    throw MCENetworkError.serverMaintenance(code)
                }
                guard 200..<300 ~= code else {
                    throw MCENetworkError.invalidStatusCode(code)
                }
                return response.data
            }
            .decode(type: MCSNetworkResponse<T>.self, decoder: JSONDecoder.api)
            .tryMap { response in
                guard response.statusCode == MCENetworkCode.success.rawValue else {
                    if response.statusCode == MCENetworkCode.loginExpired.rawValue {
                        throw MCENetworkError.loginExpired
                    }
                    if response.statusCode == MCENetworkCode.tokenExpired.rawValue {
                        throw MCENetworkError.tokenExpired
                    }
                    throw MCENetworkError.serverError(code: response.statusCode, message: response.statusText)
                }
                if T.self == MCSEmpty.self {
                    return MCSEmpty() as! T
                }
                guard let data = response.payload else {
                    throw MCENetworkError.parseError("Data empty")
                }
                return data
            }
            .catch { error in
                self.retryIfNeeded(error: error, target: target)
            }
            .mapError { self.handleError($0) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    ///
    private func retryIfNeeded<T: Decodable>(error: Error, target: Target) -> AnyPublisher<T, MCENetworkError> {
        guard
            let networkError = error as? MCENetworkError,
            let refresher = tokenRefresher
        else {
            return Fail(error: handleError(error))
                .eraseToAnyPublisher()
        }
        switch networkError {
        case .tokenExpired, .loginExpired:
            return refresher.refreshToken(networkError)
                .flatMap { _ in
                    self.request(target)
                }
                .eraseToAnyPublisher()
        default:
            return Fail(error: networkError)
                .eraseToAnyPublisher()
        }
    }
    ///
    private func handleError(_ error: Error) -> MCENetworkError {
        if let networkError = error as? MCENetworkError {
            return networkError
        }
        if error is DecodingError {
            return .parseError(error.localizedDescription)
        }
        if let moyaError = error as? MoyaError {
            switch moyaError {
            case .statusCode(let response):
                return .invalidStatusCode(response.statusCode)
            case .underlying(let error, _):
                return .underlying(error)
            default:
                return .underlying(moyaError)
            }
        }
        return .underlying(error)
    }
}
