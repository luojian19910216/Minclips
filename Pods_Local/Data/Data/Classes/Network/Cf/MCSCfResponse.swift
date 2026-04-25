//
//  MCSCfResponse.swift
//

import Foundation

///
public struct MCSCfLauncherResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    /// appStoreReviewSwitch
    @MCSSafeBool public var appStoreMask: Bool
    /// appStoreProductReviewSwitch
    @MCSSafeBool public var appStoreIapMask: Bool
    /// guide
    @MCSSafeString public var walkthroughConfig: String
    /// firstGuide
    @MCSSafeString public var firstWalkthroughConfig: String
    /// subGuide
    @MCSSafeString public var weeklySubscriberWalkthrough: String
    /// bindEmail
    @MCSSafeString public var emailBindUrl: String
//    /// iconList
//    @MCSSafeArray public var dockIcons: [MCSBannerItem]
//    /// bannerList
//    @MCSSafeArray public var homeBanners: [MCSBannerItem]
//    /// newBannerList
//    @MCSSafeArray public var featureBanners: [MCSBannerItem]
//    /// barList
//    @MCSSafeArray public var tabBarConfig: [MCSBannerItem]
//    /// userCard
//    @MCSSafeArray public var userCreditCards: [MCSBannerItem]
//    /// extensionList
//    @MCSSafeArray public var extensionBar: [MCSBannerGroup]
}

/////
//public struct MCSBannerGroup: Codable {
//    ///
//    @MCSSafeEnum public var location: MCEBannerLocation
//    ///
//    @MCSSafeArray public var items: [MCSBannerItem]
//}
//
/////
//public enum MCEBannerLocation: String, CaseIterable, Codable, MCPDefaultInitializable {
//    ///
//    case unknown
//}
//
/////
//public struct MCSBannerItem: Codable, MCPDefaultInitializable {
//    ///
//    public init() {}
//    ///
//    @MCSSafeString public var sign: String
//    ///
//    @MCSSafeString public var name: String
//    ///
//    @MCSSafeString public var iconUrl: String
//    ///
//    @MCSSafeString public var coverUrl: String
//    ///
//    @MCSSafeString public var deepLink: String
//    ///
//    public var imageUrl: String { !coverUrl.isEmpty ? coverUrl : iconUrl }
//}

///
public struct MCSCfToolboxGroup: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var name: String
    ///
    @MCSSafeArray public var item: [MCSCfToolboxItem]
}

///
public struct MCSCfToolboxItem: Codable, MCPDefaultInitializable {
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
public struct MCSCfOssTokenResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    /// accessKeyId
    @MCSSafeString public var cloudAccessKeyId: String
    /// accessKeySecret
    @MCSSafeString public var cloudSecretKey: String
    /// securityToken
    @MCSSafeString public var sessionToken: String
    /// expiration
    @MCSSafeString public var expiresAt: String
    /// objectKey
    @MCSSafeString public var objectPath: String
    /// uploadUrl
    @MCSSafeString public var uploadTargetUrl: String
    /// bucketName
    @MCSSafeString public var bucketName: String
    /// endpoint
    @MCSSafeString public var endpoint: String
    /// region
    @MCSSafeString public var region: String
}

///
public struct MCSCfCdnObjectResponse: Codable, MCPDefaultInitializable {
    public init() {}
    /// cdnPath
    @MCSSafeString public var cdnObjectPath: String
}
