//
//  MCSFeedRequest.swift
//

import Foundation

///
public struct MCSFeedListRequest: Codable {
    ///
    public init() {}
    ///
    public var isFirstInstall: Bool = false
    ///
    public var isColdStart: Bool = false
    ///
    public var source: String?
    /// limit
    public var itemsPerPage: Int = 20
    /// lastId
    public var resumeAfterId: String?
    /// customId
    public var customRefId: String?
    ///
    public var keyword: String?
}

///
public struct MCSFeedLikeListRequest: Codable {
    ///
    public init() {}
    /// pageSize
    public var itemsPerPage: Int = 20
    /// pageNumber
    public var pageIndex: Int = 1
}

///
public struct MCSFeedDetailRequest: Codable {
    ///
    public init() {}
    /// templateId
    public var templateRef: String = ""
}

///
public struct MCSFeedReportRequest: Codable {
    ///
    public init() {}
    ///
    public var templateId: String = ""
    ///
    public var reportContent: String = ""
}

///
public struct MCSFeedExposeRequest: Codable {
    ///
    public init() {}
    ///
    public var templates: [MCSFeedExposeItem]?
}

///
public struct MCSFeedExposeItem: Codable {
    ///
    public init() {}
    ///
    public var templateId: String = ""
    ///
    public var pageTitle: String = ""
    ///
    public var channel: String?
    ///
    public var eventTime: Int64 = 0
}
