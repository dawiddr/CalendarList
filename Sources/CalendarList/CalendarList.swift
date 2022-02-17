//
//  CalendarList.swift
//  CalendarList
//
//  Created by Jorge Villalobos Beato on 3/11/20.
//  Copyright © 2020 CalendarList. All rights reserved.
//

import SwiftUI

/// SwiftUI view to display paginated calendar months. When a given date is selected, all events for such date are represented below
/// according to the view-generation initializer block.
///
/// Parameters to initialize:
///   - initialDate: the initial month to be displayed will be extracted from this date. Defaults to the current day.
///   - calendar: `Calendar` instance to be used thorought the `CalendarList` instance. Defaults to the current `Calendar`.
///   - events: list of events to be displayed. Each event is an instance of `CalendarEvent`.
///   - selectedDateColor: color used to highlight the selected day. Defaults to the accent color.
///   - todayDateColor: color used to highlight the current day. Defaults to the accent color with 0.3 opacity.
///   - viewForEvent: `@ViewBuilder` block to generate a view per every event on the selected date. All the generated views for a given day will be presented in a `List`.
@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
public struct CalendarList<DotsView:View>: View {
    @State private var months:[CalendarMonth]
    @State private var currentPage = 1
    
    @State public var selectedDate:Date = Date()
    
    private let calendarDayHeight:CGFloat = 60
    private let calendar:Calendar
    
    private var dotsViewBuilder: (Date) -> DotsView?
    private var selectedDateColor:Color
    private var todayDateColor:Color
    
    /// Create a new paginated calendar SwiftUI view.
    /// - Parameters:
    ///   - initialDate: the initial month to be displayed will be extracted from this date. Defaults to the current day.
    ///   - calendar: `Calendar` instance to be used thorought the `CalendarList` instance. Defaults to the current `Calendar`.
    ///   - selectedDateColor: color used to highlight the selected day. Defaults to the accent color.
    ///   - todayDateColor: color used to highlight the current day. Defaults to the accent color with 0.3 opacity.
    public init(initialDate:Date = Date(),
                calendar:Calendar = Calendar.current,
                selectedDateColor:Color = Color.accentColor,
                todayDateColor:Color = Color.accentColor.opacity(0.3),
                @ViewBuilder dotsViewBuilder: @escaping (Date) -> DotsView?) {
        
        self.calendar = calendar
        _months = State(initialValue: CalendarMonth.getSurroundingMonths(forDate: initialDate, andCalendar: calendar))
        self.selectedDateColor = selectedDateColor
        self.todayDateColor = todayDateColor
        self.dotsViewBuilder = dotsViewBuilder
    }
    
    #if os(macOS)
    public var body: some View {
        commonBody
    }
    #else
    public var body: some View {
        VStack {
            HStack(alignment: .firstTextBaseline) {
                let title = months[currentPage].monthTitle()
                Text(title)
                    .font(.headline.weight(.medium))
                    .id(title)
                Spacer()
                todayButton
                previousMonthButton
                nextMonthButton
            }.padding(.leading)
            
            commonBody
                .padding([.top, .bottom])
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
    #endif

    public var commonBody: some View {
        VStack {
            CalendarMonthHeader(calendar: self.months[1].calendar, calendarDayHeight: self.calendarDayHeight)
                            
            HStack(alignment: .top) {
                PagerView(pageCount: self.months.count, currentIndex: self.$currentPage, pageChanged: self.updateMonthsAfterPagerSwipe) {
                    ForEach(self.months, id:\.key) { month in
                        CalendarMonthView(month: month,
                                          calendar: self.months[1].calendar,
                                          selectedDate: self.$selectedDate,
                                          calendarDayHeight: self.calendarDayHeight,
                                          dotsViewBuilder: dotsViewBuilder,
                                          selectedDateColor: self.selectedDateColor,
                                          todayDateColor: self.todayDateColor)
                    }
                }
            }.frame(height: CGFloat(self.months[1].weeks.count) * self.calendarDayHeight)
        }
    }
    
    func updateMonthsAfterPagerSwipe(newIndex:Int) {
        let newMonths = self.months[self.currentPage].getSurroundingMonths()
        
        if newIndex == 0 {
            self.months.remove(at: 1)
            self.months.remove(at: 1)
        } else { //newIndex == 2
            self.months.remove(at: 0)
            self.months.remove(at: 0)
        }
        
        self.months.insert(newMonths[0], at: 0)
        self.months.insert(newMonths[2], at: 2)
        
        self.currentPage = 1
    }
    
    var previousMonthButton: some View {
        Button {
            withAnimation {
                self.months = self.months.first!.getSurroundingMonths()
            }
        } label: {
            Image(systemName: "chevron.backward")
                .font(navigationButtonFont)
                .padding([.leading, .trailing], 8)
                .accessibilityLabel("Previous month")
        }
    }
    
    var todayButton: some View {
        Button {
            withAnimation {
                self.months = CalendarMonth.getSurroundingMonths(forDate: Date(), andCalendar: Calendar.current)
                self.selectedDate = Date()
            }
        } label: {
            Image(systemName: "smallcircle.filled.circle")
                .font(navigationButtonFont)
                .padding([.leading, .trailing], 8)
        }.accessibilityLabel("Today")
        .accessibilityHint("Go to current day")
    }
    
    var nextMonthButton: some View {
        Button {
            withAnimation {
                self.months = self.months.last!.getSurroundingMonths()
            }
        } label: {
            Image(systemName: "chevron.forward")
                .font(navigationButtonFont)
                .padding([.leading, .trailing], 8)
                .accessibilityLabel("Next month")
        }
    }
    
    private let navigationButtonFont = Font.title2.weight(.medium)
}

