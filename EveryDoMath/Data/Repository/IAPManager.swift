import Foundation
import StoreKit

@Observable
final class IAPManager {
    static let shared = IAPManager()

    // App Store Connect에 등록할 Product ID
    enum ProductID {
        static let grade3 = "com.everydomath.grade3unlock"
        static let grade4 = "com.everydomath.grade4unlock"
        static let grade5 = "com.everydomath.grade5unlock"
        static let grade6 = "com.everydomath.grade6unlock"
        static let allGrades = "com.everydomath.allgrades"

        static var all: [String] { [grade3, grade4, grade5, grade6, allGrades] }

        static func gradeId(for grade: Grade) -> String? {
            switch grade {
            case .grade3: return grade3
            case .grade4: return grade4
            case .grade5: return grade5
            case .grade6: return grade6
            default: return nil
            }
        }
    }

    var products: [Product] = []
    var purchasedIds: Set<String> = []
    var isLoading = false
    var errorMessage: String? = nil

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
        Task { await updatePurchasedProducts() }
    }

    deinit { updateListenerTask?.cancel() }

    // MARK: - 학년 잠금 여부

    func isGradeUnlocked(_ grade: Grade) -> Bool {
        if grade.isFree { return true }
        if purchasedIds.contains(ProductID.allGrades) { return true }
        if let id = ProductID.gradeId(for: grade) {
            return purchasedIds.contains(id)
        }
        return false
    }

    // MARK: - 상품 로딩

    func loadProducts() async {
        isLoading = true
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ [IAP] 상품 로딩 실패: \(error)")
        }
        isLoading = false
    }

    // MARK: - 구매

    @discardableResult
    func purchase(_ product: Product) async throws -> Bool {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - 구매 복원

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            print("❌ [IAP] 복원 실패: \(error)")
        }
    }

    // MARK: - Private

    @MainActor
    func updatePurchasedProducts() async {
        var ids = Set<String>()
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result {
                ids.insert(tx.productID)
            }
        }
        purchasedIds = ids
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result {
                    await self?.updatePurchasedProducts()
                    await tx.finish()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified: throw IAPError.failedVerification
        case .verified(let value): return value
        }
    }

    enum IAPError: LocalizedError {
        case failedVerification
        var errorDescription: String? { "구매 검증에 실패했습니다." }
    }
}
