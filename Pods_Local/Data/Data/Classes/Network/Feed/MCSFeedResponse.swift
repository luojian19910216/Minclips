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
    ///
    @MCSSafeInt public var homeOrder: Int
    ///
    @MCSSafeInt public var lowPointsCost: Int
    ///
    @MCSSafeString public var itemId: String
    ///
    @MCSSafeString public var showTitle: String
    ///
    @MCSSafeBool public var freeToUse: Bool
    ///
    @MCSSafeBool public var likedByUser: Bool
    ///
    @MCSSafeInt public var likesCount: Int
    ///
    @MCSSafeString public var displayName: String
    ///
    @MCSSafeInt public var pointCost: Int
    ///
    @MCSSafeArray public var presetGallery: [MCSFeedPresetGalleryEntry]
    ///
    @MCSSafeInt public var contentLevel: Int
    ///
    @MCSSafeBool public var proFeature: Bool
    ///
    @MCSSafeEnum public var contentKind: MCEFeedContentKind
    ///
    @MCSSafe public var videoAsset: MCSFeedVideoAssetShell
    ///
    @MCSSafeString public var itemTitle: String
    ///
    @MCSSafeBool public var tenSecondMode: Bool
    ///
    @MCSSafeInt public var hiDefPoints: Int
    ///
    @MCSSafeInt public var tenSecPoints: Int
    ///
    @MCSSafeString public var popularityText: String
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
    /// output cover thumb — prefer for detail poster when set
    @MCSSafeString public var outputCoverThumbUrl: String
    /// webpUrl
    @MCSSafeString public var webpImageUrl: String
}

///
public struct MCSFeedPresetGalleryEntry: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeArray public var imageLibrary: [String]
    ///
    @MCSSafeString public var defaultImage: String
    ///
    @MCSSafeString public var presetDescription: String

    enum CodingKeys: String, CodingKey {
        case imageLibrary
        case defaultImage
        case presetDescription = "description"
    }
}
