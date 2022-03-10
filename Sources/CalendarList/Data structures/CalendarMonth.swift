//
//  CalendarMonth.swift
//  CalendarList
//
//  Created by Jorge Villalobos Beato on 3/11/20.
//  Copyright © 2020 CalendarList. All rights reserved.
//

import Foundation

public struct CalendarMonth: Equatable {
    public var calendar:Calendar
    public var actualDate:Date
    
    public var weeks:[[Date]]
    
    public init(calendar:Calendar, actualDate:Date, weeks:[[Date]]) {
        self.calendar = calendar
        self.actualDate = actualDate
        self.weeks = weeks
    }
    
    public func nextMonth() -> CalendarMonth {
        let date = calendar.date(byAdding: .month, value: 1, to: actualDate)
        return CalendarUtils.getCalendarMonthFor(date: date!, calendar: calendar)
    }
    
    public func previousMonth() -> CalendarMonth {
        let date = calendar.date(byAdding: .month, value: -1, to: actualDate)
        return CalendarUtils.getCalendarMonthFor(date: date!, calendar: calendar)
    }
    
    public func getSurroundingMonths() -> [CalendarMonth] {
        return [
            self.previousMonth(),
            CalendarMonth(calendar: self.calendar, actualDate: self.actualDate, weeks: self.weeks),
            self.nextMonth()
        ]
    }
    
    public func monthTitle() -> String {
        let title = titleFormatter.string(from: actualDate)
        return title.prefix(1).uppercased() + title.dropFirst()
    }
    
    public static func getSurroundingMonths(forDate date:Date, andCalendar calendar:Calendar) -> [CalendarMonth] {
        let calendarMonth = CalendarUtils.getCalendarMonthFor(date: date, calendar: calendar)
        return [
            calendarMonth.previousMonth(),
            calendarMonth,
            calendarMonth.nextMonth()
        ]
    }
    
    private let titleFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM yyyy", options: 0, locale: Locale.current)
        return formatter
    }()
}
