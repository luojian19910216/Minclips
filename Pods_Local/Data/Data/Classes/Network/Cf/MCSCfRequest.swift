//
//  MCSCfRequest.swift
//

import Foundation

///
public struct MCSCfCreationLegacyRequest: Codable {
    /// type
    public var filterKind: String = ""
}

///
public struct MCSCfOssTokenRequest: Codable {
    ///
    public init() {}
    /// fileType
    public var mimeKind: String = ""
    /// fileExtension
    public var fileSuffix: String = ""
}
