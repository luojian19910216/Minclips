//
//  UserRequestModel.swift
//

import Foundation

///
public struct MCSUserLoginRequest: Codable {
    ///
    public init() {}
    ///
    public var pushStatus: Int = 0
    ///
    public var h5ActiveCode: String = ""
}

///
public struct MCSUserRefreshRequest: Codable {
    ///
    public init() {}
    ///
    public var pushStatus: Int = 0
    ///
    public var refreshToken: String = ""
}

///
public struct MCSUserUpdateRequest: Codable {
    ///
    public init() {}
    ///
    public var avatarUrl: String = ""
    ///
    public var nickname: String = ""
}

///
public struct MCSUserBindEmailSendCodeRequest: Codable {
    ///
    public init() {}
    ///
    public var email: String = ""
}

///
public struct MCSUserBindEmailRequest: Codable {
    ///
    public init() {}
    ///
    public var email: String = ""
    ///
    public var code: String = ""
}

///
public struct MCSUserSuggestAddRequest: Codable {
    ///
    public init() {}
    ///
    public var email: String = ""
    ///
    public var suggest: String = ""
}

///
public struct MCSUserDeleteAccountRequest: Codable {
    ///
    public init() {}
    ///
    public var uid: String = ""
}
