//
//  ConfigResponseModel.swift
//

import Foundation

///
public struct MCSConfigAppResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeArray public var iconList: [MCSBannerItem]
    ///
    @MCSSafeArray public var barList: [MCSBannerItem]
    ///
    @MCSSafeArray public var bannerList: [MCSBannerItem]
    ///
    @MCSSafeArray public var newBannerList: [MCSBannerItem]
    ///
    @MCSSafeArray public var userCard: [MCSBannerItem]
    ///
    @MCSSafeArray public var extensionList: [MCSBannerGroup]
    ///
//    @MCSSafeBool public var appStoreReviewSwitch: Bool
//    ///
//    @MCSSafeBool public var appStoreProductReviewSwitch: Bool
//    ///
//    @MCSSafeString public var firstGuide: String
//    ///
//    @MCSSafeString public var guide: String
//    ///
//    @MCSSafeString public var subGuide: String
//    ///
//    @MCSSafeString public var bindEmail: String
//    ///
//    @MCSSafeEnum public var create_ab_20251208: MCEAB
//    ///
//    @MCSSafeEnum public var subscribe_ab_20251117: MCEAB
//    ///
//    @MCSSafeEnum public var discount_subscribe_ab_20260112: MCEAB
//    ///
//    @MCSSafeEnum public var purchase_credits_ab_20260119: MCEAB
//    ///
//    @MCSSafeEnum public var subscribe2_new_ab_20260130: MCEAB
//    ///
//    @MCSSafeEnum public var weekly_upgrade_ab_20260304: MCEAB
}

///
public struct MCSBannerGroup: Codable {
    ///
    @MCSSafeEnum public var location: MCEBannerLocation
    ///
    @MCSSafeArray public var items: [MCSBannerItem]
}

///
public enum MCEBannerLocation: String, CaseIterable, Codable, MCPDefaultInitializable {
    ///
    case unknown
    ///
    case settings
    ///
    case homePageBottom
}

///
public struct MCSBannerItem: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var sign: String
    ///
    @MCSSafeString public var name: String
    ///
    @MCSSafeString public var iconUrl: String
    ///
    @MCSSafeString public var coverUrl: String
    ///
    @MCSSafeString public var deepLink: String
    ///
    public var imageUrl: String { !coverUrl.isEmpty ? coverUrl : iconUrl }
}

///
public struct MCSConfigToolsGroup: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var name: String
    ///
    @MCSSafeArray public var item: [MCSConfigToolsItemp]
}

///
public struct MCSConfigToolsItemp: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var id: String
    ///
    @MCSSafeString public var sign: String
    ///
    @MCSSafeString public var name: String
    ///
    @MCSSafeString public var icon: String
    ///
    @MCSSafeString public var iconMini: String
    ///
    @MCSSafeString public var iconMax: String
//    ///
//    @MCSSafeString public var templateId: String
//    ///
//    @MCSSafeEnum public var templateType: LQGTemplateType
//    ///
//    @MCSSafeBool public var isPro: Bool = false
    ///
    @MCSSafeArray public var specialTools: [[String: MCECodableValue]]
    ///
    @MCSSafeArray public var tagConfig: [[String: MCECodableValue]]
}

///
public struct MCSConfigOssstsResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var accessKeyId: String
    ///
    @MCSSafeString public var accessKeySecret: String
    ///
    @MCSSafeString public var securityToken: String
    ///
    @MCSSafeString public var endpoint: String
    ///
    @MCSSafeString public var region: String
    ///
    @MCSSafeString public var bucketName: String
    ///
    @MCSSafeString public var objectKey: String
    ///
    @MCSSafeString public var expiration: String
    ///
    @MCSSafeString public var uploadUrl: String
}

///
public struct MCSConfigFileUploadResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var cdnPath: String
}
