//
//  MCCUserTableManager.swift
//

import WCDBSwift

///
public final class MCCUserTableManager {
    ///
    public static let shared: MCCUserTableManager = .init()
    ///
    private let database = MCCDatabaseManager.shared.database
    ///
    private init() {}
    ///
    public func initialization() {
        MCCDatabaseManager.shared.createTable(MCSUser.self)
    }
    ///
    public func getAllUsers() -> [MCSUser] {
        do {
            return try database.getObjects(fromTable: MCSUser.tableName)
        } catch {
#if DEBUG
            print("MCCUserTableManager getAllUsers error: \(error)")
#endif
            return []
        }
    }
    ///
    public func getUser(by userId: String) -> MCSUser? {
        do {
            return try database.getObject(fromTable: MCSUser.tableName, where: MCSUser.Properties.userId == userId)
        } catch {
#if DEBUG
            print("MCCUserTableManager getUser error: \(error)")
#endif
            return nil
        }
    }
    ///
    @discardableResult
    public func saveUser(_ user: MCSUser) -> Bool {
        do {
            try database.insertOrReplace(objects: [user], intoTable: MCSUser.tableName)
            return true
        } catch {
#if DEBUG
            print("MCCUserTableManager saveUser error: \(error)")
#endif
            return false
        }
    }
    ///
    public func deleteAllUsers() -> Bool {
        do {
            try database.delete(fromTable: MCSUser.tableName)
            return true
        } catch {
#if DEBUG
            print("MCCUserTableManager deleteAllUsers error: \(error)")
#endif
            return false
        }
    }
    /// 
    public func deleteUser(by userId: String) -> Bool {
        do {
            try database.delete(fromTable: MCSUser.tableName, where: MCSUser.Properties.userId == userId)
            return true
        } catch {
#if DEBUG
            print("MCCUserTableManager deleteUser error: \(error)")
#endif
            return false
        }
    }
}
