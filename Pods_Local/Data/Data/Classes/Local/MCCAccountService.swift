//
//  MCCAccountService.swift
//

import Foundation
import Combine

///
private enum MCEUserConfig {
    ///
    static let currentUid = "com.minclips.user.uid"
}

///
public final class MCCAccountService {
    ///
    public static let shared = MCCAccountService()
    ///
    public private(set) var currentUser = CurrentValueSubject<MCSUser?, Never>(nil)
    ///
    public var isLogin: AnyPublisher<Bool, Never> {
        currentUser
            .map { $0 != nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    ///
    private init() {
        if let uid = UserDefaults.standard.string(forKey: MCEUserConfig.currentUid),
           let user = MCCUserTableManager.shared.getUser(by: uid) {
            currentUser.send(user)
        }
    }
    ///
    public func login(user: MCSUser) {
        UserDefaults.standard.set(user.uid, forKey: MCEUserConfig.currentUid)
        MCCUserTableManager.shared.saveUser(user)
        currentUser.send(user)
    }
    ///
    public func logout() {
        UserDefaults.standard.removeObject(forKey: MCEUserConfig.currentUid)
        currentUser.send(nil)
    }
    ///
    public func updateCurrentUser(_ user: MCSUser) {
        UserDefaults.standard.set(user.uid, forKey: MCEUserConfig.currentUid)
        MCCUserTableManager.shared.saveUser(user)
        currentUser.send(user)
    }
    ///
    public func update(_ block: (inout MCSUser) -> Void) {
        guard var user = currentUser.value else { return }
        block(&user)
        MCCUserTableManager.shared.saveUser(user)
        currentUser.send(user)
    }
}
