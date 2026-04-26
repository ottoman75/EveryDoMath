import SwiftUI
import StoreKit

struct IAPStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var iap = IAPManager.shared
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMsg = ""

    // MARK: - Product 분류

    private var subscriptionProducts: [Product] {
        iap.products.filter {
            $0.id == IAPManager.ProductID.subscriptionYearly ||
            $0.id == IAPManager.ProductID.subscriptionMonthly
        }
        .sorted { $0.price > $1.price } // 연간(높은 가격) 먼저
    }

    private var nonSubscriptionProducts: [Product] {
        iap.products.filter {
            $0.id != IAPManager.ProductID.subscriptionYearly &&
            $0.id != IAPManager.ProductID.subscriptionMonthly
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    header

                    if iap.isLoading {
                        ProgressView()
                            .tint(.appPrimaryStart)
                            .padding(.top, 40)
                    } else if iap.products.isEmpty {
                        emptyState
                    } else {
                        valuePropsRow

                        if !subscriptionProducts.isEmpty {
                            subscriptionSection
                            orDivider
                        }

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
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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

    // MARK: - Value Props Row

    private var valuePropsRow: some View {
        HStack(spacing: 0) {
            propItem(icon: "doc.text.fill", label: "14,000문제")
            Divider().frame(height: 28)
            propItem(icon: "graduationcap.fill", label: "교육과정 연계")
            Divider().frame(height: 28)
            propItem(icon: "person.2.fill", label: "가족 공유")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.appCard))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.appCardBorder, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    private func propItem(icon: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appPrimaryStart)
            Text(verbatim: label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionProducts, id: \.id) { product in
                subscriptionCard(product)
            }
        }
        .padding(.horizontal, 20)
    }

    private func subscriptionCard(_ product: Product) -> some View {
        let isYearly = product.id == IAPManager.ProductID.subscriptionYearly
        let isPurchased = iap.purchasedIds.contains(product.id)

        return VStack(alignment: .leading, spacing: 12) {
            // 상단: 뱃지
            HStack {
                if isYearly {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("iap.free_trial_badge")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.appWarning))
                }
                Spacer()
                if isYearly {
                    Text("iap.best_value")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(LinearGradient(
                            colors: [.appPrimaryStart, .appPrimaryEnd],
                            startPoint: .leading, endPoint: .trailing)))
                }
            }

            // 제목
            Text(verbatim: product.displayName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.appText)

            // 설명
            Text(verbatim: product.description)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.appSubtext)

            // 가격
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(verbatim: product.displayPrice)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
                Text(isYearly ? "iap.per_year" : "iap.per_month")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.appSubtext)
            }

            if isYearly {
                Text("iap.year_equivalent")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.appSubtext)
            }

            // CTA 버튼
            if isPurchased {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                    Text("iap.active_subscription")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.appSuccess)
                )
            } else {
                Button {
                    Task { await buyProduct(product) }
                } label: {
                    Text(isYearly ? "iap.start_free_trial" : "iap.start_subscription")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(LinearGradient(
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
                        .stroke(
                            isYearly ? Color.appPrimaryStart.opacity(0.6) : Color.appCardBorder,
                            lineWidth: isYearly ? 2 : 1
                        )
                )
        )
    }

    // MARK: - Or Divider

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.appCardBorder).frame(height: 1)
            Text("iap.or_individual")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.appSubtext)
                .fixedSize()
            Rectangle().fill(Color.appCardBorder).frame(height: 1)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Product List

    private var productList: some View {
        VStack(spacing: 12) {
            ForEach(nonSubscriptionProducts, id: \.id) { product in
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
