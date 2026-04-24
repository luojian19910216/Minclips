//
//  MCCLoggerPlugin.swift
//

import Foundation
import Moya

///
public final class MCCLoggerPlugin: PluginType {
    ///
    private var startTime: [Int: Date] = [:]
    ///
    public init() {}
    ///
    public func willSend(_ request: RequestType, target: TargetType) {
        guard let req = request.request else { return }
        startTime[req.hashValue] = Date()
    }
    ///
    public func didReceive(_ result: Result<Response, MoyaError>, target: TargetType) {
#if DEBUG
        switch result {
        case .success(let response):
            guard let request = response.request else { return }
            
            let key = request.hashValue
            let duration = startTime[key].map { Date().timeIntervalSince($0) } ?? 0
            startTime.removeValue(forKey: key)
            
            print("""
            🚀 NETWORK
            ----------------------------------------
            \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")
            ⏱ Time: \(String(format: "%.3f", duration))s
            Status: \(response.statusCode)
            """)
            
            if let headers = request.allHTTPHeaderFields {
                print("📤 Headers:")
                headers.forEach { print("   \($0): \($1)") }
            }
            
            if let body = request.httpBody,
               let bodyStr = String(data: body, encoding: .utf8) {
                print("📤 Body:")
                print(bodyStr)
            }
            
            print("📥 Response:")
            
            if let json = try? response.mapJSON(),
               let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            } else if let str = String(data: response.data, encoding: .utf8) {
                print(str)
            }
            
            print("----------------------------------------\n")
        case .failure(let error):
            print("""
            ❌ NETWORK ERROR
            \(target.path)
            \(error)
            """)
        }
#endif
    }
}
