//
//  CalendarViewDay.swift
//  CalendarList
//
//  Created by Jorge Villalobos Beato on 3/11/20.
//  Copyright © 2020 CalendarList. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct CalendarViewDay<DotsView:View>: View {
    let calendar:Calendar
    let day:Date
    let selected:Bool
    let height:CGFloat
    
    let selectedDateColor:Color
    let todayDateColor:Color
    let dotsView:DotsView?
    
    var body: some View {
        ZStack(alignment: .top) {
            Text("\(self.dateFormatter().string(from: day))")
                .font(.body)
                .foregroundColor(self.selected ? Color.white : ( !self.calendar.isDateInWeekend(self.day) ? Color.primary : Color.secondary))
            
            if let dotsView = dotsView {
                dotsView.offset(x: 0, y: 32)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(Circle().foregroundColor(dateColor()).padding(2))
        .padding([.top, .bottom], 10)
        .frame(height: self.height)
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
