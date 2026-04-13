//
//  PiumsArtistApp.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI
import SwiftData

@main
struct PiumsArtistApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Artist.self,
            Service.self,
            Booking.self,
            Message.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .errorHandling()
                .environmentObject(ErrorHandler.shared)
                .environmentObject(NetworkMonitor.shared)
        }
        .modelContainer(sharedModelContainer)
    }
}
