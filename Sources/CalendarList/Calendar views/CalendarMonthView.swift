//
//  CalendarMonthView.swift
//  CalendarList
//
//  Created by Jorge Villalobos Beato on 3/11/20.
//  Copyright © 2020 CalendarList. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct CalendarMonthView<DotsView: View & Equatable>: View {
    let month:CalendarMonth
    let calendar:Calendar
    
    @Binding var selectedDays:[Date]
    @Binding var selectedDayFrames:[CGRect]
    @Binding var isShowingSelectedDayDetails: Bool
    let isSelectingMultipleDays: Bool
    
    let geometry:GeometryProxy
    let isVisible: Bool
    let calendarDayHeight:CGFloat
    
    let dotsViewBuilder: (Date) -> DotsView?
    
    let selectedDateColor:Color
    let todayDateColor:Color
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(self.month.weeks, id:\.self) { week in
                HStack(spacing: 0) {
                    ForEach(getRangeForMarginsTop(week: week), id:\.self) { num in
                        Text("").frame(maxWidth: .infinity, idealHeight: self.calendarDayHeight, alignment: .center)
                    }

                    ForEach(week, id:\.self) { day in
                        let dayStart = CalendarUtils.resetHourPart(of: day, calendar:self.calendar)
                        let isSelected = selectedDays.contains(day)
                        CalendarViewDay(
                            calendar: self.calendar,
                            day: day,
                            selected: isSelected,
                            height: self.calendarDayHeight,
                            selectedDateColor: self.selectedDateColor,
                            todayDateColor: self.todayDateColor,
                            dotsView: self.dotsViewBuilder(dayStart))
                        .equatable()
                        .anchorPreference(key: BoundsPreferences<Date>.self, value: .bounds) {
                            [day: geometry[$0]]
                        }.opacity(isShowingSelectedDayDetails && !selectedDays.contains(day) ? 0.4 : 1)
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
                        Text("").frame(maxWidth: .infinity, idealHeight: self.calendarDayHeight, alignment: .center)
                    }
                }
            }
        }.contentShape(Rectangle())
        .onPreferenceChange(BoundsPreferences<Date>.self) { newValue in
            if isVisible {
                DispatchQueue.main.async {
                    dayFrames = newValue
                }
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
    private var dayFrames: [Date: CGRect] = [:]
}

private struct BoundsPreferences<Item: Hashable>: PreferenceKey {
    static var defaultValue: [Item: CGRect] { [:] }

    static func reduce(value: inout [Item: CGRect], nextValue: () -> [Item: CGRect]) {
        value.merge(nextValue()) { $1 }
    }
}
