//
//  MCSFeedResponse.swift
//

import Foundation

///
public struct MCSFeedLabelItem: Codable, MCPDefaultInitializable {
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
public struct MCSFeedSearchResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    /// 是否是搜索结果，值反了
    @MCSSafeBool public var fromAppSearch: Bool
    ///
    @MCSSafeArray public var list: [MCSFeedItem]
}

///
public struct MCSFeedItem: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var id: String
}
