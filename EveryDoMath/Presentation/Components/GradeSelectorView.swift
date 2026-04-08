import SwiftUI

struct GradeSelectorView: View {
    @Binding var selectedGrade: Grade

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Grade.allCases) { grade in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedGrade = grade
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text("\(grade.rawValue)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("학년")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundColor(selectedGrade == grade ? .white : .appSubtext)
                        .frame(width: 64, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    selectedGrade == grade
                                        ? LinearGradient(colors: [.appPrimaryStart, .appPrimaryEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [.appCard, .appCard], startPoint: .top, endPoint: .bottom)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    selectedGrade == grade ? Color.clear : Color.appCardBorder,
                                    lineWidth: 1
                                )
                        )
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
