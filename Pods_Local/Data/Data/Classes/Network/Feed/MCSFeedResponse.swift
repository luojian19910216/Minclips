//
//  MCSFeedResponse.swift
//

import Foundation

///
public struct MCSFeedLabelItem: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    /// id
    @MCSSafeString public var templateRef: String
    /// sign
    @MCSSafeString public var productSign: String
    /// displayName
    @MCSSafeString public var title: String
    /// iconUrl
    @MCSSafeString public var iconImageUrl: String
}

///
public struct MCSFeedSearchResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
//    /// 是否是搜索结果，值反了
//    @MCSSafeBool public var fromAppSearch: Bool
//    ///
//    @MCSSafeArray public var list: [MCSFeedItem]
}

///
public struct MCSFeedItem: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    /// id
    @MCSSafeString public var itemId: String
}
