//
//  ProductRequestModel.swift
//

import Foundation

///
public struct MCSProductPayCallbackRequest: Codable {
    ///
    public init() {}
    ///
    public var productId: String = ""
    ///
    public var transactionId: String = ""
    ///
    public var payment: Int = 1
}
