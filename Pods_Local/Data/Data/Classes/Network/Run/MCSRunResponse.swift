//
//  MCSRunResponse.swift
//

import Foundation

///
public struct MCSRunItem: Codable {

    @MCSSafeDate public var createTime

    @MCSSafeString public var runId: String

    @MCSSafeString public var taskId: String
    
    @MCSSafeEnum public var runState: MCERunStatus

    @MCSSafeEnum public var failureCode: MCERunFailCode
        
    @MCSSafeString public var failureReason: String
    
    @MCSSafeString public var sourceImageUrl: String

    @MCSSafeString public var outputCoverThumbUrl: String
    
    @MCSSafeString public var outputCoverImageUrl: String
    
    @MCSSafeArray<MCSRunResult> public var outputArtifacts: [MCSRunResult] = []
    
    @MCSSafeInt public var qualityTier: Int
    
    @MCSSafeInt public var pointCost: Int

    @MCSSafeString public var outputKind: String

    @MCSSafeInt public var liked: Int = 0

    @MCSSafeInt public var disliked: Int = 0

    @MCSSafeInt public var proFeature: Int = 0

    @MCSSafeInt public var freeToUse: Int = 0
    
    @MCSSafeInt public var aiGenerated: Int = 0
    
    @MCSSafe public var inputBundle: MCSWorkRunInputBundleShell
    
    @MCSSafeInt public var templateId: Int

    @MCSSafeString public var templateName: String

    @MCSSafeString public var showTitle: String

    @MCSSafeEnum public var contentKind: MCEFeedContentKind
    
    @MCSSafeString public var templateCoverImageUrl: String
    
    @MCSSafeString public var templateCoverThumbUrl: String
    
    @MCSSafeInt public var tenSecondMode: Int = 0

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
    case reject = "audit_reject"
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

public struct MCSWorkRunInputBundleShell: Codable, MCPDefaultInitializable {

    public init() {}
    
    @MCSSafeString public var sourceImage0: String = ""

    @MCSSafeString public var sourceImage1: String = ""

    @MCSSafeString public var sourceImage2: String = ""

    @MCSSafeString public var sourceImage3: String = ""

    @MCSSafeString public var sourceImage4: String = ""

    @MCSSafeString public var sourceImage5: String = ""

    @MCSSafeString public var sourceVideo: String = ""

    @MCSSafeString public var promptText: String = ""

    @MCSSafeInt public var clipDurationSec: Int = 0
    
}
