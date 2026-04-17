//
//  ContentView.swift
//  PiumsArtist
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var authService = AuthService.shared
    @AppStorage("hasSeenArtistOnboarding") private var hasSeenOnboarding = false
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                splashScreen
            } else if !hasSeenOnboarding {
                ArtistOnboardingView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasSeenOnboarding = true
                    }
                }
            } else if authService.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isLoggedIn)
        .animation(.easeInOut(duration: 0.3), value: hasSeenOnboarding)
        .task {
            // Intenta auto-login con token guardado
            await authService.attemptAutoLogin()
            // Splash mínimo de 1.5s
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation { isLoading = false }
        }
    }

    // MARK: - Splash Screen
    private var splashScreen: some View {
        ZStack {
            Color.piumsOrange.ignoresSafeArea()
            VStack(spacing: 20) {
                Image("PiumsLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 76)
                    .colorMultiply(.white)
                Text("Panel de Artistas")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white.opacity(0.75))
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Artist.self, Service.self, Booking.self, Message.self], inMemory: true)
}
