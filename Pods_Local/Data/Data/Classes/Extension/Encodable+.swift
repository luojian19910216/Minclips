//
//  Encodable+.swift
//

import Foundation

extension Encodable {
    ///
    public func toDictionary() -> [String: Any]? {
        do {
            let data = try JSONEncoder().encode(self)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            return jsonObject as? [String: Any]
        } catch {
            return nil
        }
    }
}
