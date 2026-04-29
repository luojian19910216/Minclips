//
//  MCSRunRequest.swift
//

import Foundation

///
public struct MCSComposeSeedRequest: Codable {
    ///
    public init() {}
    ///
    public var templateRef: String?
    ///
    public var imageList: [String]?
    /// 0/1/2
    public var outputQuality: String?
    /// 5/10
    public var clipDuration: String?
}

///
public struct MCSRunListRequest: Codable {
    ///
    public init() {}
    /// limit
    public var itemsPerPage: Int = 20
    /// lastId
    public var resumeAfterId: String?
    /// image/video
    public var outputKind: String?
}

///
public struct MCSRunInfosRequest: Codable {
    ///
    public init() {}
    /// workIds
    public var workIdList: [String] = []
}

///
public struct MCSRunInfoRequest: Codable {
    ///
    public init() {}
    /// workId
    public var workRef: String = ""
}

///
public struct MCSRunDeleteRequest: Codable {
    ///
    public init() {}
    /// workId
    public var workRef: String = ""
}
