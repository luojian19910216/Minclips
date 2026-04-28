//
//  MCSRunResponse.swift
//

import Foundation

///
public struct MCSRunItem: Codable, MCPDefaultInitializable {
    ///
    public init() {}
    ///
    @MCSSafeDate public var createTime: Date
    /// id
    @MCSSafeString public var runId: String = ""
//    ///
//    @MCSSafeString public var taskId: String = ""
//    ///
//    @MCSSafeEnum public var status: MCERunStatus
//    ///
//    @MCSSafeEnum public var failCode: MCERunFailCode
//    ///
//    @MCSSafeString public var failReason: String = ""
    @MCSSafeString public var imageUrl: String = ""
    @MCSSafeString public var coverUrl: String = ""
    @MCSSafeArray public var result: [MCSRunResult] = []
//    ///
//    @MCSSafeEnum public var clarity: MCEClarity
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
//    ///
//    public var isAi: String = ""
}

///
public struct MCSRunResult: Codable, MCPDefaultInitializable {
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
public enum MCERunStatus: Int, CaseIterable, Codable, MCPDefaultInitializable {
    ///
    case generating = 1
    ///
    case success = 2
    ///
    case failed = 3
}

///
public enum MCERunFailCode: String, CaseIterable, Codable, MCPDefaultInitializable {
    ///
    case fail
    ///
    case auditReject = "audit_reject"
}
