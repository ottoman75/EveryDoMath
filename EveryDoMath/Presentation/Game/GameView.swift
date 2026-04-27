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
                topBar

                TimerRingView(
                    totalTime: 30.0,
                    remaining: viewModel.remainingTime
                )
                .frame(width: 100, height: 100)

                if viewModel.currentProblemIndex < viewModel.session.problems.count {
                    let problem = viewModel.session.problems[viewModel.currentProblemIndex]
                    ProblemCardView(problemText: problem.displayString)
                        .id(viewModel.currentProblemIndex)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.currentProblemIndex)
                        .padding(.horizontal, 20)
                }

                inputDisplay

                Spacer()

                NumberPadView(
                    input: Bindable(viewModel).currentInput,
                    inputMode: viewModel.currentInputMode,
                    onSubmit: { viewModel.submitAnswer() }
                )
                .padding(.bottom, 8)
            }

            if viewModel.showFeedback {
                let correctAnswer: String = {
                    let idx = viewModel.currentProblemIndex  // feedback 중 인덱스는 아직 미진행
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
                Button("game.quit_button") {
                    showQuitAlert = true
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.appSubtext)
            }
        }
        .alert("game.quit_title", isPresented: $showQuitAlert) {
            Button("game.quit_continue", role: .cancel) { }
            Button("game.quit_confirm", role: .destructive) {
                appState.navigationPath.removeLast(appState.navigationPath.count)
            }
        } message: {
            Text("game.quit_message")
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
            Text(verbatim: "\(viewModel.currentProblemIndex + 1) / \(viewModel.session.problems.count)")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.appSubtext)

            Spacer()

            if viewModel.comboCount > 1 {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.appWarning)
                    Text(verbatim: L("game.combo_format", viewModel.comboCount))
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
