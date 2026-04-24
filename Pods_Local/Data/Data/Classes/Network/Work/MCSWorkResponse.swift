//
//  WorkResponseModel.swift
//

import Foundation

///
public struct MCSWorkItem: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeDate public var createTime: Date
    ///
    @MCSSafeString public var id: String = ""
    ///
    @MCSSafeString public var taskId: String = ""
    ///
    @MCSSafeEnum public var status: MCEWorkStatus
    ///
    @MCSSafeEnum public var failCode: MCEWorkFailCode
    ///
    @MCSSafeString public var failReason: String = ""
    ///
    @MCSSafeString public var imageUrl: String = ""
    ///
    @MCSSafeString public var coverUrl: String = ""
    ///
    @MCSSafeArray public var result: [MCSWorkResult]
    ///
    @MCSSafeEnum public var clarity: MCEClarity
//    ///
//    public var templateId: String = ""
//    ///
//    public var templateType: LQGTemplateType = .unknown
//    ///
//    public var templateSign: String?
//    ///
//    public var templateName: String?
//    ///
//    public var isTenSeconds: Bool = false
//    ///
//    public var ispro: Bool = false
//    ///
//    public var is_free: Bool = false
//    ///
//    public var inputs: [AnyHashable: Any] = [:]
//    public var isAi: String = ""
}

///
public struct MCSWorkResult: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeString public var watermarkUrl: String
    ///
    @MCSSafeString public var url: String
    ///
    @MCSSafeCGFloat public var width: CGFloat
    ///
    @MCSSafeCGFloat public var height: CGFloat
    ///
    @MCSSafeInt public var duration: Int
}

///
public enum MCEWorkStatus: Int, CaseIterable, Codable, MCPDefaultInitializable {
    ///
    case generating = 1
    ///
    case success = 2
    ///
    case failed = 3
}

///
public enum MCEWorkFailCode: String, CaseIterable, Codable, MCPDefaultInitializable {
    ///
    case fail
    ///
    case auditReject = "audit_reject"
}
