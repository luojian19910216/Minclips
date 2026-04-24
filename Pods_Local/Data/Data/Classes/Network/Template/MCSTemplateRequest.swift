//
//  TemplateRequestModel.swift
//

import Foundation

///
public struct MCSTemplateListRequest: Codable {
    ///
    public init() {}
    /// 是否是首次安装
    public var isFirstInstall: Bool = false
    /// 是否是冷启动
    public var isColdStart: Bool = false
    /// 来源
    public var source: String?
    ///
    public var limit: Int = 20
    ///
    public var lastId: String?
    /// 首页传
    public var lastHomePageSort: String?
    /// 模版流传
    public var customId: String?
    /// 搜索传
    public var keyword: String?
}

///
public struct MCSTemplateLikeListRequest: Codable {
    ///
    public init() {}
    ///
    public var pageSize: Int = 20
    ///
    public var pageNumber: Int = 1
    ///
    public var isTool: Bool = false
}

///
public struct MCSTemplateDetailRequest: Codable {
    ///
    public init() {}
    ///
    public var templateId: String = ""
}

///
public struct MCSTemplateReportRequest: Codable {
    ///
    public init() {}
    ///
    public var templateId: String = ""
    ///
    public var reportContent: String = ""
}

///
public struct MCSTemplateExposeRequest: Codable {
    ///
    public init() {}
    ///
    public var templates: [MCSTemplateExposeItem]?
}

///
public struct MCSTemplateExposeItem: Codable {
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
