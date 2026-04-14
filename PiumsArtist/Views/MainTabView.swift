//
//  MainTabView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("HOME")
                }
                .tag(0)

            BookingsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "calendar.badge.clock" : "calendar.badge.clock")
                    Text("RESERVAS")
                }
                .tag(1)

            MessagesView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "message.fill" : "message")
                    Text("MESSAGES")
                }
                .tag(2)

            CalendarView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "calendar" : "calendar")
                    Text("CALENDAR")
                }
                .tag(3)

            ServicesView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "bag.fill" : "bag")
                    Text("SERVICES")
                }
                .tag(4)
        }
        .tint(.piumsOrange)
    }
}

#Preview {
    MainTabView()
}
