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
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }
                .tag(0)
            
            BookingsView()
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Reservas")
                }
                .tag(1)
            
            CalendarView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Calendario")
                }
                .tag(2)
            
            MessagesView()
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Mensajes")
                }
                .tag(3)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Perfil")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
}