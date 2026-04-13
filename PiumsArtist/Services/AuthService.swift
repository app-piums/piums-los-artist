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
                responseType: AuthResponse.self
            )
            
            // Store auth token
            apiService.authToken = response.token
            
            // Store refresh token (optional in this backend)
            if let refreshToken = response.refreshToken {
                UserDefaults.standard.set(refreshToken, forKey: "refresh_token")
            }
            
            // Store user data
            currentArtist = response.user.toDomainModel()
            
            // Store credentials if remember me is enabled
            if rememberMe {
                storedEmail = email
                self.rememberMe = true
            } else {
                storedEmail = ""
                self.rememberMe = false
            }
            
            // Parse expires time if provided (e.g. "15m"), default 15min
            let expiresInSeconds = parseExpiresIn(response.expiresIn ?? "15m")
            scheduleTokenRefresh(expiresIn: expiresInSeconds)
            
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
                let _: SuccessResponseDTO = try await apiService.request(
                    endpoint: .logout,
                    method: .POST,
                    responseType: SuccessResponseDTO.self
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
                responseType: AuthResponse.self
            )
            
            // Update tokens
            apiService.authToken = response.token
            if let rt = response.refreshToken {
                UserDefaults.standard.set(rt, forKey: "refresh_token")
            }
            
            // Update user data
            currentArtist = response.user.toDomainModel()
            
            // Schedule next refresh
            let expiresInSeconds = parseExpiresIn(response.expiresIn ?? "15m")
            scheduleTokenRefresh(expiresIn: expiresInSeconds)
            
        } catch {
            // If refresh fails, logout user
            await logout()
        }
    }
    
    // MARK: - Helper Methods
    
    private func parseExpiresIn(_ expiresString: String) -> Int {
        // Parse strings like "15m", "1h", "7d" to seconds
        let number = Int(expiresString.dropLast()) ?? 15
        let unit = String(expiresString.suffix(1))
        
        switch unit {
        case "s":
            return number
        case "m":
            return number * 60
        case "h":
            return number * 3600
        case "d":
            return number * 86400
        default:
            return 900 // Default 15 minutes
        }
    }
    
    func validateToken() async {
        guard apiService.authToken != nil else {
            return
        }
        
        do {
            // Try to fetch current user profile to validate token
            let response = try await apiService.get(
                endpoint: .userProfile,
                responseType: UserDTO.self
            )
            
            currentArtist = response.toDomainModel()
            
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

// MARK: - Login View (Artist Design)

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showPassword = false
    @State private var animateIn = false
    
    var body: some View {
        ZStack {
            // Dark artistic background
            artistBackground
            
            // Bottom sheet white card
            VStack(spacing: 0) {
                Spacer()
                loginSheet
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .ignoresSafeArea()
        .onAppear {
            email = authService.artistEmail
            withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
                animateIn = true
            }
        }
        .alert("Error de Login", isPresented: .constant(authService.errorMessage != nil)) {
            Button("OK") { authService.errorMessage = nil }
        } message: {
            Text(authService.errorMessage ?? "")
        }
    }
    
    // MARK: - Dark Artistic Background
    private var artistBackground: some View {
        ZStack {
            // Deep dark gradient
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.12, green: 0.10, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative circles
            Circle()
                .fill(Color.piumsOrange.opacity(0.15))
                .frame(width: 280, height: 280)
                .blur(radius: 60)
                .offset(x: -80, y: -60)
            
            Circle()
                .fill(Color.piumsAccent.opacity(0.10))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: 100, y: 20)
            
            // Top content
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    // Logo
                    Text("Piuma")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.piumsOrange, .piumsAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .opacity(animateIn ? 1 : 0)
                        .offset(y: animateIn ? 0 : -20)
                    
                    // Artist icon / illustration
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 110, height: 110)
                        
                        Circle()
                            .fill(Color.piumsOrange.opacity(0.15))
                            .frame(width: 84, height: 84)
                        
                        Image(systemName: "music.microphone")
                            .font(.system(size: 38, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.piumsOrange, .piumsAccent],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .scaleEffect(animateIn ? 1 : 0.6)
                    .opacity(animateIn ? 1 : 0)
                    
                    VStack(spacing: 6) {
                        Text("Panel de Artista")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        
                        Text("Gestiona tu carrera creativa")
                            .font(.subheadline.weight(.regular))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 10)
                }
                .padding(.top, 72)
                
                Spacer()
            }
        }
    }
    
    // MARK: - White Login Sheet
    private var loginSheet: some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black.opacity(0.15))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 28)
            
            VStack(alignment: .leading, spacing: 24) {
                // Sheet header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bienvenido de nuevo")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Accede a tu panel de control creativo.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Fields
                VStack(spacing: 16) {
                    // Email
                    VStack(alignment: .leading, spacing: 6) {
                        Text("EMAIL")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        
                        TextField("nombre@ejemplo.com", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .font(.body)
                    }
                    
                    // Password
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CONTRASEÑA")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .tracking(0.5)
                        
                        HStack {
                            Group {
                                if showPassword {
                                    TextField("••••••••", text: $password)
                                } else {
                                    SecureField("••••••••", text: $password)
                                }
                            }
                            .padding(.leading, 16)
                            .font(.body)
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.secondary)
                                    .padding(.trailing, 16)
                            }
                        }
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Forgot password
                        HStack {
                            Spacer()
                            Button("¿Olvidaste tu contraseña?") {}
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.piumsOrange)
                        }
                    }
                }
                
                // Login Button
                Button {
                    Task {
                        await authService.login(
                            email: email,
                            password: password,
                            rememberMe: rememberMe
                        )
                    }
                } label: {
                    HStack(spacing: 8) {
                        if authService.isLoading {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.9)
                        }
                        Text(authService.isLoading ? "Iniciando sesión..." : "Iniciar sesión")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        email.isEmpty || password.isEmpty
                        ? Color.piumsOrange.opacity(0.5)
                        : Color.piumsOrange
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                
                // Divider
                HStack(spacing: 12) {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                    
                    Text("O CONTINUAR CON")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .fixedSize()
                    
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 1)
                }
                
                // Social login
                HStack(spacing: 12) {
                    // Google
                    Button {
                        // Google OAuth
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "g.circle.fill")
                                .font(.title3)
                                .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                            Text("Continuar con Google")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Apple
                    Button {
                        // Apple Sign In
                    } label: {
                        Image(systemName: "apple.logo")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.primary)
                            .frame(width: 50, height: 50)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                
                // Register link
                HStack(spacing: 4) {
                    Text("¿Aún no tienes cuenta?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Regístrate gratis") {}
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.piumsOrange)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 40)
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color(.systemBackground))
                .ignoresSafeArea(edges: .bottom)
        )
        .offset(y: animateIn ? 0 : 400)
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
