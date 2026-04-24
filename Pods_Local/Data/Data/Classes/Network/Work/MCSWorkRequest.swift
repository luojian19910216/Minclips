//
//  WorkRequestModel.swift
//

import Foundation

///
public struct MCSWorkCreateRequest: Codable {
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
public struct MCSWorkListRequest: Codable {
    ///
    public init() {}
    ///
    public var limit: Int = 20
    ///
    public var lastId: String?
    /// image/video
    public var resultType: String?
    /// 2: success
    public var status: String?
}

///
public struct MCSWorkInfosRequest: Codable {
    ///
    public init() {}
    ///
    public var workIds: [String] = []
}

///
public struct MCSWorkInfoRequest: Codable {
    ///
    public init() {}
    ///
    public var workId: String = ""
}

///
public struct MCSWorkDeleteRequest: Codable {
    ///
    public init() {}
    ///
    public var workId: String = ""
}
