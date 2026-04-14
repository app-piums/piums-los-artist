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
                    Text("Inicio")
                }
                .tag(0)

            BookingsView()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("Reservas")
                }
                .tag(1)

            CalendarView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "calendar" : "calendar")
                    Text("Agenda")
                }
                .tag(2)

            MessagesView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "message.fill" : "message")
                    Text("Mensajes")
                }
                .tag(3)

            MoreMenuView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "line.3.horizontal" : "line.3.horizontal")
                    Text("Más")
                }
                .tag(4)
        }
        .tint(.piumsOrange)
    }
}

#Preview {
    MainTabView()
}
