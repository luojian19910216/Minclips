//
//  MCSRunRequest.swift
//

import Foundation

///
/// Body for `MCERunAPI.composeSeed` → `POST /gwx/v1/runs/compose/seed`.
/// Add or rename fields when the backend contract is finalized.
public struct MCSComposeSeedRequest: Codable {
    ///
    public init() {}
    ///
    public var templateId: String?
    ///
    public var images: [String]?
    ///
    public var video: String?
    ///
    public var text: String?
    ///
    public var clarity: String?
    ///
    public var duration: String?
    ///
    public var roller: String?
    ///
    public var isAi: String?
    ///
    public var isVideoMerge: Bool = false
}

///
public struct MCSRunListRequest: Codable {
    ///
    public init() {}
    /// limit
    public var itemsPerPage: Int = 20
    /// lastId
    public var resumeAfterId: String?
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
