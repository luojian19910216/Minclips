//
//  MCCUmAPIManager.swift
//

import Combine
import Moya

///
public final class MCCUmAPIManager {
    ///
    public static let shared: MCCUmAPIManager = .init()
    ///
    private let networkManager = MCCAPIClient(
        provider: MCENetworkProvider.umProvider,
        tokenRefresher: MCCCustomAccessTokenInterceptor.shared
    )
    ///
    private init() {}
}

extension MCCUmAPIManager {
    ///
    public func identityEstablish() -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.identityEstablish)
    }
    ///
    public func credentialRenew(with requestModel: MCSUmCredentialRenewRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.credentialRenew(requestModel))
    }
    ///
    public func integralStatement() -> AnyPublisher<Int, MCENetworkError> {
        networkManager.request(.integralStatement)
    }
    ///
    public func profilePatch(with requestModel: MCSUmProfilePatchRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.profilePatch(requestModel))
    }
    ///
    public func mailOtpDispatch(with requestModel: MCSUmMailOtpDispatchRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.mailOtpDispatch(requestModel))
    }
    ///
    public func mailAttachConfirm(with requestModel: MCSUmMailAttachConfirmRequest) -> AnyPublisher<MCSEmpty, MCENetworkError> {
        networkManager.request(.mailAttachConfirm(requestModel))
    }
    ///
    public func feedbackAppend(with requestModel: MCSUmFeedbackAppendRequest) -> AnyPublisher<Bool, MCENetworkError> {
        networkManager.request(.feedbackAppend(requestModel))
    }
    ///
    public func safetyRetire(with requestModel: MCSUmSafetyRetireRequest) -> AnyPublisher<MCSUser, MCENetworkError> {
        networkManager.request(.safetyRetire(requestModel))
    }
}
