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
