//
//  MCSGuide.swift
//

import Foundation

///
public struct MCSGuide: Codable, Hashable {
    ///
    public var id: String = UUID().uuidString
    ///
    public var medio: String = ""
    ///
    public var title: String = ""
    ///
    public var detail: String = ""
    ///
    public var handleBtnTitle: String = ""
}
