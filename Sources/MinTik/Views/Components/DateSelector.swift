import SwiftUI

struct DateSelector: View {
    @Binding var selectedDate: Date
    var textPrimary: Color
    var textSecondary: Color
    var inactiveBlock: Color
    // The earliest date for which activity data exists. Navigation will not go earlier than this.
    var earliestDate: Date?

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var isFuture: Bool {
        selectedDate > Date()
    }

    private var displayText: String {
        if isToday {
            return "今天，\(dateFormatter.string(from: selectedDate))"
        } else {
            return dateFormatter.string(from: selectedDate)
        }
    }
    
    private var canGoPrevious: Bool {
        guard let earliest = earliestDate else { return false }
        return !Calendar.current.isDate(selectedDate, inSameDayAs: earliest)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Previous day button (show only if we can go earlier)
            if canGoPrevious {
                Button(action: previousDay) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textSecondary)
                        .frame(width: 32, height: 32) // larger tap area
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            } else {
                // Invisible spacer to maintain centering
                Color.clear
                    .frame(width: 32, height: 32)
            }

            Spacer()

            // Date display
            Text(displayText)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(textPrimary)

            Spacer()

            // Next day button (only show when not today)
            if !isToday {
                Button(action: nextDay) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isFuture ? textSecondary.opacity(0.3) : textSecondary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .disabled(isFuture)
            } else {
                // Invisible spacer to maintain centering
                Color.clear
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(inactiveBlock.opacity(0.85))
        .cornerRadius(8)
    }

    private func previousDay() {
        if let newDate = Calendar.current.date(byAdding: .day, value: -1, to: selectedDate) {
            // Ensure we do not go before the earliest available date
            if let earliest = earliestDate, newDate < earliest {
                return
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = newDate
            }
        }
    }

    private func nextDay() {
        guard !isToday else { return }
        if let newDate = Calendar.current.date(byAdding: .day, value: 1, to: selectedDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDate = min(newDate, Date())
            }
        }
    }
}
