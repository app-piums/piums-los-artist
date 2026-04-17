//
//  MainTabView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    init() {
        let bg = UIColor.systemGroupedBackground
        UINavigationBar.appearance().backgroundColor = bg
        UINavigationBar.appearance().barTintColor = bg
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = bg
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some View {
        ZStack {
            Color(.secondarySystemGroupedBackground).ignoresSafeArea()
            TabView(selection: $selectedTab) {
                NavigationStack { DashboardView() }
                    .tabItem { Label("Inicio", systemImage: "house.fill") }
                    .tag(0)

                NavigationStack { BookingsView() }
                    .tabItem { Label("Reservas", systemImage: "doc.text.fill") }
                    .tag(1)

                NavigationStack { CalendarView() }
                    .tabItem { Label("Agenda", systemImage: "calendar") }
                    .tag(2)

                NavigationStack { MessagesView() }
                    .tabItem { Label("Mensajes", systemImage: "message.fill") }
                    .tag(3)

                NavigationStack { MoreMenuView() }
                    .tabItem { Label("Más", systemImage: "line.3.horizontal") }
                    .tag(4)
            }
            .tint(.piumsOrange)
            .toolbarBackground(.ultraThinMaterial, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)
        }
    }
}

#Preview {
    MainTabView()
}
