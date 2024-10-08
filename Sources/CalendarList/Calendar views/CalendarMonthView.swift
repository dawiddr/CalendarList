//
//  CalendarMonthView.swift
//  CalendarList
//
//  Created by Jorge Villalobos Beato on 3/11/20.
//  Copyright © 2020 CalendarList. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct CalendarMonthView<DotsView: View & Equatable & Sendable>: View {
    let month:CalendarMonth
    let calendar:Calendar
    
    @Binding var selectedDays:[Date]
    @Binding var selectedDayFrames:[Anchor<CGRect>]
    @Binding var isShowingSelectedDayDetails: Bool
    let isSelectingMultipleDays: Bool
    let isVisible: Bool
    let dotsViewBuilder: (Date) -> DotsView?
    let selectedDateColor:Color
    let todayDateColor:Color
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(self.month.weeks, id:\.self) { week in
                HStack(spacing: 0) {
                    ForEach(getRangeForMarginsTop(week: week), id:\.self) { num in
                        Text("")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .accessibilityHidden(true)
                    }

                    ForEach(week, id:\.self) { day in
                        let isSelected = selectedDays.contains(day)
                        CalendarViewDay(
                            calendar: self.calendar,
                            day: day,
                            selected: isSelected,
                            selectedDateColor: self.selectedDateColor,
                            todayDateColor: self.todayDateColor,
                            dotsView: self.dotsViewBuilder(day))
                        .equatable()
                        .anchorPreference(key: BoundsPreferences<Date>.self, value: .bounds) {
                            [day: $0]
                        }.opacity(isShowingSelectedDayDetails && !selectedDays.contains(day) ? 0.4 : 1)
                        .accessibilityAddTraits(.isButton)
                        .onTapGesture {
                            guard let dayFrame = dayFrames[day] else {
                                return
                            }
                            
                            if isSelectingMultipleDays {
                                if selectedDays.contains(day) {
                                    selectedDays.removeAll { $0 == day }
                                    selectedDayFrames.removeAll { $0 == dayFrame }
                                } else {
                                    selectedDays.append(day)
                                    selectedDayFrames.append(dayFrame)
                                }
                            } else {
                                if isShowingSelectedDayDetails, selectedDays.contains(day) {
                                    selectedDays = []
                                    isShowingSelectedDayDetails = false
                                } else {
                                    selectedDays = [day]
                                    selectedDayFrames = [dayFrame]
                                    isShowingSelectedDayDetails = true
                                }
                            }
                        }
                    }
                    
                    ForEach(getRangeForMarginsBottom(week: week), id:\.self) { num in
                        Text("")
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .accessibilityHidden(true)
                    }
                }
            }
        }.contentShape(Rectangle())
        .accessibilityHidden(!isVisible)
        .onPreferenceChange(BoundsPreferences<Date>.self) { newValue in
            if isVisible {
                dayFrames = newValue
            }
        }
    }

    private func getRangeForMarginsTop(week: [Date]) -> Range<Int> {
        if week.count < 7 && self.containsFirstDayOfMonth(week) {
            let diff = 7 - week.count
            return 1..<diff+1
        }
        return 0..<0
    }

    private func getRangeForMarginsBottom(week: [Date]) -> Range<Int> {
        if week.count < 7 && !self.containsFirstDayOfMonth(week) {
            let diff = 7 - week.count
            return 1..<diff+1
        }
        return 0..<0
    }
    
    private func containsFirstDayOfMonth(_ dates:[Date]) -> Bool {
        return dates.contains { (date) -> Bool in
            calendar.component(.day, from: date) == 1
        }
    }
    
    @State
    private var dayFrames: [Date: Anchor<CGRect>] = [:]
}

private struct BoundsPreferences<Item: Hashable>: PreferenceKey {
    static var defaultValue: [Item: Anchor<CGRect>] { [:] }

    static func reduce(value: inout [Item: Anchor<CGRect>], nextValue: () -> [Item: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}
