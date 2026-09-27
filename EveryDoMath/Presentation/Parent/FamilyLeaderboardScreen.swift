import SwiftUI

/// 가족 리더보드 단독 화면.
///
/// 원래 부모 대시보드의 탭이었는데, 형제·부모와 점수를 겨루는 **아이 기능**이라
/// 부모 게이트 뒤에 둘 이유가 없었다. 홈에서 바로 들어온다.
///
/// 내용은 FamilyLeaderboardView 가 그대로 담당하고, 여기서는 화면 골격과
/// 데이터 로딩만 맡는다.
struct FamilyLeaderboardScreen: View {
    @State private var viewModel = ParentDashboardViewModel()
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()
            FamilyLeaderboardView(viewModel: viewModel)
        }
        .navigationTitle("family.screen_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            Task { await viewModel.loadFamilyGroup() }
        }
    }
}
