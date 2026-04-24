//
//  TemplateResponseModel.swift
//

import Foundation

///
public struct MCSTemplateLabelItem: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var id: String
    ///
    @MCSSafeString public var sign: String
    ///
    @MCSSafeString public var displayName: String
    ///
    @MCSSafeString public var iconUrl: String
    ///
    @MCSSafeString public var imageName: String
}

///
public struct MCSTemplateSearchResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    /// 是否是搜索结果，值反了
    @MCSSafeBool public var fromAppSearch: Bool
    ///
    @MCSSafeArray public var list: [MCSTemplateItem]
}

///
public struct MCSTemplateItem: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var id: String
}
