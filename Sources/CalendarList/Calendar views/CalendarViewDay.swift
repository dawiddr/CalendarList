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
                Text("00")
                    .font(.body)
                    .padding(6)
                    .hidden()
                    .background(Circle().foregroundColor(dateColor()))
                
                Text("\(self.dateFormatter().string(from: day))")
                    .font(.body)
                    .foregroundColor(self.selected ? Color.white : ( !self.calendar.isDateInWeekend(self.day) ? Color.primary : Color.secondary))
            }
            
            Group {
                if let dotsView = dotsView {
                    dotsView.equatable()
                } else {
                    Spacer()
                }
            }.frame(maxHeight: .infinity, alignment: .top)
            .padding(2)
            .padding(.top, 4)
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
    
    func dateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "d"
        return formatter
    }
}
