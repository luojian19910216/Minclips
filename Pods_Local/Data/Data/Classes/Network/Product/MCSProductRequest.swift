//
//  ProductRequestModel.swift
//

import Foundation

///
public struct MCSProductPayCallbackRequest: Codable {
    ///
    public init() {}
    /// productId
    public var productKey: String = ""
    /// transactionId
    public var txnId: String = ""
    /// payment
    public var payPayload: Int = 1
}
