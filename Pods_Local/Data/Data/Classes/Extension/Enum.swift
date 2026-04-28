//
//  Enum.swift
//

import Foundation

///
public enum MCEAB: String, CaseIterable, Codable, MCPDefaultInitializable {
    ///
    case unknown, dz, a, b, c, d
}

public enum MCEDuration: String, CaseIterable, Codable, MCPDefaultInitializable {
    ///
    case week, month, year
}

///
public enum MCEClarity: Int, CaseIterable, Codable, MCPDefaultInitializable {
    ///
    case fast, standard, high
}

///
public enum MCEFeedContentKind: String, CaseIterable, Codable, MCPDefaultInitializable {
    ///
    case imageToVideo = "image_to_video"
    ///
    case imageToImage = "image_to_image"

    public init?(rawValue: String) {
        let normalized: String
        if rawValue.hasPrefix("much_") {
            normalized = String(rawValue.dropFirst(5))
        } else {
            normalized = rawValue
        }
        switch normalized {
        case Self.imageToVideo.rawValue:
            self = .imageToVideo
        case Self.imageToImage.rawValue:
            self = .imageToImage
        default:
            return nil
        }
    }

    /// Generated video (图生视频) vs static image (图生图)。
    public var isToVideo: Bool { self == .imageToVideo }
}
