//
//  NetworkRequestModel.swift
//

import Foundation

///
public struct MCSNetworkPageRequest: Codable {
    ///
    public var pageSize: Int = 20
    ///
    public var pageNumber: Int = 1
}

///
public struct MCSNetworkListRequest: Codable {
    ///
    public var limit: Int = 20
    ///
    public var lastId: String?
}
