//
//  CalendarViewDay.swift
//  CalendarList
//
//  Created by Jorge Villalobos Beato on 3/11/20.
//  Copyright © 2020 CalendarList. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct CalendarViewDay<DotsView: View & Equatable>: View, Equatable {
    let calendar:Calendar
    let day:Date
    let selected:Bool
    
    let selectedDateColor:Color
    let todayDateColor:Color
    let dotsView:DotsView?
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                let color = dateColor()
                Text(verbatim: "00")
                    .font(.body)
                    .padding(6)
                    .hidden()
                    .background(Circle().foregroundColor(color))
                    .accessibilityHidden(true)
                
                Text("\(self.dayFormatter.string(from: day))")
                    .font(.body.weight(color == selectedDateColor ? .medium : .regular))
                    .foregroundColor(self.selected ? Color.white : ( !self.calendar.isDateInWeekend(self.day) ? Color.primary : Color.secondary))
                    .accessibilityLabel(self.accessibilityDateFormatter.string(from: day))
            }
            
            Group {
                if let dotsView = dotsView {
                    dotsView.equatable()
                } else {
                    Spacer()
                }
            }.frame(maxHeight: .infinity, alignment: .top)
            .padding(2)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func dateColor() -> Color {
        if self.selected {
            return self.selectedDateColor
        } else if calendar.isDateInToday(day) {
            return self.todayDateColor
        } else {
            return Color.clear
        }
    }
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "d"
        return formatter
    }()
    
    private let accessibilityDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "d MMMM", options: 0, locale: .current)
        return formatter
    }()
}
