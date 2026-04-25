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
    /// keyword
    public var searchText: String?
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
    /// templateId
    public var templateRef: String = ""
    /// reportContent
    public var reportBody: String = ""
}

///
public struct MCSFeedExposeRequest: Codable {
    ///
    public init() {}
    /// templates
    public var exposureItems: [MCSFeedExposeItem]?
}

///
public struct MCSFeedExposeItem: Codable {
    ///
    public init() {}
    /// templateId
    public var templateRef: String = ""
    /// pageTitle
    public var viewTitle: String = ""
    /// channel
    public var channelKey: String?
    /// eventTime
    public var eventAt: Int64 = 0
}
