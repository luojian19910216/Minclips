//
//  MCSUmRequest.swift
//

import Foundation

///
public struct MCSUmCredentialRenewRequest: Codable {
    /// refreshToken
    public var reauthKey: String?
    /// pushStatus
    public var pushState: String?
}

///
public struct MCSUmProfilePatchRequest: Codable {
    /// avatarUrl
    public var avatarLink: String?
    /// nickname
    public var displayName: String?
}

///
public struct MCSUmMailOtpDispatchRequest: Codable {
    /// email
    public var mailId: String?
}

///
public struct MCSUmMailAttachConfirmRequest: Codable {
    /// email
    public var mailId: String?
    /// code
    public var otpCode: String?
}

///
public struct MCSUmFeedbackAppendRequest: Codable {
    /// email
    public var mailId: String?
    /// suggest
    public var hintText: String?
}

///
public struct MCSUmSafetyRetireRequest: Codable {
    /// uid
    public var userRef: String?
}
