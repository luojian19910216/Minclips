//
//  MCSNetworkResponse.swift
//

import Foundation

///
public struct MCSNetworkResponse<T: Decodable>: Decodable {
    ///
    @MCSSafeString
    public var clientAction: String = ""
    ///
    @MCSSafeInt
    public var statusCode: Int
    ///
    @MCSSafeString
    public var statusText: String
    ///
    public var payload: T?
    ///
    @MCSSafeString
    public var respondedAt: String = ""
}

///
public struct MCSList<T: Decodable>: Decodable {
    ///
    public var items: [T] = []
    ///
    public init(items: [T] = []) {
        self.items = items
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let array = try? container.decode([T].self) {
            self.items = array
            return
        }
        if let keyedContainer = try? decoder.container(keyedBy: CodingKeys.self) {
            if let list = try? keyedContainer.decode([T].self, forKey: .list) {
                self.items = list
                return
            }
        }
        self.items = []
    }
    ///
    private enum CodingKeys: String, CodingKey {
        case list
    }
}

///
public struct MCSEmpty: Codable {}
