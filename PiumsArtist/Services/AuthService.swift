//
//  AuthService.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import Foundation
import Combine
import SwiftUI
import FirebaseAuth
import GoogleSignIn

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var isAuthenticated = false
    @Published var currentArtist: Artist?
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// true si el artista aún no ha enviado sus documentos de verificación
    @Published var needsVerification = false
    
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
                KeychainStore.save(refreshToken, key: "refresh_token")
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

            // Verificar si el artista necesita subir documentos de identidad
            await checkVerificationStatus()

        } catch {
            if let apiError = error as? APIError {
                errorMessage = apiError.errorDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isLoading = false
    }
    
    func register(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        do {
            let request = RegisterRequest(email: email, password: password, name: name, role: "ARTIST", phone: nil)
            let response = try await apiService.post(
                endpoint: .register,
                body: request,
                responseType: AuthResponse.self
            )
            let role = (response.user.role ?? "").lowercased()
            guard role == "artist" || role == "artista" else {
                errorMessage = "Esta cuenta no tiene permisos de artista. Contacta a soporte@piums.io para activar tu cuenta."
                isLoading = false
                return
            }
            apiService.authToken = response.token
            if let refreshToken = response.refreshToken {
                KeychainStore.save(refreshToken, key: "refresh_token")
            }
            currentArtist = response.user.toDomainModel()
            let expiresInSeconds = parseExpiresIn(response.expiresIn ?? "15m")
            scheduleTokenRefresh(expiresIn: expiresInSeconds)
            await checkVerificationStatus()
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
                
                // Clear all stored session data
                KeychainStore.delete(key: "refresh_token")
                UserDefaults.standard.removeObject(forKey: "artist_backend_id")
                
                // Cancel any scheduled token refresh
                cancelTokenRefresh()
            }
        }
    }
    
    func refreshToken() async {
        guard let storedRefreshToken = KeychainStore.load(key: "refresh_token") else {
            await logout()
            return
        }

        do {
            let request = RefreshTokenRequest(refreshToken: storedRefreshToken)
            let response = try await apiService.post(
                endpoint: .refreshToken,
                body: request,
                responseType: RefreshTokenResponse.self
            )

            apiService.authToken = response.token
            if let rt = response.refreshToken {
                KeychainStore.save(rt, key: "refresh_token")
            }
            scheduleTokenRefresh(expiresIn: 15 * 60)

        } catch {
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
        guard let token = apiService.authToken else { return }

        if let user = decodeJWTUser(token: token) {
            if currentArtist == nil {
                currentArtist = user
            }
            // Restore artist_backend_id if missing (e.g. after app restart)
            if artistBackendId == nil {
                await fetchAndSaveArtistBackendId()
            }
        } else {
            apiService.authToken = nil
            currentArtist = nil
        }
    }

    private func fetchAndSaveArtistBackendId() async {
        do {
            let dto = try await apiService.get(endpoint: .artistDashboard, responseType: ArtistProfileMinDTO.self)
            artistBackendId = dto.artist.id
        } catch {
            print("[AUTH] fetchArtistBackendId error: \(error)")
        }
    }

    /// Consulta GET /auth/me para saber si el artista ya subió sus documentos.
    func checkVerificationStatus() async {
        do {
            let me = try await apiService.get(endpoint: .authMe, responseType: AuthMeDTO.self)
            let hasDocuments = !(me.documentFrontUrl ?? "").isEmpty
            needsVerification = !hasDocuments
        } catch {
            print("[AUTH] checkVerificationStatus error: \(error)")
            // No forzar la pantalla si hay error de red
            needsVerification = false
        }
    }
    
    /// Decodifica el payload del JWT sin verificar firma (solo para leer datos del usuario)
    private func decodeJWTUser(token: String) -> Artist? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        
        var base64 = String(parts[1])
        // Padding base64
        let remainder = base64.count % 4
        if remainder > 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        base64 = base64.replacingOccurrences(of: "-", with: "+")
                       .replacingOccurrences(of: "_", with: "/")
        
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        // Verificar expiración
        if let exp = json["exp"] as? TimeInterval {
            if Date().timeIntervalSince1970 > exp { return nil }
        }
        
        let id    = json["id"] as? String ?? ""
        let email = json["email"] as? String ?? ""
        let role  = json["role"] as? String ?? ""
        
        guard !id.isEmpty, !email.isEmpty else { return nil }
        guard role == "artista" || role == "artist" || role == "ARTIST" else { return nil }
        
        return Artist(
            name: currentArtist?.name ?? email,
            email: email,
            phone: currentArtist?.phone ?? "",
            profession: "Artist",
            specialty: "General",
            bio: currentArtist?.bio ?? "",
            rating: currentArtist?.rating ?? 0.0,
            totalReviews: currentArtist?.totalReviews ?? 0,
            yearsOfExperience: currentArtist?.yearsOfExperience ?? 0,
            isVerified: currentArtist?.isVerified ?? false
        )
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

    /// ID del perfil de artista en el backend (guardado en UserDefaults al cargar el perfil).
    /// Distinto del userId del auth — es el `id` de la tabla artists/artist_profiles.
    var artistBackendId: String? {
        get { UserDefaults.standard.string(forKey: "artist_backend_id") }
        set { UserDefaults.standard.set(newValue, forKey: "artist_backend_id") }
    }

    /// The backend user ID extracted from the JWT — used to detect message direction (sent vs received).
    var currentUserId: String? {
        guard let token = apiService.authToken else { return nil }
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3 else { return nil }
        var base64 = String(parts[1])
        let remainder = base64.count % 4
        if remainder > 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        base64 = base64
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["id"] as? String
    }
    
    // MARK: - Social OAuth

    /// Google Sign-In: GIDSignIn → Firebase credential → Firebase ID token → POST /api/auth/firebase
    func loginWithGoogle() async {
        isLoading = true
        errorMessage = nil

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "No se pudo obtener la ventana de presentación"
            isLoading = false
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)

            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "No se recibió el token de Google"
                isLoading = false
                return
            }

            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            let firebaseResult = try await Auth.auth().signIn(with: credential)
            let firebaseIdToken = try await firebaseResult.user.getIDToken()

            let request = FirebaseAuthRequest(idToken: firebaseIdToken)
            let response = try await apiService.post(
                endpoint: .firebaseAuth,
                body: request,
                responseType: AuthResponse.self
            )

            apiService.authToken = response.token
            if let rt = response.refreshToken {
                KeychainStore.save(rt, key: "refresh_token")
            }
            if let user = decodeJWTUser(token: response.token) {
                currentArtist = user
            }
            scheduleTokenRefresh(expiresIn: 15 * 60)
            await checkVerificationStatus()

        } catch let error as NSError where error.domain == "com.google.GIDSignIn" && error.code == -5 {
            // usuario canceló — sin mensaje de error
        } catch {
            errorMessage = "Error al autenticar con Google: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Auto-login Support

    func attemptAutoLogin() async {
        // Restore session whenever a token exists — rememberMe only controls email pre-fill
        guard apiService.authToken != nil else { return }
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
                    .fullScreenCover(isPresented: $authService.needsVerification) {
                        VerificacionView(onComplete: {
                            authService.needsVerification = false
                        })
                    }
            } else {
                LoginView()
            }
        }
    }
}

