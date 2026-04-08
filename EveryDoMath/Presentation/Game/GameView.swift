import SwiftUI

struct GameView: View {
    let session: GameSession
    @State private var viewModel: GameViewModel
    @Environment(AppState.self) private var appState

    @State private var showQuitAlert = false

    init(session: GameSession) {
        self.session = session
        _viewModel = State(initialValue: GameViewModel(session: session))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                // 상단: 문제 번호 + 콤보
                topBar

                // 타이머
                TimerRingView(
                    totalTime: 30.0,
                    remaining: viewModel.remainingTime
                )
                .frame(width: 100, height: 100)

                // 문제 카드
                if viewModel.currentProblemIndex < viewModel.session.problems.count {
                    let problem = viewModel.session.problems[viewModel.currentProblemIndex]
                    ProblemCardView(problemText: problem.displayString)
                        .id(viewModel.currentProblemIndex)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentProblemIndex)
                        .padding(.horizontal, 20)
                }

                // 입력값 표시
                inputDisplay

                Spacer()

                // 숫자 패드
                NumberPadView(
                    input: Bindable(viewModel).currentInput,
                    inputMode: viewModel.currentInputMode,
                    onSubmit: { viewModel.submitAnswer() }
                )
                .padding(.bottom, 8)
            }

            // 피드백 오버레이
            if viewModel.showFeedback {
                let correctAnswer: String = {
                    let idx = max(0, viewModel.currentProblemIndex - 1)
                    if idx < viewModel.session.problems.count {
                        return viewModel.session.problems[idx].answerDisplayString
                    }
                    return ""
                }()

                FeedbackOverlayView(
                    isCorrect: viewModel.lastAnswerCorrect,
                    earnedScore: viewModel.earnedScore,
                    correctAnswer: correctAnswer
                )
                .allowsHitTesting(false)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("포기") {
                    showQuitAlert = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appSubtext)
            }
        }
        .alert("게임을 포기하시겠습니까?", isPresented: $showQuitAlert) {
            Button("계속하기", role: .cancel) { }
            Button("포기", role: .destructive) {
                appState.navigationPath.removeLast(appState.navigationPath.count)
            }
        } message: {
            Text("현재 진행 상황이 모두 사라집니다.")
        }
        .onChange(of: viewModel.isGameFinished) { _, finished in
            if finished {
                appState.navigationPath.append(AppDestination.result(viewModel.session))
            }
        }
        .onAppear {
            viewModel.startGame()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // 문제 번호
            Text("\(viewModel.currentProblemIndex + 1) / \(GameSession.problemCount)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.appSubtext)

            Spacer()

            // 콤보
            if viewModel.comboCount > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.appWarning)
                    Text("\(viewModel.comboCount) combo")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.appWarning)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: viewModel.comboCount)
    }

    // MARK: - Input Display

    private var inputDisplay: some View {
        Text(viewModel.currentInput.isEmpty ? "?" : viewModel.currentInput)
            .font(.system(size: 48, weight: .bold, design: .rounded))
            .foregroundColor(viewModel.currentInput.isEmpty ? .appSubtext.opacity(0.4) : .appText)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appCardBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 20)
    }
}
