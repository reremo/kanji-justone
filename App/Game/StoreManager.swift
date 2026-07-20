import Foundation
import Observation
import StoreKit

/// 買い切り「全部解除パック」の StoreKit 2 窓口。
/// ローカル検証は Products.storekit（スキームに設定済み）で可能。
@MainActor
@Observable
final class StoreManager {
    static let productID = "com.reremo.kanjijustone.unlockall"

    private(set) var product: Product?
    private(set) var purchasing = false
    var lastError: String?

    /// 権利状態が変わったときに呼ばれる（AppState.purchased を更新する）
    var onEntitlementChange: ((Bool) -> Void)?

    private var updatesTask: Task<Void, Never>?

    func start() {
        updatesTask = Task {
            for await update in Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                }
                await refreshEntitlement()
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlement()
        }
    }

    func loadProduct() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    func refreshEntitlement() async {
        var owned = false
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement,
               transaction.productID == Self.productID {
                owned = true
            }
        }
        onEntitlementChange?(owned)
    }

    func purchase() async {
        guard let product, !purchasing else { return }
        purchasing = true
        defer { purchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    onEntitlementChange?(true)
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = "購入を完了できませんでした。通信環境を確認して、もう一度お試しください"
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }
}
