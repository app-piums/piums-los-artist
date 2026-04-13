//
//  AuthService.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentArtist: Artist?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // Stored credentials for auto-login
    @AppStorage("user_email") private var storedEmail: String = ""
    @AppStorage("remember_me") private var rememberMe: Bool = false
    
    private init() {
        // Listen to auth token changes
        apiService.$authToken
            .map { $0 != nil }
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)
        
        // Auto-login if token exists
        if apiService.authToken != nil {
            Task {
                await validateToken()
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String, rememberMe: Bool = false) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = LoginRequest(email: email, password: password)
            let response = try await apiService.post(
                endpoint: .login,
                body: request,
                responseType: APIResponse<LoginResponse>.self
            )
            
            guard let loginData = response.data else {
                throw APIError.noData
            }
            
            // Store auth token
            apiService.authToken = loginData.token
            
            // Store refresh token
            UserDefaults.standard.set(loginData.refreshToken, forKey: "refresh_token")
            
            // Store user data
            currentArtist = loginData.artist.toDomainModel()
            
            // Store credentials if remember me is enabled
            if rememberMe {
                storedEmail = email
                self.rememberMe = true
            } else {
                storedEmail = ""
                self.rememberMe = false
            }
            
            // Schedule token refresh
            scheduleTokenRefresh(expiresIn: loginData.expiresIn)
            
        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func logout() {
        Task {
            // Call logout endpoint
            do {
                let _ = try await apiService.request(
                    endpoint: .logout,
                    method: .POST,
                    responseType: SuccessResponse.self
                )
            } catch {
                print("Logout API call failed: \(error)")
            }
            
            // Clear local data
            await MainActor.run {
                apiService.authToken = nil
                currentArtist = nil
                storedEmail = ""
                rememberMe = false
                
                // Clear stored refresh token
                UserDefaults.standard.removeObject(forKey: "refresh_token")
                
                // Cancel any scheduled token refresh
                cancelTokenRefresh()
            }
        }
    }
    
    func refreshToken() async {
        guard let refreshToken = UserDefaults.standard.string(forKey: "refresh_token") else {
            await logout()
            return
        }
        
        do {
            let request = RefreshTokenRequest(refreshToken: refreshToken)
            let response = try await apiService.post(
                endpoint: .refreshToken,
                body: request,
                responseType: APIResponse<LoginResponse>.self
            )
            
            guard let loginData = response.data else {
                throw APIError.noData
            }
            
            // Update tokens
            apiService.authToken = loginData.token
            UserDefaults.standard.set(loginData.refreshToken, forKey: "refresh_token")
            
            // Update user data
            currentArtist = loginData.artist.toDomainModel()
            
            // Schedule next refresh
            scheduleTokenRefresh(expiresIn: loginData.expiresIn)
            
        } catch {
            // If refresh fails, logout user
            await logout()
        }
    }
    
    func validateToken() async {
        guard apiService.authToken != nil else {
            return
        }
        
        do {
            // Try to fetch current artist profile to validate token
            let response = try await apiService.get(
                endpoint: .artistProfile,
                responseType: APIResponse<ArtistDTO>.self
            )
            
            if let artistData = response.data {
                currentArtist = artistData.toDomainModel()
            }
            
        } catch {
            // Token is invalid, try to refresh
            await refreshToken()
        }
    }
    
    // MARK: - Token Refresh Scheduling
    
    private var refreshTimer: Timer?
    
    private func scheduleTokenRefresh(expiresIn: Int) {
        cancelTokenRefresh()
        
        // Refresh token 5 minutes before it expires
        let refreshTime = TimeInterval(max(expiresIn - 300, 60))
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshTime, repeats: false) { _ in
            Task {
                await self.refreshToken()
            }
        }
    }
    
    private func cancelTokenRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    // MARK: - Helper Methods
    
    var isLoggedIn: Bool {
        return isAuthenticated && currentArtist != nil
    }
    
    var artistName: String {
        return currentArtist?.name ?? "Artista"
    }
    
    var artistEmail: String {
        return currentArtist?.email ?? storedEmail
    }
    
    // MARK: - Auto-login Support
    
    func attemptAutoLogin() async {
        guard rememberMe && !storedEmail.isEmpty else {
            return
        }
        
        await validateToken()
    }
}

// MARK: - Authentication View Modifiers

struct AuthenticatedView<Content: View>: View {
    @StateObject private var authService = AuthService.shared
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        Group {
            if authService.isLoggedIn {
                content()
            } else {
                LoginView()
            }
        }
    }
}

// MARK: - Login View (Basic Implementation)

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Logo or App Title
                VStack(spacing: 8) {
                    Image(systemName: "scissors.badge.ellipsis")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("Piums Artista")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Inicia sesión para continuar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 16) {
                    // Email Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("tu@email.com", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Contraseña")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        SecureField("Contraseña", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Remember Me Toggle
                    HStack {
                        Toggle("Recordarme", isOn: $rememberMe)
                        Spacer()
                    }
                }
                
                // Login Button
                Button(action: {
                    Task {
                        await authService.login(
                            email: email,
                            password: password,
                            rememberMe: rememberMe
                        )
                    }
                }) {
                    HStack {
                        if authService.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text("Iniciar Sesión")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .roundedCorner(8)
                }
                .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear {
            // Pre-fill email if remembered
            email = authService.artistEmail
        }
        .alert("Error de Login", isPresented: .constant(authService.errorMessage != nil)) {
            Button("OK") {
                authService.errorMessage = nil
            }
        } message: {
            Text(authService.errorMessage ?? "")
        }
    }
}

// MARK: - View Extensions

extension View {
    func roundedCorner(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - Preview

#Preview {
    LoginView()
}