import StoreKit

/// 登录成功后调用 `startIfNeeded()`，消费 `Transaction.updates`（核销见 `MCCStoreKitSubscription.syncBillingWithServer`）。
public final class MCCStoreKitTransactionUpdatesObserver {

    public static let shared = MCCStoreKitTransactionUpdatesObserver()

    private var updatesTask: Task<Void, Never>?

    private init() {}

    public func startIfNeeded() {
        guard updatesTask == nil else { return }
        updatesTask = Task(priority: .utility) { await self.consumeUpdatesLoop() }
    }

    private func consumeUpdatesLoop() async {
        for await verification in Transaction.updates {
            if Task.isCancelled { break }
            await process(verification)
        }
    }

    private func process(_ verification: VerificationResult<Transaction>) async {
        let txn: Transaction
        do {
            txn = try MCCStoreKitSubscription.verifiedTransaction(from: verification)
        } catch {
            return
        }
        if txn.revocationDate != nil {
            return
        }
        guard MCCStoreKitSubscription.isSupportedPersistentIAP(txn) else { return }

        let pid = txn.productID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !pid.isEmpty else { return }

        do {
            try await MCCStoreKitSubscription.syncBillingWithServer(productId: pid, transaction: txn)
            await txn.finish()
        } catch {
            // 失败不 finish；无 Toast。
        }
    }
}
