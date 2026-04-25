//
//  MCSSubscriptionResponse.swift
//

import Foundation

///
public struct MCSSubscriptionCatalogResponse: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeEnum public var ab: MCEAB
    ///
    @MCSSafeBool public var discountRetention: Bool
    ///
    @MCSSafeString public var retentionDeepLink: String
    ///
    @MCSSafeArray public var offers: [MCSSubscriptionRow] = []
}

///
public struct MCSSubscriptionRow: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    /// id
    @MCSSafeString public var offerId: String
    /// productType
    @MCSSafeString public var offerCategory: String
    /// duration
    @MCSSafeEnum public var planPeriod: MCEDuration
    /// title
    @MCSSafeString public var subheading: String
    /// benefit
    @MCSSafeString public var benefitTag: String
    /// discount
    @MCSSafeInt public var onSale: Int
    /// discountDesc
    @MCSSafeString public var promoText: String
    /// priceDesc
    @MCSSafeString public var priceHeadline: String
    /// discountPrice
    @MCSSafeString public var currentPrice: String
    /// freeTrial
    @MCSSafeInt public var freeTrialEnabled: Int
    /// giftIntegral
    @MCSSafeInt public var bonusCredits: Int
    /// integralCount
    @MCSSafeInt public var creditsPerPeriod: Int
    /// integralRate
    @MCSSafeString public var creditCadence: String
    /// name
    @MCSSafeString public var displayName: String
    /// originIntegralCount
    @MCSSafeInt public var baseCredits: Int
    /// originalPrice
    @MCSSafeString public var listPrice: String
    /// payLevel
    @MCSSafeString public var checkoutClass: String
    /// priceDescription
    @MCSSafeString public var priceLine: String
    /// selected
    @MCSSafeInt public var isSelected: Int
    /// totalIntegral
    @MCSSafeInt public var creditAllowance: Int
    /// unit
    @MCSSafeString public var currencySign: String
    /// tip
    @MCSSafeString public var helpText: String
    /// isShowWeek
    @MCSSafeBool public var showWeeklyCredits: Bool
    /// isShowWeekV2
    @MCSSafeBool public var showWeeklyCreditsV2: Bool
    /// label
    @MCSSafeString public var cornerBadge: String
    /// isFb
    @MCSSafeBool public var adReporting: Bool
    /// advocacy
    @MCSSafeString public var savingsPitch: String
    /// confirmBtn
    @MCSSafeString public var callToAction: String
    /// placard
    @MCSSafeArray public var featureLines: [MCSSubscriptionFeatureLine]
    /// backPlacard
    @MCSSafeArray public var backFeatureLines: [MCSSubscriptionFeatureLine]
}

///
public struct MCSSubscriptionFeatureLine: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    /// text
    @MCSSafeString public var line: String
    /// highlight
    @MCSSafeBool public var emphasis: Bool
    /// highlightText
    @MCSSafeString public var subline: String
    /// tailMarking
    @MCSSafeString public var endMark: String
}
