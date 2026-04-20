//
//  MainTabView.swift
//  PiumsArtist
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var tutorial = TutorialManager.shared

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

            // ── Interactive tour overlay ──
            if tutorial.isActive {
                TourOverlayView()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .zIndex(100)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: tutorial.isActive)
        // Navigate to the correct tab when tutorial step changes
        .onChange(of: tutorial.currentTabTarget) { _, newTab in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                selectedTab = newTab
            }
        }
        // Also switch tab when tour becomes active (start at tab 0)
        .onChange(of: tutorial.isActive) { _, active in
            if active {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    selectedTab = tutorial.currentTabTarget
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}
