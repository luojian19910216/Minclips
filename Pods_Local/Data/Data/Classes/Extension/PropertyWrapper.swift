//
//  PropertyWrapper.swift
//

import Foundation
import WCDBSwift

public protocol MCPDefaultInitializable {
    init()
}

extension MCPDefaultInitializable where Self: ExpressibleByBooleanLiteral {
    public init() { self = false }
}

extension MCPDefaultInitializable where Self: ExpressibleByIntegerLiteral {
    public init() { self = 0 }
}

extension MCPDefaultInitializable where Self: ExpressibleByFloatLiteral {
    public init() { self = 0 as! Self }
}

extension MCPDefaultInitializable where Self: ExpressibleByStringLiteral {
    public init() { self = "" }
}

extension MCPDefaultInitializable where Self: RawRepresentable & CaseIterable {
    public init() { self = Self.allCases.first! }
}

@propertyWrapper
public struct MCSSafeBool: Codable, ColumnCodable, CustomStringConvertible {
    ///
    public var wrappedValue: Bool
    ///
    public init(wrappedValue: Bool = false) {
        self.wrappedValue = wrappedValue
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = false
            return
        }
        if let boolValue = try? container.decode(Bool.self) {
            wrappedValue = boolValue
            return
        }
        if let intValue = try? container.decode(Int.self) {
            wrappedValue = intValue != 0
            return
        }
        if let stringValue = try? container.decode(String.self) {
            let lower = stringValue.lowercased()
            if lower == "true" || lower == "1" {
                wrappedValue = true
                return
            }
            if lower == "false" || lower == "0" {
                wrappedValue = false
                return
            }
        }
        wrappedValue = false
    }
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
    ///
    public init?(with value: FundamentalValue) {
        self.init(wrappedValue: value.int32Value != 0)
    }
    ///
    public func archivedValue() -> FundamentalValue {
        FundamentalValue(wrappedValue)
    }
    ///
    public static var columnType: ColumnType {
        .integer32
    }
    ///
    public var description: String {
        wrappedValue.description
    }
}

@propertyWrapper
public struct MCSSafeInt: Codable, ColumnCodable, CustomStringConvertible {
    ///
    public var wrappedValue: Int
    ///
    public init(wrappedValue: Int = 0) {
        self.wrappedValue = wrappedValue
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = 0
            return
        }
        if let intValue = try? container.decode(Int.self) {
            wrappedValue = intValue
            return
        }
        if let doubleValue = try? container.decode(Double.self) {
            wrappedValue = Int(doubleValue)
            return
        }
        if let stringValue = try? container.decode(String.self),
           let intValue = Int(stringValue) {
            wrappedValue = intValue
            return
        }
        wrappedValue = 0
    }
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
    ///
    public init?(with value: FundamentalValue) {
        self.init(wrappedValue: Int(value.int64Value))
    }
    ///
    public func archivedValue() -> FundamentalValue {
        FundamentalValue(Int64(wrappedValue))
    }
    ///
    public static var columnType: ColumnType {
        .integer64
    }
    ///
    public var description: String {
        "\(wrappedValue)"
    }
}

@propertyWrapper
public struct MCSSafeCGFloat: Codable, ColumnCodable, CustomStringConvertible {
    ///
    public var wrappedValue: CGFloat
    ///
    public init(wrappedValue: CGFloat = 0) {
        self.wrappedValue = wrappedValue
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let doubleValue = try? container.decode(Double.self) {
            wrappedValue = CGFloat(doubleValue)
            return
        }
        if let intValue = try? container.decode(Int.self) {
            wrappedValue = CGFloat(intValue)
            return
        }
        if let stringValue = try? container.decode(String.self),
           let doubleFromString = Double(stringValue) {
            wrappedValue = CGFloat(doubleFromString)
            return
        }
        wrappedValue = 0
    }
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Double(wrappedValue))
    }
    ///
    public init?(with value: FundamentalValue) {
        self.wrappedValue = CGFloat(value.doubleValue)
    }
    ///
    public func archivedValue() -> FundamentalValue {
        FundamentalValue(Double(wrappedValue))
    }
    ///
    public static var columnType: ColumnType {
        .float
    }
    ///
    public var description: String {
        "\(wrappedValue)"
    }
}

@propertyWrapper
public struct MCSSafeString: Codable, ColumnCodable, CustomStringConvertible {
    ///
    public var wrappedValue: String
    ///
    public init(wrappedValue: String = "") {
        self.wrappedValue = wrappedValue
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = ""
            return
        }
        if let stringValue = try? container.decode(String.self) {
            wrappedValue = stringValue
            return
        }
        if let boolValue = try? container.decode(Bool.self) {
            wrappedValue = String(boolValue)
            return
        }
        if let intValue = try? container.decode(Int.self) {
            wrappedValue = String(intValue)
            return
        }
        if let doubleValue = try? container.decode(Double.self) {
            wrappedValue = String(doubleValue)
            return
        }
        wrappedValue = ""
    }
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
    ///
    public init?(with value: FundamentalValue) {
        self.init(wrappedValue: value.stringValue)
    }
    ///
    public func archivedValue() -> FundamentalValue {
        FundamentalValue(wrappedValue)
    }
    ///
    public static var columnType: ColumnType {
        .text
    }
    ///
    public var description: String {
        wrappedValue
    }
}

