import SwiftUI

struct GoalSettingsView: View {
    @Binding var goal: LearningGoal
    var onSave: (LearningGoal) -> Void

    @State private var draft: LearningGoal

    init(goal: Binding<LearningGoal>, onSave: @escaping (LearningGoal) -> Void) {
        _goal = goal
        self.onSave = onSave
        _draft = State(initialValue: goal.wrappedValue)
    }

    private var reminderTime: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(
                    bySettingHour: draft.reminderHour,
                    minute: draft.reminderMinute,
                    second: 0,
                    of: Date()
                ) ?? Date()
            },
            set: { date in
                draft.reminderHour = Calendar.current.component(.hour, from: date)
                draft.reminderMinute = Calendar.current.component(.minute, from: date)
            }
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                settingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("goal.settings.daily_target", systemImage: "gamecontroller.fill")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.appText)

                        HStack {
                            Text(verbatim: L("goal.settings.daily_value", draft.dailySessionTarget))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.appPrimaryStart)
                                .frame(width: 80, alignment: .center)

                            Stepper("", value: $draft.dailySessionTarget, in: 1...10)
                                .labelsHidden()
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                settingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("goal.settings.grade_target", systemImage: "graduationcap.fill")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.appText)

                        HStack(spacing: 8) {
                            ForEach(Grade.allCases) { grade in
                                Button {
                                    draft.gradeTarget = grade
                                } label: {
                                    Text(verbatim: grade.label)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(draft.gradeTarget == grade ? .white : .appSubtext)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule().fill(
                                                draft.gradeTarget == grade ? Color.appPrimaryStart : Color.appCard
                                            )
                                        )
                                }
                            }
                        }
                    }
                }

                settingCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("goal.settings.reminder", systemImage: "bell.fill")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.appText)
                            Spacer()
                            Toggle("", isOn: $draft.isReminderEnabled)
                                .labelsHidden()
                                .tint(.appPrimaryStart)
                        }

                        if draft.isReminderEnabled {
                            DatePicker(
                                "goal.settings.reminder_time",
                                selection: reminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(.appText)
                            .tint(.appPrimaryStart)
                        }
                    }
                }

                Button {
                    onSave(draft)
                } label: {
                    Text("goal.settings.save")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [.appPrimaryStart, .appPrimaryEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(20)
        }
    }

    private func settingCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCard)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appCardBorder, lineWidth: 1))
            )
    }
}
