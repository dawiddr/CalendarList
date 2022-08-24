//
//  CalendarMonthHeader.swift
//  CalendarList
//
//  Created by Jorge Villalobos Beato on 3/11/20.
//  Copyright © 2020 CalendarList. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, OSX 10.15, tvOS 13.0, watchOS 6.0, *)
struct CalendarMonthHeader:View {
    let calendar:Calendar
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(CalendarUtils.getLocalizedShortWeekdaySymbols(for: self.calendar), id:\.order) { weekdaySymbol in
                Text(weekdaySymbol.symbol)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
