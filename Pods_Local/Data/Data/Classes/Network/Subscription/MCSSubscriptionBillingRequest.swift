//
//  MCSSubscriptionBillingRequest.swift
//

import Foundation

///
public struct MCSSubscriptionBillingRequest: Codable {
    ///
    public init() {}
    /// productId
    public var productId: String = ""
    /// transactionId
    public var transactionId: String = ""
    /// payment
    public var payment: Int = 1
}
