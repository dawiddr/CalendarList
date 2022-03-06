//
//  CalendarList.swift
//  CalendarList
//
//  Created by Jorge Villalobos Beato on 3/11/20.
//  Copyright © 2020 CalendarList. All rights reserved.
//

import SwiftUI
import SwiftUIPager

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
public struct CalendarList<DotsView: View & Equatable, DetailsView: View & Equatable>: View {
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
                @ViewBuilder dotsViewBuilder: @escaping (Date) -> DotsView?,
                @ViewBuilder detailsViewBuilder: @escaping (Date) -> DetailsView?,
                isShowingSelectedDayDetails: Binding<Bool>) {
        
        self.calendar = calendar
        _months = State(initialValue: CalendarMonth.getSurroundingMonths(forDate: initialDate, andCalendar: calendar))
        self.selectedDateColor = selectedDateColor
        self.todayDateColor = todayDateColor
        self.dotsViewBuilder = dotsViewBuilder
        self.detailsViewBuilder = detailsViewBuilder
        self._isShowingSelectedDayDetails = isShowingSelectedDayDetails
    }
    
    public var body: some View {
        GeometryReader { geometry in
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
            
                VStack {
                    CalendarMonthHeader(calendar: self.months[1].calendar)
                        .padding([.leading, .trailing])
                
                    Pager(page: .withIndex(currentPage), data: months.indices, id: \.self) { index in
                        let month = months[index]
                        CalendarMonthView(month: month,
                                          calendar: self.months[1].calendar,
                                          selectedDate: self.$selectedDate,
                                          selectedDayFrame: self.$selectedDayFrame,
                                          isShowingSelectedDayDetails: self.$isShowingSelectedDayDetails,
                                          geometry: geometry,
                                          isVisible: index == 1,
                                          calendarDayHeight: self.calendarDayHeight,
                                          dotsViewBuilder: dotsViewBuilder,
                                          selectedDateColor: self.selectedDateColor,
                                          todayDateColor: self.todayDateColor)
                            .padding([.leading, .trailing])
                    }.pagingPriority(.high)
                    .onPageChanged(updateMonths)
                    .onDraggingChanged { _ in
                        if isShowingSelectedDayDetails {
                            isShowingSelectedDayDetails = false
                        }
                    }.offset(y: -8)
                    .preference(key: CalendarOverlayPreference.self, value: detailsView(date: selectedDate, geometry: geometry))
                }.frame(height: CGFloat(self.months[1].weeks.count) * self.calendarDayHeight)
                .padding([.top, .bottom])
                .background(Color(UIColor.secondarySystemGroupedBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)))
            }
        }
    }
    
    @State
    public var selectedDate:Date = Date()
    
    private func detailsView(date: Date, geometry: GeometryProxy) -> CalendarOverlayView {
        if isShowingSelectedDayDetails, let dayFrame = selectedDayFrame {
            let detailsWidth = selectedDayDetailsFrame.size.width
            let detailsHeight = selectedDayDetailsFrame.size.height

            return CalendarOverlayView(view: AnyView(self.detailsViewBuilder(selectedDate)
                .equatable()
                .anchorPreference(key: BoundsPreference.self, value: .bounds) { geometry[$0] }
                .onPreferenceChange(BoundsPreference.self) {
                    selectedDayDetailsFrame = $0
                }.onTapGesture {
                    isShowingSelectedDayDetails = false
                }.position(x: min(max(detailsWidth / 2 - 8, dayFrame.minX + dayFrame.width / 2), geometry.size.width - detailsWidth / 2 + 8),
                           y: dayFrame.minY - detailsHeight / 2 + 6)))
        } else {
            return CalendarOverlayView(view: AnyView(EmptyView()))
        }
    }
    
    private func updateMonths(newIndex:Int) {
        let newMonths = months[newIndex].getSurroundingMonths()
        if newIndex == 0 {
            months.remove(at: 1)
            months.remove(at: 1)
        } else if newIndex == 2 {
            months.remove(at: 0)
            months.remove(at: 0)
        }
        
        months.insert(newMonths[0], at: 0)
        months.insert(newMonths[2], at: 2)
        currentPage = 1
    }
    
    private var previousMonthButton: some View {
        Button {
            withAnimation {
                currentPage = 0
                isShowingSelectedDayDetails = false
            }
            updateMonths(newIndex: currentPage)
        } label: {
            Image(systemName: "chevron.backward")
                .font(navigationButtonFont)
                .padding([.leading, .trailing], 8)
                .accessibilityLabel("Previous month")
        }
    }
    
    private var todayButton: some View {
        Button {
            withAnimation {
                months = CalendarMonth.getSurroundingMonths(forDate: Date(), andCalendar: Calendar.current)
                selectedDate = Date()
                isShowingSelectedDayDetails = false
            }
        } label: {
            Image(systemName: "smallcircle.filled.circle")
                .font(navigationButtonFont)
                .padding([.leading, .trailing], 8)
        }.accessibilityLabel("Today")
        .accessibilityHint("Go to current day")
    }
    
    private var nextMonthButton: some View {
        Button {
            withAnimation {
                currentPage = 2
                isShowingSelectedDayDetails = false
            }
            updateMonths(newIndex: currentPage)
        } label: {
            Image(systemName: "chevron.forward")
                .font(navigationButtonFont)
                .padding([.leading, .trailing], 8)
                .accessibilityLabel("Next month")
        }
    }
    
    private let navigationButtonFont = Font.title2.weight(.medium)
    
    @State private var months:[CalendarMonth]
    @State private var currentPage = 1
    
    @State private var selectedDayFrame: CGRect?
    @State private var selectedDayDetailsFrame: CGRect = .zero
    @Binding private var isShowingSelectedDayDetails: Bool
    
    private let calendarDayHeight:CGFloat = 60
    private let calendar:Calendar
    
    private var dotsViewBuilder: (Date) -> DotsView?
    private var detailsViewBuilder: (Date) -> DetailsView?
    private var selectedDateColor:Color
    private var todayDateColor:Color
}

public struct CalendarOverlayView: Equatable {
    public static func == (lhs: CalendarOverlayView, rhs: CalendarOverlayView) -> Bool {
        return lhs.id == rhs.id
    }
    
    public let view: AnyView
    
    private let id = UUID().uuidString
}

public struct CalendarOverlayPreference: PreferenceKey {
    public static var defaultValue = CalendarOverlayView(view: AnyView(EmptyView()))
    
    public static func reduce(value: inout CalendarOverlayView, nextValue: () -> CalendarOverlayView) {
        value = nextValue()
    }
}

private struct BoundsPreference: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
