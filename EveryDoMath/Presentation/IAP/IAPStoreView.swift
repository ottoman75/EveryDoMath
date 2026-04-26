import SwiftUI
import StoreKit

struct IAPStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var iap = IAPManager.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMsg = ""

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header

                    if iap.isLoading {
                        ProgressView()
                            .tint(.appPrimaryStart)
                            .padding(.top, 40)
                    } else if iap.products.isEmpty {
                        emptyState
                    } else {
                        productList
                    }

                    restoreButton

                    Text("iap.legal_notice")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundColor(.appSubtext.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
                .padding(.top, 8)
            }
        }
        .task { await iap.loadProducts() }
        .alert("iap.error_title", isPresented: $showError) {
            Button("common.confirm", role: .cancel) { }
        } message: {
            Text(verbatim: errorMsg)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.appPrimaryStart, .appPrimaryEnd],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
            }

            Text("iap.title")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            Text("iap.subtitle")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundColor(.appSubtext)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.top, 16)
    }

    // MARK: - Product List

    private var productList: some View {
        VStack(spacing: 12) {
            ForEach(iap.products, id: \.id) { product in
                productCard(product)
            }
        }
        .padding(.horizontal, 20)
    }

    private func productCard(_ product: Product) -> some View {
        let isAllGrades = product.id == IAPManager.ProductID.allGrades
        let isPurchased = iap.purchasedIds.contains(product.id)

        return HStack(spacing: 16) {
            // 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isAllGrades
                          ? LinearGradient(colors: [.appPrimaryStart, .appPrimaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                          : LinearGradient(colors: [.appCard, .appCard], startPoint: .top, endPoint: .bottom))
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isAllGrades ? Color.clear : Color.appCardBorder, lineWidth: 1)
                    )
                Image(systemName: isAllGrades ? "star.fill" : "lock.open.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(isAllGrades ? .white : .appPrimaryStart)
            }

            // 설명
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: product.displayName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.appText)
                Text(verbatim: product.description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.appSubtext)
                    .lineLimit(2)
            }

            Spacer()

            // 가격 / 구매 버튼
            if isPurchased {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.appSuccess)
            } else {
                Button {
                    Task { await buyProduct(product) }
                } label: {
                    Text(verbatim: product.displayPrice)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(LinearGradient(
                                colors: [.appPrimaryStart, .appPrimaryEnd],
                                startPoint: .leading, endPoint: .trailing))
                        )
                }
                .disabled(isPurchasing)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(isAllGrades ? Color.appPrimaryStart.opacity(0.5) : Color.appCardBorder, lineWidth: isAllGrades ? 1.5 : 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            if isAllGrades {
                Text("iap.best_value")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.appWarning))
                    .offset(x: -12, y: -10)
            }
        }
    }

    // MARK: - Empty / Restore

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundColor(.appSubtext)
            Text("iap.load_failed")
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(.appSubtext)
            Button("iap.retry") {
                Task { await iap.loadProducts() }
            }
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(.appPrimaryStart)
        }
        .padding(.top, 40)
    }

    private var restoreButton: some View {
        Button {
            Task {
                await iap.restorePurchases()
            }
        } label: {
            Text("iap.restore")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
                .underline()
        }
        .padding(.top, 4)
    }

    // MARK: - Purchase Action

    private func buyProduct(_ product: Product) async {
        isPurchasing = true
        do {
            let purchased = try await iap.purchase(product)
            if purchased { dismiss() }
        } catch {
            errorMsg = error.localizedDescription
            showError = true
        }
        isPurchasing = false
    }
}