@propertyWrapper
public struct MCSSafeDate: Codable, ColumnCodable {
    ///
    public var wrappedValue: Date
    ///
    public init(wrappedValue: Date = Date()) {
        self.wrappedValue = wrappedValue
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let time = try? container.decode(Double.self) {
            if time > 1_000_000_000_000 { // 大于约 2001 年 -> 毫秒
                wrappedValue = Date(timeIntervalSince1970: time / 1000)
            } else { // 秒
                wrappedValue = Date(timeIntervalSince1970: time)
            }
            return
        }
        if let intTime = try? container.decode(Int.self) {
            if intTime > 1_000_000_000_000 { // 毫秒
                wrappedValue = Date(timeIntervalSince1970: TimeInterval(intTime) / 1000)
            } else { // 秒
                wrappedValue = Date(timeIntervalSince1970: TimeInterval(intTime))
            }
            return
        }
        if let stringValue = try? container.decode(String.self) {
            // 3a. 字符串是数字，解析为时间戳
            if let time = TimeInterval(stringValue) {
                wrappedValue = Date(timeIntervalSince1970: time)
                return
            }
            // 3b. ISO8601 格式
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: stringValue) {
                wrappedValue = date
                return
            }
            // 3c. 自定义格式
            let customFormatter = DateFormatter()
            customFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = customFormatter.date(from: stringValue) {
                wrappedValue = date
                return
            }
        }
        wrappedValue = Date()
    }
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.timeIntervalSince1970)
    }
    ///
    public init?(with value: FundamentalValue) {
        wrappedValue = Date(timeIntervalSince1970: value.doubleValue)
    }
    ///
    public func archivedValue() -> FundamentalValue {
        FundamentalValue(wrappedValue.timeIntervalSince1970)
    }
    ///
    public static var columnType: ColumnType {
        .float
    }
}

@propertyWrapper
public struct MCSSafeEnum<T: RawRepresentable & CaseIterable & Codable & MCPDefaultInitializable>: Codable, ColumnCodable where T.RawValue: Codable {
    ///
    public var wrappedValue: T
    ///
    public init(wrappedValue: T = T.allCases.first!) {
        self.wrappedValue = wrappedValue
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let rawValue = try? container.decode(T.RawValue.self), let value = T(rawValue: rawValue) {
            self.wrappedValue = value
        } else {
            self.wrappedValue = T()
        }
    }
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.rawValue)
    }
    ///
    public init?(with value: FundamentalValue) {
        if T.RawValue.self == String.self, let value = T(rawValue: value.stringValue as! T.RawValue) {
            wrappedValue =  value
            return
        }
        if T.RawValue.self == Int.self, let value = T(rawValue: Int(value.int64Value) as! T.RawValue) {
            wrappedValue = value
            return
        }
        wrappedValue = T()
    }
    ///
    public func archivedValue() -> FundamentalValue {
        if let stringRaw = wrappedValue.rawValue as? String {
            return FundamentalValue(stringRaw)
        } else if let intRaw = wrappedValue.rawValue as? Int {
            return FundamentalValue(Int64(intRaw))
        } else {
            return FundamentalValue("")
        }
    }
    ///
    public static var columnType: ColumnType {
        if T.RawValue.self == String.self { return .text }
        if T.RawValue.self == Int.self { return .integer64 }
        return .text
    }
}

@propertyWrapper
public struct MCSSafe<T: Codable & MCPDefaultInitializable>: Codable, ColumnCodable {
    ///
    public var wrappedValue: T
    ///
    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let model = try? container.decode(T.self) {
            self.wrappedValue = model
            return
        }
        if let jsonString = try? container.decode(String.self),
           let data = jsonString.data(using: .utf8),
           let model = try? JSONDecoder().decode(T.self, from: data) {
            self.wrappedValue = model
            return
        }
        self.wrappedValue = T()
    }
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
    ///
    public init?(with value: FundamentalValue) {
        if let data = value.stringValue.data(using: .utf8),
           let model = try? JSONDecoder().decode(T.self, from: data) {
            self.wrappedValue = model
        } else {
            self.wrappedValue = T()
        }
    }
    ///
    public func archivedValue() -> FundamentalValue {
        guard
            let data = try? JSONEncoder().encode(wrappedValue),
            let json = String(data: data, encoding: .utf8)
        else {
            return FundamentalValue("")
        }
        return FundamentalValue(json)
    }
    ///
    public static var columnType: ColumnType {
        .text
    }
}

