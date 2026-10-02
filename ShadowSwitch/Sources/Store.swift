import StoreKit
import SwiftUI

enum ProductID {
    static let pass = "com.connexa.shadowswitch.pass_s1"
    static let starter = "com.connexa.shadowswitch.starter"
    static let shardsS = "com.connexa.shadowswitch.shards_s"
    static let shardsL = "com.connexa.shadowswitch.shards_l"
    static let all = [pass, starter, shardsS, shardsL]
    static let fallbackPrice: [String: String] = [pass: "$4.99", starter: "$1.99", shardsS: "$0.99", shardsL: "$4.99"]
}

@MainActor
final class Store: ObservableObject {
    @Published var products: [String: Product] = [:]
    @Published var busy = false
    @Published var message: String?
    private let progress: PlayerData
    private var updates: Task<Void, Never>?

    init(progress: PlayerData) {
        self.progress = progress
        updates = Task { [weak self] in
            for await result in StoreKit.Transaction.updates {
                await self?.handle(result)
            }
        }
        Task { await load(); await syncEntitlements() }
    }
    deinit { updates?.cancel() }

    func price(_ id: String) -> String {
        products[id]?.displayPrice ?? ProductID.fallbackPrice[id] ?? "—"
    }
    var available: Bool { !products.isEmpty }

    func load() async {
        do {
            let list = try await Product.products(for: ProductID.all)
            products = Dictionary(uniqueKeysWithValues: list.map { ($0.id, $0) })
        } catch {
            message = "Store unavailable. Please try again later."
        }
    }

    func buy(_ id: String) async {
        if products.isEmpty { await load() }
        guard let product = products[id] else {
            message = "This item is not available right now."
            return
        }
        busy = true
        defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(let result): await handle(result)
            case .pending: message = "Purchase pending approval."
            case .userCancelled: break
            @unknown default: break
            }
        } catch {
            message = "Purchase failed. You were not charged."
        }
    }

    func restore() async {
        busy = true
        defer { busy = false }
        do {
            try await AppStore.sync()
            await syncEntitlements()
            message = "Purchases restored."
        } catch {
            message = "Could not restore purchases."
        }
    }

    private func handle(_ result: VerificationResult<StoreKit.Transaction>) async {
        guard case .verified(let t) = result else { return }
        switch t.productID {
        case ProductID.pass: progress.d.passPremium = true
        case ProductID.starter: progress.applyStarter()
        case ProductID.shardsS: progress.d.shards += 600
        case ProductID.shardsL: progress.d.shards += 4000
        default: break
        }
        await t.finish()
        Sfx.play(.reward)
    }

    private func syncEntitlements() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let t) = result else { continue }
            if t.productID == ProductID.pass { progress.d.passPremium = true }
            if t.productID == ProductID.starter { progress.applyStarter() }
        }
    }
}
