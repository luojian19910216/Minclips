//
//  MCCDatabaseManager.swift
//

import Foundation
import WCDBSwift

///
private enum MCEDatabaseConfig {
    ///
    static let path = "com.minclips.database.db"
    ///
    static let queue = "com.minclips.database.queue"
}

///
public protocol MCPDatabaseTableProtocol {
    ///
    static var tableName: String { get }
}

///
public final class MCCDatabaseManager {
    ///
    public static let shared: MCCDatabaseManager = .init()
    ///
    private let queue = DispatchQueue(label: MCEDatabaseConfig.queue, qos: .userInitiated)
    ///
    private let databasePath: String = FileManager.default
        .urls(for: .documentDirectory, in: .userDomainMask)
        .first!
        .appendingPathComponent(MCEDatabaseConfig.path)
        .path
    ///
    public lazy var database: Database = Database(withPath: databasePath)
    ///
    private init() {}
    ///
    public func initialization() {
        queue.async {
            let result = self.database.canOpen
#if DEBUG
            print("Database open \(result ? "success" : "failure")：\(self.database.path)")
#endif
        }
    }
    ///
    public func createTable<T: TableCodable & MCPDatabaseTableProtocol & Sendable>(_ type: T.Type) {
        queue.async {
            let result = (try? self.database.create(table: type.tableName, of: type)) != nil
#if DEBUG
            print("Table create \(result ? "success" : "failure")：\(type.tableName)")
#endif
        }
    }
}