@propertyWrapper
public struct MCSSafeDict: Codable, ColumnCodable {
    ///
    public var wrappedValue: [String: Any]
    ///
    public init(wrappedValue: [String: Any] = [:]) {
        self.wrappedValue = wrappedValue
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let jsonString = try? container.decode(String.self),
           let data = jsonString.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            wrappedValue = dict
        } else if let data = try? container.decode(Data.self), let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            wrappedValue = dict
        } else {
            wrappedValue = [:]
        }
    }
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let data = try? JSONSerialization.data(withJSONObject: wrappedValue, options: []),
           let json = String(data: data, encoding: .utf8) {
            try container.encode(json)
        } else {
            try container.encode("{}")
        }
    }
    ///
    public init?(with value: FundamentalValue) {
        if let data = value.stringValue.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            wrappedValue = json
        } else {
            wrappedValue = [:]
        }
    }
    ///
    public func archivedValue() -> FundamentalValue {
        if let data = try? JSONSerialization.data(withJSONObject: wrappedValue, options: []),
           let json = String(data: data, encoding: .utf8) {
            return FundamentalValue(json)
        }
        return FundamentalValue("{}")
    }
    ///
    public static var columnType: ColumnType {
        .text
    }
}

@propertyWrapper
public struct MCSSafeArray<T: Codable>: Codable, ColumnCodable, CustomStringConvertible {
    ///
    public var wrappedValue: [T]
    ///
    public init(wrappedValue: [T] = []) {
        self.wrappedValue = wrappedValue
    }
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = []
            return
        }
        if let array = try? container.decode([T].self) {
            wrappedValue = array
            return
        }
        wrappedValue = []
    }
    ///
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue)
    }
    ///
    public init?(with value: FundamentalValue) {
        guard let json = value.stringValue.data(using: .utf8) else {
            self.init(wrappedValue: [])
            return
        }
        if let array = try? JSONDecoder().decode([T].self, from: json) {
            self.init(wrappedValue: array)
        } else {
            self.init(wrappedValue: [])
        }
    }
    ///
    public func archivedValue() -> FundamentalValue {
        if let data = try? JSONEncoder().encode(wrappedValue),
           let json = String(data: data, encoding: .utf8) {
            return FundamentalValue(json)
        }
        return FundamentalValue("[]")
    }
    ///
    public static var columnType: ColumnType {
        .text
    }
    ///
    public var description: String {
        if let data = try? JSONEncoder().encode(wrappedValue),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
        return "[]"
    }
}

extension KeyedDecodingContainer {
    ///
    public func decode(_ type: MCSSafeBool.Type, forKey key: Key) throws -> MCSSafeBool {
        try decodeIfPresent(type, forKey: key) ?? MCSSafeBool()
    }
    ///
    public func decode(_ type: MCSSafeInt.Type, forKey key: Key) throws -> MCSSafeInt {
        try decodeIfPresent(type, forKey: key) ?? MCSSafeInt()
    }
    ///
    public func decode(_ type: MCSSafeCGFloat.Type, forKey key: Key) throws -> MCSSafeCGFloat {
        try decodeIfPresent(type, forKey: key) ?? MCSSafeCGFloat()
    }
    ///
    public func decode(_ type: MCSSafeString.Type, forKey key: Key) throws -> MCSSafeString {
        try decodeIfPresent(type, forKey: key) ?? MCSSafeString()
    }
    ///
    public func decode(_ type: MCSSafeDate.Type, forKey key: Key) throws -> MCSSafeDate {
        try decodeIfPresent(type, forKey: key) ?? MCSSafeDate()
    }
    ///
    public func decode<T>(_ type: MCSSafeEnum<T>.Type, forKey key: Key) throws -> MCSSafeEnum<T>
    where T: RawRepresentable & CaseIterable & Codable & MCPDefaultInitializable {
        try decodeIfPresent(type, forKey: key) ?? MCSSafeEnum(wrappedValue: T())
    }
    ///
    public func decode<T>(_ type: MCSSafe<T>.Type, forKey key: Key) throws -> MCSSafe<T>
    where T: Codable & MCPDefaultInitializable {
        try decodeIfPresent(type, forKey: key) ?? MCSSafe(wrappedValue: T())
    }
    ///
    public func decode(_ type: MCSSafeDict.Type, forKey key: Key) throws -> MCSSafeDict {
        try decodeIfPresent(type, forKey: key) ?? MCSSafeDict()
    }
    ///
    public func decode<T>(_ type: MCSSafeArray<T>.Type, forKey key: Key) throws -> MCSSafeArray<T>
    where T: Decodable {
        try decodeIfPresent(type, forKey: key) ?? MCSSafeArray<T>()
    }
}

public enum MCECodableValue: Codable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case dictionary([String: MCECodableValue])
    case array([MCECodableValue])
    case null
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([String: MCECodableValue].self) {
            self = .dictionary(v)
        } else if let v = try? container.decode([MCECodableValue].self) {
            self = .array(v)
        } else {
            self = .null
        }
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        case .dictionary(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}
