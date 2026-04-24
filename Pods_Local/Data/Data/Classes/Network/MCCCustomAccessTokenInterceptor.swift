//
//  MCCCustomAccessTokenInterceptor.swift
//

import Combine

///
actor MCCTokenRefreshState {
    ///
    private var refreshing: AnyPublisher<Void, MCENetworkError>?
    ///
    func publisher() -> AnyPublisher<Void, MCENetworkError>? {
        refreshing
    }
    ///
    func set(_ publisher: AnyPublisher<Void, MCENetworkError>) {
        refreshing = publisher
    }
    ///
    func clear() {
        refreshing = nil
    }
}

///
public final class MCCCustomAccessTokenInterceptor: MCPAccessTokenRefreshable {
    ///
    public static let shared = MCCCustomAccessTokenInterceptor()
    ///
    private let state = MCCTokenRefreshState()
    ///
    private init() {}
    ///
    public func refreshToken(_ error: MCENetworkError) -> AnyPublisher<Void, MCENetworkError> {
        Future<AnyPublisher<Void, MCENetworkError>, Never> { promise in
            Task {
                /// 已有 refresh
                if let publisher = await self.state.publisher() {
                    promise(.success(publisher))
                    return
                }
                /// 创建 refresh publisher
                let publisher = self.refresh(with: error)
                    .handleEvents(
                        receiveCompletion: { _ in
                            Task { await self.state.clear() }
                        },
                        receiveCancel: {
                            Task { await self.state.clear() }
                        }
                    )
                    .share()
                    .eraseToAnyPublisher()
                await self.state.set(publisher)
                promise(.success(publisher))
            }
        }
        .flatMap { $0 }
        .eraseToAnyPublisher()
    }
    ///
    private func refresh(with error: MCENetworkError) -> AnyPublisher<Void, MCENetworkError> {
        let request: AnyPublisher<MCSUser, MCENetworkError>
        switch error {
        case .loginExpired:
            var requestModel: MCSUserLoginRequest = .init()
            requestModel.pushStatus = 2
            request = MCCUserAPIManager.shared.login(with: requestModel)
        case .tokenExpired:
            guard let refreshToken = MCCAccountService.shared.currentUser.value?.refreshToken else {
                return Fail(error: MCENetworkError.loginExpired)
                    .eraseToAnyPublisher()
            }
            var requestModel: MCSUserRefreshRequest = .init()
            requestModel.refreshToken = refreshToken
            request = MCCUserAPIManager.shared.refresh(with: requestModel)
        default:
            return Fail(error: error)
                .eraseToAnyPublisher()
        }
        return request
            .handleEvents(receiveOutput: MCCAccountService.shared.updateCurrentUser)
            .map { _ in () }
            .eraseToAnyPublisher()
    }
}
