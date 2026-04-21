import SwiftUI

struct DayPickerView: View {
    @Binding var selectedDays: [Int]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var onChange: (() -> Void)?

    private let daySymbols = ["S", "M", "T", "W", "T", "F", "S"]
    private let fullDayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        VStack(spacing: isPad ? 12 : 8) {
            HStack(spacing: isPad ? 12 : 8) {
                ForEach(0..<7, id: \.self) { index in
                    dayButton(for: index)
                }
            }

            Text(selectionDescription)
                .font(.system(size: descriptionFontSize))
                .foregroundColor(.secondary)
        }
    }

    private func dayButton(for index: Int) -> some View {
        let isSelected = selectedDays.contains(index)
        return Button {
            toggleDay(index)
            onChange?()
            HapticService.shared.selection()
        } label: {
            Text(daySymbols[index])
                .font(.system(size: dayFontSize, weight: .semibold))
                .frame(width: dayButtonSize, height: dayButtonSize)
                .background(isSelected ? Color.accentColor : Color.gray.opacity(0.15))
                .foregroundColor(isSelected ? .white : .secondary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(fullDayNames[index])
        .accessibilityHint(isSelected ? "Selected" : "Not selected")
    }

    private func toggleDay(_ index: Int) {
        if selectedDays.contains(index) {
            selectedDays.removeAll { $0 == index }
        } else {
            selectedDays.append(index)
            selectedDays.sort()
        }
    }

    private var selectionDescription: String {
        switch selectedDays.sorted() {
        case []: return "Once"
        case [0, 6]: return "Weekends"
        case [1, 2, 3, 4, 5]: return "Weekdays"
        case [0, 1, 2, 3, 4, 5, 6]: return "Every Day"
        default:
            let names = selectedDays.sorted().map { fullDayNames[$0] }
            return names.joined(separator: ", ")
        }
    }

    private var isPad: Bool { horizontalSizeClass == .regular }
    private var dayButtonSize: CGFloat { isPad ? 44 : 36 }
    private var dayFontSize: CGFloat { isPad ? 16 : 14 }
    private var descriptionFontSize: CGFloat { isPad ? 14 : 12 }
}

#Preview {
    struct PreviewWrapper: View {
        @State var days1: [Int] = []
        @State var days2: [Int] = [1, 2, 3, 4, 5]
        @State var days3: [Int] = [0, 6]
        @State var days4: [Int] = [0, 1, 2, 3, 4, 5, 6]

        var body: some View {
            VStack(spacing: 24) {
                VStack {
                    Text("Once (no selection)")
                    DayPickerView(selectedDays: $days1)
                }
                VStack {
                    Text("Weekdays")
                    DayPickerView(selectedDays: $days2)
                }
                VStack {
                    Text("Weekends")
                    DayPickerView(selectedDays: $days3)
                }
                VStack {
                    Text("Every Day")
                    DayPickerView(selectedDays: $days4)
                }
            }
            .padding()
        }
    }
    return PreviewWrapper()
}
