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
public struct CalendarList<DotsView: View & Equatable & Sendable, DetailsView: View & Equatable, FooterView: View>: View {
    /// Create a new paginated calendar SwiftUI view.
    /// - Parameters:
    ///   - initialDate: the initial month to be displayed will be extracted from this date. Defaults to the current day.
    ///   - calendar: `Calendar` instance to be used thorought the `CalendarList` instance. Defaults to the current `Calendar`.
    ///   - selectedDateColor: color used to highlight the selected day. Defaults to the accent color.
    ///   - todayDateColor: color used to highlight the current day. Defaults to the accent color with 0.3 opacity.
    public init(initialDate:Date = Date(),
                calendar:Calendar = Calendar.current,
                selectedDays: Binding<[Date]>,
                isSelectingMultipleDays: Binding<Bool>,
                isShowingSelectedDayDetails: Binding<Bool>,
                overlayHolder: CalendarOverlayHolder,
                selectedDateColor:Color = Color.accentColor,
                todayDateColor:Color = Color.accentColor.opacity(0.3),
                @ViewBuilder footerView: @escaping () -> FooterView,
                @ViewBuilder dotsViewBuilder: @escaping (Date) -> DotsView?,
                @ViewBuilder detailsViewBuilder: @escaping (Date) -> DetailsView?) {
        
        self.calendar = calendar
        self._selectedDays = selectedDays
        self._isSelectingMultipleDays = isSelectingMultipleDays
        self._isShowingSelectedDayDetails = isShowingSelectedDayDetails
        self.overlayHolder = overlayHolder
        self.selectedDateColor = selectedDateColor
        self.todayDateColor = todayDateColor
        self.footerView = footerView
        self.dotsViewBuilder = dotsViewBuilder
        self.detailsViewBuilder = detailsViewBuilder
        
        _months = State(initialValue: CalendarMonth.getSurroundingMonths(forDate: initialDate, andCalendar: calendar))
    }
    
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
        
            VStack {
                CalendarMonthHeader(calendar: self.months[1].calendar)
                    .padding([.leading, .trailing])
                Pager(page: .withIndex(currentPage), data: months.indices, id: \.self) { index in
                    let month = months[index]
                    CalendarMonthView(month: month,
                                      calendar: self.months[1].calendar,
                                      selectedDays: self.$selectedDays,
                                      selectedDayFrames: self.$selectedDayFrames,
                                      isShowingSelectedDayDetails: self.$isShowingSelectedDayDetails,
                                      isSelectingMultipleDays: self.isSelectingMultipleDays,
                                      isVisible: index == 1,
                                      dotsViewBuilder: dotsViewBuilder,
                                      selectedDateColor: self.selectedDateColor,
                                      todayDateColor: self.todayDateColor)
                        .padding([.leading, .trailing])
                        .padding(.top, 4)
                }.pagingPriority(.high)
                .onPageChanged(updateMonths)
                .onDraggingChanged { _ in
                    if isShowingSelectedDayDetails {
                        isShowingSelectedDayDetails = false
                    }
                }.frame(height: CGFloat(months[1].weeks.count) * self.calendarDayHeight)
                .offset(y: -8)
                .onChange(of: isShowingSelectedDayDetails) {
                    overlayHolder.view = detailsView()
                }.onChange(of: selectedDays) {
                    overlayHolder.view = detailsView()
                }.onChange(of: selectedDayFrames) {
                    overlayHolder.view = detailsView()
                }.onChange(of: selectedDayDetailsFrame) {
                    overlayHolder.view = detailsView()
                }
            }.padding(.top)
            .background(Color(UIColor.secondarySystemGroupedBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous)))
            footerView()
                .padding([.leading, .trailing])
                .padding(.top, 8)
        }
    }
    
    private func detailsView() -> AnyView {
        if isShowingSelectedDayDetails, let selectedDay = selectedDays.first, let dayFrame = selectedDayFrames.first {
            let detailsWidth = selectedDayDetailsFrame.size.width
            let detailsHeight = selectedDayDetailsFrame.size.height

            return AnyView(GeometryReader { geometry in
                let dayFrame = geometry[dayFrame]
                self.detailsViewBuilder(selectedDay)
                    .equatable()
                    .anchorPreference(key: BoundsPreference.self, value: .bounds) { geometry[$0] }
                    .onPreferenceChange(BoundsPreference.self) {
                        selectedDayDetailsFrame = $0
                    }.onTapGesture {
                        isShowingSelectedDayDetails = false
                    }.position(x: min(max(detailsWidth / 2 + 8, dayFrame.minX + dayFrame.width / 2), geometry.size.width - detailsWidth / 2 - 8),
                               y: dayFrame.minY - detailsHeight / 2 - 6)
                    .opacity(selectedDayDetailsFrame == .zero ? 0 : 1) // The frame is initially zero, which causes the position to be incorrect.
            })
        } else {
            return AnyView(EmptyView().hidden())
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
                .accessibilityLabel(Text("schedule.previous_month_button"))
        }
    }
    
    private var todayButton: some View {
        Button {
            withAnimation {
                months = CalendarMonth.getSurroundingMonths(forDate: Date(), andCalendar: Calendar.current)
                selectedDays = [Date()]
                isShowingSelectedDayDetails = false
            }
        } label: {
            Image(systemName: "smallcircle.filled.circle")
                .font(navigationButtonFont)
                .padding([.leading, .trailing], 8)
        }.accessibilityLabel(Text("schedule.today_button"))
        .accessibilityHint(Text("schedule.today_button_hint"))
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
                .accessibilityLabel(Text("schedule.next_month_button"))
        }
    }
    
    private let navigationButtonFont = Font.title2.weight(.medium)
    
    @State private var months:[CalendarMonth]
    @State private var currentPage = 1
    
    @State private var selectedDayFrames: [Anchor<CGRect>] = []
    @State private var selectedDayDetailsFrame: CGRect = .zero
    @Binding private var isShowingSelectedDayDetails: Bool
    @Binding private var selectedDays: [Date]
    @Binding private var isSelectingMultipleDays: Bool

    @ScaledMetric(relativeTo: .body) private var calendarDayHeight: CGFloat = 70

    private let calendar:Calendar
    
    private var footerView: () -> FooterView
    private var dotsViewBuilder: (Date) -> DotsView?
    private var detailsViewBuilder: (Date) -> DetailsView?
    private var selectedDateColor:Color
    private var todayDateColor:Color
    private var overlayHolder: CalendarOverlayHolder
}

private struct BoundsPreference: PreferenceKey {
    static let defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

public class CalendarOverlayHolder: ObservableObject {
    public init() {}

    @Published
    public var view: AnyView = AnyView(EmptyView())
}
