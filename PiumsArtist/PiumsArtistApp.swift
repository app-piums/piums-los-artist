//
//  PiumsArtistApp.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI
import SwiftData
import Combine
import FirebaseCore
import GoogleSignIn

// MARK: - ThemeManager

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var storedScheme: String {
        didSet {
            UserDefaults.standard.set(storedScheme, forKey: "piums_color_scheme")
            // Apply immediately to all UIKit windows
            DispatchQueue.main.async { self.applyToWindows() }
        }
    }

    private init() {
        self.storedScheme = UserDefaults.standard.string(forKey: "piums_color_scheme") ?? "dark"
    }

    var colorScheme: ColorScheme? {
        switch storedScheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    func applyToWindows() {
        let style: UIUserInterfaceStyle
        switch storedScheme {
        case "light": style = .light
        case "dark":  style = .dark
        default:      style = .unspecified
        }
        // Apply to every window in every scene (includes sheet windows)
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for window in ws.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}

// MARK: - App

@main
struct PiumsArtistApp: App {
    @StateObject private var themeManager = ThemeManager.shared

    init() {
        FirebaseApp.configure()
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Artist.self, Service.self, Booking.self, Message.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.colorScheme)
                .errorHandling()
                .environmentObject(ErrorHandler.shared)
                .environmentObject(NetworkMonitor.shared)
                .environmentObject(themeManager)
                .onAppear { themeManager.applyToWindows() }
                .onChange(of: themeManager.storedScheme) { _, _ in
                    themeManager.applyToWindows()
                }
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
