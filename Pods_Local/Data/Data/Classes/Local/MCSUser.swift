//
//  MCSUser.swift
//

import Foundation
import WCDBSwift

///
public struct MCSUser: Codable, MCPDatabaseTableProtocol, TableCodable {
    ///
    @MCSSafeString public var deviceKey: String
    ///
    @MCSSafeString public var userId: String
    ///
    @MCSSafeString public var authToken: String
    ///
    @MCSSafeString public var renewToken: String
    ///
    @MCSSafeString public var appAccountId: String
    ///
    @MCSSafeString public var avatarUrl: String
    ///
    @MCSSafeString public var displayName: String
    ///
    @MCSSafeString public var email: String
    ///
    @MCSSafeInt public var pointsBalance: Int
    ///
    @MCSSafeInt public var pointsDelta: Int
    ///
    @MCSSafeBool public var membershipActive: Bool
    ///
    @MCSSafeArray public var entitlements: [MCSEntitlement]
    ///
    @MCSSafe public var reminder: MCSReminder
    ///
    @MCSSafeString public var creditsRefillMessage: String
    /// Table Name
    public static var tableName: String { "User" }
    /// WCDB Mapping
    public enum CodingKeys: String, CodingTableKey {
        case deviceKey
        case userId
        case authToken
        case renewToken
        case appAccountId
        case avatarUrl
        case displayName
        case email
        case pointsBalance
        case pointsDelta
        case membershipActive
        case entitlements
        case reminder
        case creditsRefillMessage
        ///
        public typealias Root = MCSUser
        ///
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        ///
        public static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                .userId: ColumnConstraintBinding(isPrimary: true)
            ]
        }
        ///
        public static var indexes: [IndexBinding.Subfix: IndexBinding]? {
            return [
                "_userId_index": IndexBinding(indexesBy: [CodingKeys.userId])
            ]
        }
    }
}

public struct MCSEntitlement: Codable, MCPDefaultInitializable {
    ///
    @MCSSafeString public var entitlementType: String
    ///
    @MCSSafeString public var tierCode: String
    ///
    @MCSSafeString public var label: String
    ///
    @MCSSafeString public var validFrom: String
    ///
    @MCSSafeString public var validTo: String
    ///
    @MCSSafeBool public var isActive: Bool
    ///
    @MCSSafeString public var billingPeriod: String
    ///
    public init() {}
}

public struct MCSReminder: Codable, MCPDefaultInitializable {
    ///
    @MCSSafeString public var hintText: String
    ///
    @MCSSafeInt public var bonusPoints: Int
    ///
    @MCSSafeInt public var proTrialsLeft: Int
    ///
    public init() {}
}
