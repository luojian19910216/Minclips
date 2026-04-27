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
public struct MCSFeedItem: Codable {
    /// id
    @MCSSafeString public var itemId: String
    /// name
    @MCSSafeString public var itemTitle: String
    /// media`
    @MCSSafe public var videoAsset: MCSFeedVideoAssetShell
    ///
    @MCSSafeBool public var proFeature: Bool
}

///
public struct MCSFeedVideoAssetShell: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    /// width
    @MCSSafeInt public var imageWidth: Int
    /// height
    @MCSSafeInt public var imageHeight: Int
    /// mp4Audio
    @MCSSafeBool public var hasMp4Audio: Bool
    /// mp4Url
    @MCSSafeString public var videoMp4Url: String
    /// staticCoverUrl
    @MCSSafeString public var posterImageUrl: String
    /// webpUrl
    @MCSSafeString public var webpImageUrl: String
}
