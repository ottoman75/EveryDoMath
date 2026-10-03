import SwiftUI

extension View {
    /// 큰 화면에서 콘텐츠가 통째로 늘어나지 않도록 폭을 묶고 가운데 세운다.
    ///
    /// iPad 를 지원하면 앱은 820pt 가 넘는 캔버스를 받는다. 폰 기준으로 짠
    /// `frame(maxWidth: .infinity)` 들이 그대로 늘어나면 버튼 하나가 화면을
    /// 가로지르고 글자는 가운데 덩그러니 남는다. 읽기 좋은 폭에서 끊고
    /// 남는 공간은 양옆 여백으로 둔다.
    ///
    /// **좁은 화면에서는 아무 일도 하지 않는다.** 폰에서도 프레임을 걸었더니
    /// 홈 콘텐츠가 한 화면을 살짝 넘겨 하단 버튼이 잘렸고, ScreenshotTests 의
    /// 가드가 그것을 잡아냈다. 필요한 곳에만 건다.
    func readableWidth(_ maxWidth: CGFloat = 560) -> some View {
        modifier(ReadableWidth(maxWidth: maxWidth))
    }
}

private struct ReadableWidth: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let maxWidth: CGFloat

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        } else {
            content
        }
    }
}