// MARK: - Login View (Artist Design — flujo email-first + social providers)

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @FocusState private var focused: LoginField?
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showRegister = false
    @State private var showForgotPassword = false
    @State private var animateIn = false
    @State private var glowPulse = false
    @State private var loginStep: LoginStep = .email

    enum LoginField { case email, password }
    enum LoginStep { case email, password, social }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                backgroundLayer(geo: geo)
                loginCard
                    // maxHeight (no fijo) → la card se reduce cuando aparece el teclado
                    .frame(maxHeight: geo.size.height * 0.78)
                    .offset(y: animateIn ? 0 : geo.size.height * 0.8)
            }
            // .container ignora bordes de pantalla pero respeta el teclado
            .ignoresSafeArea(.container)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            email = authService.artistEmail
            withAnimation(.spring(response: 0.75, dampingFraction: 0.88).delay(0.05)) { animateIn = true }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true).delay(0.3)) { glowPulse = true }
        }
        .alert("Error", isPresented: .constant(authService.errorMessage != nil)) {
            Button("Aceptar") { authService.errorMessage = nil }
        } message: {
            Text(authService.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $showRegister) { RegisterView() }
        .sheet(isPresented: $showForgotPassword) { ForgotPasswordView() }
    }

    // MARK: - Background

    @ViewBuilder
    private func backgroundLayer(geo: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Color.piumsBackground.ignoresSafeArea()

            Circle()
                .fill(Color.piumsOrange.opacity(glowPulse ? 0.30 : 0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 55)
                .offset(y: geo.safeAreaInsets.top + 80)

            VStack(spacing: 0) {
                Spacer().frame(height: geo.safeAreaInsets.top + 20)

                Image("PiumsLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 52)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: animateIn)

                Spacer().frame(height: 24)

                ZStack {
                    Circle()
                        .fill(Color.piumsOrange.opacity(0.15))
                        .frame(width: 76, height: 76)
                        .blur(radius: 10)
                    Circle()
                        .fill(Color.piumsBackgroundElevated)
                        .frame(width: 62, height: 62)
                        .overlay(Circle().fill(Color.piumsOrange.opacity(0.22)))
                    Image(systemName: "music.microphone")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundStyle(Color.piumsOrange)
                }
                .scaleEffect(animateIn ? 1 : 0.6)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.08), value: animateIn)

                Spacer().frame(height: 20)

                VStack(spacing: 6) {
                    Text("Panel de Artistas")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Gestiona tu carrera creativa")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.45).delay(0.15), value: animateIn)

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Card

    private var loginCard: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.18))
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 24)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch loginStep {
                    case .email:
                        emailPanel
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    case .password:
                        passwordPanel
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    case .social:
                        socialPanel
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: loginStep)
                .padding(.horizontal, 26)
                .padding(.bottom, 50)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.piumsBackgroundSecondary)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Email Panel (paso 1)

    private var emailPanel: some View {
        VStack(alignment: .leading, spacing: 26) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ingresar o crear cuenta")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.piumsLabel)
            }

            fieldEmail

            if let msg = authService.errorMessage {
                errorBanner(msg)
            }

            // Botón Continuar (va al panel de contraseña)
            continueButton(
                title: "Continuar",
                icon: "arrow.right",
                enabled: isValidEmail(email)
            ) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    loginStep = .password
                    focused = .password
                }
            }

            // Separador
            dividerDot

            // Botón social colapsado
            socialCollapseButton

            // Registro
            registerLink
        }
    }

    // MARK: - Password Panel (paso 2)

    private var passwordPanel: some View {
        VStack(alignment: .leading, spacing: 26) {
            // Encabezado con email y botón atrás
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        loginStep = .email
                    }
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.piumsOrange)
                        .frame(width: 36, height: 36)
                        .background(Color.piumsBackgroundElevated)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Bienvenido")
                        .font(.caption)
                        .foregroundStyle(Color.piumsLabelSecondary)
                    Text(email)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.piumsLabel)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()
            }

            fieldPassword

            if let msg = authService.errorMessage {
                errorBanner(msg)
            }

            loginButton

            HStack {
                Spacer()
                Button("¿Olvidaste tu contraseña?") { showForgotPassword = true }
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(Color.piumsOrange)
            }

            registerLink
        }
    }

    // MARK: - Social Panel (paso social)

    private var socialPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Ingresar o crear cuenta con:")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.piumsLabel)
            }

            VStack(spacing: 12) {
                googleButton
            }

            dividerDot

            // Volver a email/contraseña
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    loginStep = .email
                }
            } label: {
                Text("Continúa con correo y contraseña")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.piumsLabel.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.piumsBackgroundElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
            }

            registerLink

            Text("Al crear una cuenta en Piums, aceptas los ")
                .font(.caption)
                .foregroundStyle(Color.piumsLabelSecondary)
                + Text("Términos de Servicio")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.piumsOrange)
                + Text(" y ")
                    .font(.caption)
                    .foregroundStyle(Color.piumsLabelSecondary)
                + Text("Política de Privacidad.")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.piumsOrange)
        }
    }

    // MARK: - Google Button

    private var googleButton: some View {
        Button {
            Task { await authService.loginWithGoogle() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(Color.white).frame(width: 26, height: 26)
                    Text("G")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color(red: 0.26, green: 0.52, blue: 0.96))
                }
                .frame(width: 26, height: 26)

                Text("Continuar con Google")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.piumsLabel)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .padding(.horizontal, 16)
            .background(Color.piumsBackgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
        }
        .disabled(authService.isLoading)
    }

    // MARK: - Fields

    private var fieldEmail: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("CORREO ELECTRÓNICO")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .tracking(1.2)

            TextField("nombre@ejemplo.com", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    guard isValidEmail(email) else { return }
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                        loginStep = .password
                        focused = .password
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 15)
                .background(Color.piumsBackgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .strokeBorder(
                            focused == .email ? Color.piumsOrange.opacity(0.7) : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: focused == .email)
        }
    }

    private var fieldPassword: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("CONTRASEÑA")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .tracking(1.2)

            HStack(spacing: 0) {
                Group {
                    if showPassword {
                        TextField("••••••••", text: $password)
                    } else {
                        SecureField("••••••••", text: $password)
                    }
                }
                .textContentType(.password)
                .focused($focused, equals: .password)
                .submitLabel(.done)
                .onSubmit { Task { await authService.login(email: email, password: password) } }

                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(focused == .password ? Color.piumsOrange.opacity(0.8) : .secondary)
                        .padding(.trailing, 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(Color.piumsBackgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(
                        focused == .password ? Color.piumsOrange.opacity(0.7) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: focused == .password)
        }
    }

    // MARK: - Reusable Components

    @ViewBuilder
    private func continueButton(title: String, icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title).font(.body.bold())
                Image(systemName: icon).font(.system(size: 14, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: enabled
                        ? [Color(red: 0.85, green: 0.38, blue: 0.12), Color(red: 0.72, green: 0.28, blue: 0.07)]
                        : [Color.piumsOrange.opacity(0.4), Color.piumsOrange.opacity(0.4)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!enabled)
        .animation(.easeInOut(duration: 0.2), value: enabled)
    }

    private var loginButton: some View {
        let empty = password.isEmpty
        return Button {
            Task { await authService.login(email: email, password: password) }
        } label: {
            ZStack {
                if authService.isLoading {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white).scaleEffect(0.85)
                        Text("Iniciando sesión…").font(.body.bold())
                    }
                } else {
                    Text("Iniciar sesión").font(.body.bold())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: empty
                        ? [Color.piumsOrange.opacity(0.4), Color.piumsOrange.opacity(0.4)]
                        : [Color(red: 0.85, green: 0.38, blue: 0.12), Color(red: 0.72, green: 0.28, blue: 0.07)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(authService.isLoading || empty)
        .animation(.easeInOut(duration: 0.2), value: empty)
    }

    private var socialCollapseButton: some View {
        Button {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                loginStep = .social
            }
        } label: {
            Text("Continúa con Google")
                .font(.body.weight(.medium))
                .foregroundStyle(Color.piumsLabel.opacity(0.85))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.piumsBackgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    private var dividerDot: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 5, height: 5)
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
        }
    }

    private var registerLink: some View {
        HStack(spacing: 4) {
            Text("¿No tienes cuenta?")
                .font(.subheadline)
                .foregroundStyle(Color.piumsLabelSecondary)
            Button("Regístrate") { showRegister = true }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.piumsOrange)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.piumsError)
            Text(msg)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.piumsError)
            Spacer()
        }
        .padding(14)
        .background(Color.piumsError.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.piumsError.opacity(0.3), lineWidth: 0.5))
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
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
