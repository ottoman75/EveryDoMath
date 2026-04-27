import SwiftUI

struct GradeSelectorView: View {
    @Binding var selectedGrade: Grade
    var onLockedTapped: (() -> Void)? = nil
    var allowLockedSelection: Bool = false

    @State private var iap = IAPManager.shared

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Grade.allCases) { grade in
                    let isUnlocked = iap.isGradeUnlocked(grade)
                    let isSelected = selectedGrade == grade

                    Button {
                        if isUnlocked || TrialManager.isTrialAvailable(for: grade) || allowLockedSelection {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedGrade = grade
                            }
                        } else {
                            onLockedTapped?()
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(grade.rawValue)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("학년")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(isSelected ? .white : (isUnlocked ? .appSubtext : .appSubtext.opacity(0.5)))
                        .frame(width: 64, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    isSelected
                                        ? LinearGradient(colors: [.appPrimaryStart, .appPrimaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [.appCard, .appCard], startPoint: .top, endPoint: .bottom)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? Color.clear : Color.appCardBorder,
                                    lineWidth: 1
                                )
                        )
                        .overlay(alignment: .topTrailing) {
                            if !isUnlocked {
                                if TrialManager.isTrialAvailable(for: grade) {
                                    Text("trial.label")
                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.appSuccess))
                                        .padding(4)
                                } else {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(3)
                                        .background(Circle().fill(Color.appSubtext.opacity(0.8)))
                                        .padding(4)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    GradeSelectorView(selectedGrade: .constant(.grade3))
        .padding(.vertical)
        .background(Color.appBackground)
}
