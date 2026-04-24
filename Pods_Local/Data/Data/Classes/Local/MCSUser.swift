//
//  MCSUser.swift
//

import Foundation
import WCDBSwift

///
public struct MCSUser: Codable, MCPDatabaseTableProtocol, TableCodable {
    ///
    @MCSSafeString public var deviceId: String
    ///
    @MCSSafeString public var uid: String
    ///
    @MCSSafeString public var accessToken: String
    ///
    @MCSSafeString public var refreshToken: String
    ///
    @MCSSafeString public var appAccountToken: String
    ///
    @MCSSafeString public var avatarImageUrl: String
    ///
    @MCSSafeString public var nickname: String
    ///
    @MCSSafeString public var email: String
    ///
    @MCSSafeInt public var integralCount: Int
    ///
    @MCSSafeInt public var integralCountIncrease: Int
    ///
    @MCSSafeBool public var vip: Bool
    ///
    @MCSSafeArray public var permission: [MCSUserPermission]
    ///
    @MCSSafe public var userReminderVo: MCSUserReminder
    ///
    @MCSSafeString public var creditsRefillHint: String
    /// Table Name
    public static var tableName: String { "User" }
    /// WCDB Mapping
    public enum CodingKeys: String, CodingTableKey {
        case deviceId
        case uid
        case accessToken
        case refreshToken
        case appAccountToken
        case avatarImageUrl
        case nickname
        case email
        case integralCount
        case integralCountIncrease
        case vip
        case permission
        case userReminderVo
        case creditsRefillHint
        ///
        public typealias Root = MCSUser
        ///
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        ///
        public static var columnConstraintBindings: [CodingKeys : ColumnConstraintBinding]? {
            return [
                .uid: ColumnConstraintBinding(isPrimary: true)
            ]
        }
        ///
        public static var indexes: [IndexBinding.Subfix: IndexBinding]? {
            return [
                "_uid_index": IndexBinding(indexesBy: [CodingKeys.uid])
            ]
        }
    }
}

///
public struct MCSUserPermission: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var grade: String
    ///
    @MCSSafeEnum public var duration: MCEDuration
    ///
    @MCSSafeBool public var activeStatus: Bool
    ///
    @MCSSafeString public var displayName: String
}

///
public struct MCSUserReminder: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var copywriter: String
    ///
    @MCSSafeInt public var pointsBonus: Int
}
