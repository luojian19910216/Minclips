//
//  MCSRunResponse.swift
//

import Foundation

///
public struct MCSRunItem: Codable {
    
    public init() {}

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
    
    @MCSSafeEnum public var qualityTier: MCEClarity
    
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
public enum MCERunStatus: Int, CaseIterable, Codable {
    ///
    case generating = 1
    ///
    case success = 2
    ///
    case failed = 3
}

extension MCERunStatus: MCPDefaultInitializable {}

///
public enum MCERunFailCode: String, CaseIterable, Codable {
    ///
    case fail
    ///
    case auditFail = "audit_reject"
}

extension MCERunFailCode: MCPDefaultInitializable {}

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

extension MCSRunItem {

    /// Thumbnail fallback: outputs → **`sourceImageUrl` (user’s first uploaded image)** → `inputBundle` extras → templates → artifact URLs/watermarks.
    public func mcc_firstPosterImageURLString() -> String {
        func pick(_ s: String) -> String? {
            let u = s.mcc_normalizedRemoteURL()
            return u.isEmpty ? nil : u
        }
        let ordered: [String] = [
            outputCoverThumbUrl,
            outputCoverImageUrl,
            sourceImageUrl,
            inputBundle.sourceImage0,
            inputBundle.sourceImage1,
            inputBundle.sourceImage2,
            inputBundle.sourceImage3,
            inputBundle.sourceImage4,
            inputBundle.sourceImage5,
            templateCoverThumbUrl,
            templateCoverImageUrl,
        ]
        for s in ordered {
            if let u = pick(s) { return u }
        }
        for r in outputArtifacts {
            if let u = pick(r.url) { return u }
            if let u = pick(r.watermarkUrl) { return u }
        }
        return ""
    }

    /// Pending tiles: blurred user upload when `sourceImageUrl` is set; otherwise same fallback poster as `mcc_firstPosterImageURLString()`, **still with blur** so generating vs failed thumbnails read the same.
    public func mcc_worksListThumbnail() -> (urlString: String, blurOverlay: Bool) {
        func pick(_ s: String) -> String? {
            let u = s.mcc_normalizedRemoteURL()
            return u.isEmpty ? nil : u
        }

        switch runState {
        case .success:
            return (mcc_firstPosterImageURLString(), false)

        case .generating, .failed:
            if let firstUser = pick(sourceImageUrl) {
                return (firstUser, true)
            }
            let fallback = mcc_firstPosterImageURLString()
            return (fallback, true)
        }
    }
}

extension String {

    /// Normalize remote URL strings coming from the server: trim whitespace, unescape JSON-style `\/` and unicode `\u002F`, and surrounding quotes if any. **Idempotent** (running it twice is a no-op).
    public func mcc_normalizedRemoteURL() -> String {
        var s = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.isEmpty { return s }
        if s.hasPrefix("\"") && s.hasSuffix("\"") && s.count >= 2 {
            s = String(s.dropFirst().dropLast())
        }
        if s.contains(#"\/"#) {
            s = s.replacingOccurrences(of: #"\/"#, with: "/")
        }
        let lower = s.lowercased()
        if lower.contains(#"\u002f"#) {
            s = s.replacingOccurrences(of: #"\u002f"#, with: "/", options: .caseInsensitive)
        }
        return s
    }
}
