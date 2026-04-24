//
//  ConfigRequestModel.swift
//

import Foundation

///
public struct MCSConfigCreateRequest: Codable {
    ///
    public init() {}
    /// imagetoTmage/imageToVideo/textToImage/textToVideo
    public var type: String = ""
}


///
public struct MCSConfigOssstsRequest: Codable {
    ///
    public init() {}
    /// image/video
    public var fileType: String = ""
    /// png/mp4
    public var fileExtension: String = ""
}
