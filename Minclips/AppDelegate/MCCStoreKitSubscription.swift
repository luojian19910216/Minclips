import Common
import Combine
import Data
import StoreKit

// MARK: - 订阅 / Restore / 服务端核销（billingNotify）

/// StoreKit 2 与各界面订阅、恢复的**唯一**业务入口：`purchase`、`restorePurchases`、`syncBillingWithServer`（`billingNotify` + `finish`）。
///
/// **`Transaction.updates`**：由 `MCCStoreKitTransactionUpdatesObserver` 监听；须在登录成功后调用其 `startIfNeeded()`。
public enum MCCStoreKitSubscription {

    public enum PurchaseOutcome: Equatable {
        /// 已核销并成功 `finish`
        case activated
        case userCancelled
        case pendingApproval
        case unrecognizedPurchaseResult
    }

    public enum PurchaseFailure: Error, Equatable {
        case emptyProductId
        case productUnavailable
        case unsupportedProductType
        case transactionRevokedOrInvalid
        /// 服务端核销失败；`userFacingMessage` 适合直接 Toast。
        case serverSyncUnderlying(String)
        case storeUnderlying(String)

        public var userFacingMessage: String {
            switch self {
            case .emptyProductId: return "Plan unavailable."
            case .productUnavailable: return "Product not available from App Store."
            case .unsupportedProductType: return "Unsupported product type."
            case .transactionRevokedOrInvalid: return "This purchase is no longer valid."
            case .serverSyncUnderlying(let m): return m
            case .storeUnderlying(let m): return m
            }
        }
    }

    public enum RestoreFailure: Error, Equatable {
        case storeUnderlying(String)
        case serverSyncUnderlying(String)

        public var userFacingMessage: String {
            switch self {
            case .storeUnderlying(let m): return m
            case .serverSyncUnderlying(let m): return m
            }
        }
    }

    public static func verifiedTransaction(from result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(_, let err):
            throw err
        case .verified(let t):
            return t
        }
    }

    public static func isSupportedPersistentIAP(_ product: Product) -> Bool {
        product.type == .autoRenewable || product.type == .nonRenewable || product.type == .nonConsumable
    }

    public static func isSupportedPersistentIAP(_ transaction: Transaction) -> Bool {
        transaction.productType == .autoRenewable
            || transaction.productType == .nonRenewable
            || transaction.productType == .nonConsumable
    }

    /// `billingNotify`；成功后会 `updateCurrentUser`。
    public static func syncBillingWithServer(productId: String, transaction: Transaction) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            var token: AnyCancellable?
            var finished = false
            var rq = MCSSubscriptionBillingRequest()
            rq.productKey = productId.trimmingCharacters(in: .whitespacesAndNewlines)
            rq.txnId = String(transaction.id)
            rq.payPayload = 1
            token = MCCSubscriptionAPIManager.shared.billingNotify(with: rq)
                .receive(on: DispatchQueue.main)
                .sink(
                    receiveCompletion: { completion in
                        defer { token = nil }
                        switch completion {
                        case .failure(let err):
                            guard !finished else { return }
                            finished = true
                            cont.resume(throwing: err)
                        case .finished:
                            guard !finished else { return }
                            finished = true
                            cont.resume(throwing: MCENetworkError.parseError("Billing response missing"))
                        }
                    },
                    receiveValue: { user in
                        defer { token = nil }
                        guard !finished else { return }
                        finished = true
                        MCCAccountService.shared.updateCurrentUser(user)
                        cont.resume(returning: ())
                    }
                )
        }
    }

    /// 购买：拉 `Product`、`purchase`、`billingNotify`、`finish`。在 **MainActor**（有 UI Toast）环境下调用。
    @MainActor
    public static func purchase(productId rawId: String) async -> Result<PurchaseOutcome, PurchaseFailure> {
        let pid = rawId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pid.isEmpty else { return .failure(.emptyProductId) }
        do {
            let products = try await Product.products(for: [pid])
            guard let product = products.first(where: { $0.id == pid }) else {
                return .failure(.productUnavailable)
            }
            guard isSupportedPersistentIAP(product) else {
                return .failure(.unsupportedProductType)
            }
            let purchaseResult = try await product.purchase()
            switch purchaseResult {
            case .success(let verification):
                let txn: Transaction
                do {
                    txn = try verifiedTransaction(from: verification)
                } catch {
                    return .failure(.storeUnderlying((error as? LocalizedError)?.errorDescription ?? error.localizedDescription))
                }
                if txn.revocationDate != nil {
                    return .failure(.transactionRevokedOrInvalid)
                }
                do {
                    try await syncBillingWithServer(productId: pid, transaction: txn)
                    await txn.finish()
                    return .success(.activated)
                } catch {
                    let m = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    return .failure(.serverSyncUnderlying(m))
                }
            case .userCancelled:
                return .success(.userCancelled)
            case .pending:
                return .success(.pendingApproval)
            @unknown default:
                return .success(.unrecognizedPurchaseResult)
            }
        } catch {
            return .failure(.storeUnderlying((error as? LocalizedError)?.errorDescription ?? error.localizedDescription))
        }
    }

    /// `AppStore.sync()` 后遍历 `currentEntitlements` 并逐条核销。
    /// - Parameter filterProductIds: `nil` 或空集：不限制；否则只处理集合内 `productID`。
    @MainActor
    public static func restorePurchases(filterProductIds: Set<String>? = nil) async -> Result<Int, RestoreFailure> {
        let filter: Set<String>? = {
            guard let s = filterProductIds, !s.isEmpty else { return nil }
            return s
        }()
        do {
            try await AppStore.sync()
        } catch {
            let m = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return .failure(.storeUnderlying(m))
        }
        var count = 0
        do {
            for await verification in Transaction.currentEntitlements {
                let txn = try verifiedTransaction(from: verification)
                if txn.revocationDate != nil { continue }
                guard isSupportedPersistentIAP(txn) else { continue }
                let productId = txn.productID.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !productId.isEmpty else { continue }
                if let filter, !filter.contains(productId) { continue }
                do {
                    try await syncBillingWithServer(productId: productId, transaction: txn)
                    await txn.finish()
                    count += 1
                } catch {
                    let m = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
                    return .failure(.serverSyncUnderlying(m))
                }
            }
        } catch {
            let m = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            return .failure(.storeUnderlying(m))
        }
        return .success(count)
    }
}
