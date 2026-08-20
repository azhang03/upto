import SwiftUI

// The themed calendar and time panel that opens from a date field.
// The grid is drawn with the app tokens; the time control keeps
// native editing.
struct CalendarPopover: View {
    @Binding var date: Date

    @State private var displayedMonth: Date

    init(date: Binding<Date>) {
        _date = date
        _displayedMonth = State(initialValue: date.wrappedValue)
    }

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            header
            weekdayRow
            dayGrid
            Divider()
                .overlay(Theme.Colors.hairline)
            timeRow
        }
        .padding(Theme.Spacing.l)
        .frame(width: 264)
    }

    private var header: some View {
        HStack {
            monthButton("chevron.left", by: -1)
            Spacer()
            Text(monthTitle)
                .font(Theme.Fonts.control)
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer()
            monthButton("chevron.right", by: 1)
        }
    }

    private func monthButton(_ symbol: String, by value: Int) -> some View {
        Button {
            if let shifted = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
                displayedMonth = shifted
            }
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.Colors.textSecondary)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var weekdayRow: some View {
        HStack(spacing: 0) {
            ForEach(Array(orderedWeekdaySymbols().enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(Theme.Fonts.sectionLabel)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var dayGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
            ForEach(Array(gridDays().enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 26)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: date)
        let isToday = calendar.isDateInToday(day)
        return Button {
            selectDay(day)
        } label: {
            Text("\(calendar.component(.day, from: day))")
                .font(Theme.Fonts.control)
                .foregroundStyle(isSelected ? Theme.Colors.accentText : Theme.Colors.textPrimary)
                .frame(width: 26, height: 26)
                .background(isSelected ? Theme.Colors.accent : .clear, in: Circle())
                .overlay {
                    if isToday && !isSelected {
                        Circle().stroke(Theme.Colors.accentDim, lineWidth: 1)
                    }
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var timeRow: some View {
        HStack {
            SectionHeader("Time")
            Spacer()
            ThemedDatePicker(date: $date, elements: [.hourMinute])
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func orderedWeekdaySymbols() -> [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    // The days of the displayed month, with empty slots so the first
    // day lands on its weekday column.
    private func gridDays() -> [Date?] {
        guard let monthStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: displayedMonth)
        ), let range = calendar.range(of: .day, in: .month, for: monthStart) else {
            return []
        }
        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<range.count {
            days.append(calendar.date(byAdding: .day, value: offset, to: monthStart))
        }
        return days
    }

    // Picking a day keeps the time of day that is already set.
    private func selectDay(_ day: Date) {
        var parts = calendar.dateComponents([.year, .month, .day], from: day)
        let time = calendar.dateComponents([.hour, .minute], from: date)
        parts.hour = time.hour
        parts.minute = time.minute
        if let combined = calendar.date(from: parts) {
            date = combined
        }
    }
}
