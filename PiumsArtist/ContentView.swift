//
//  ContentView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var authService = AuthService.shared

    var body: some View {
        AuthenticatedView {
            MainTabView()
        }
        .onAppear {
            Task {
                await authService.attemptAutoLogin()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Artist.self, Service.self, Booking.self, Message.self], inMemory: true)
}
