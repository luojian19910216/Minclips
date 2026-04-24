//
//  MCENetworkError.swift
//

import Foundation

///
public enum MCENetworkCode: Int {
    ///
    case success = 0
    ///
    case loginExpired = 10004
    ///
    case tokenExpired = 10005
}

///
public enum MCENetworkError: Error {
    ///
    case parseError(String)
    ///
    case underlying(Error)
    ///
    case invalidStatusCode(Int)
    ///
    case serverError(code: Int, message: String?)
    ///
    case serverMaintenance(Int)
    ///
    case loginExpired
    ///
    case tokenExpired
}

extension MCENetworkError: LocalizedError {
    ///
    public var errorDescription: String? {
        switch self {
        case .parseError:
            return "Data parsing error"
        case .underlying(let error):
            if let urlError = error as? URLError {
                return "Network error (\(urlError.code.rawValue))"
            }
            let nsError = error as NSError
            return "Network error: \(nsError.code)"
        case .invalidStatusCode(let code):
            return "Network error: \(code)"
        case .serverError(let code, let message):
            return (message ?? "Server error") + ": \(code)"
        case .serverMaintenance(let code):
            return "The server is under maintenance: \(code)"
        case .loginExpired:
            return "Login expired."
        case .tokenExpired:
            return "Token expired."
        }
    }
}
