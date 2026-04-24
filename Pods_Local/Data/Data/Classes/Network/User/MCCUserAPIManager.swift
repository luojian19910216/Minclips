//
//  MCCUserAPIManager.swift
//

import Combine
import Moya

///
public final class MCCUserAPIManager {
    ///
    public static let shared: MCCUserAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.userProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCUserAPIManager {
    ///
    public func login(with requestModel: MCSUserLoginRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.login(requestModel))
    }
    ///
    public func refresh(with requestModel: MCSUserRefreshRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.refresh(requestModel))
    }
    ///
    public func integralQuery() -> AnyPublisher<Int, MCENetworkError> {
        networkManager.request(.integralQuery)
    }
    ///
    public func update(with requestModel: MCSUserUpdateRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.update(requestModel))
    }
    ///
    public func bindEmailSendCode(with requestModel: MCSUserBindEmailSendCodeRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.bindEmailSendCode(requestModel))
    }
    ///
    public func bindEmail(with requestModel: MCSUserBindEmailRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.bindEmail(requestModel))
    }
    ///
    public func suggestAdd(with requestModel: MCSUserSuggestAddRequest) -> AnyPublisher<Bool, MCENetworkError> {
        networkManager.request(.suggestAdd(requestModel))
    }
    ///
    public func deleteAccount(with requestModel: MCSUserDeleteAccountRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.deleteAccount(requestModel))
    }
}
