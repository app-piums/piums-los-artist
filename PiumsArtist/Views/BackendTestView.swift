//
//  BackendTestView.swift
//  PiumsArtist
//
//  Vista para probar la conectividad con el backend
//

import SwiftUI

struct BackendTestView: View {
    @StateObject private var backendTest = BackendTest()
    @Environment(\.dismiss) private var dismiss
    
    @State private var testEmail = ""
    @State private var testPassword = ""
    @State private var showingLoginTest = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header de estado
                    statusHeader
                    
                    // Información de configuración
                    configurationInfo
                    
                    // Botones de test
                    testButtons
                    
                    // Resultados
                    if !backendTest.responseMessage.isEmpty {
                        resultsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Test de Backend")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(.piumsPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Limpiar") {
                        backendTest.connectionStatus = .unknown
                        backendTest.responseMessage = ""
                        backendTest.responseTime = 0
                        backendTest.lastTestedAt = nil
                    }
                    .foregroundColor(.piumsPrimary)
                }
            }
        }
    }
    
    // MARK: - Status Header
    private var statusHeader: some View {
        PiumsCard(style: .highlighted) {
            VStack(spacing: 16) {
                HStack {
                    Text(backendTest.connectionStatus.emoji)
                        .font(.system(size: 32))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estado de Conexión")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.piumsTextSecondary)
                        
                        Text(backendTest.connectionStatus.description)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.piumsTextPrimary)
                    }
                    
                    Spacer()
                }
                
                if backendTest.responseTime > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tiempo de respuesta")
                                .font(.caption)
                                .foregroundColor(.piumsTextSecondary)
                            
                            Text("\(Int(backendTest.responseTime * 1000))ms")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.piumsInfo)
                        }
                        
                        Spacer()
                        
                        if let lastTested = backendTest.lastTestedAt {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Última prueba")
                                    .font(.caption)
                                    .foregroundColor(.piumsTextSecondary)
                                
                                Text(lastTested, style: .time)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.piumsTextSecondary)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Configuration Info
    private var configurationInfo: some View {
        PiumsCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Configuración de API")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.piumsTextPrimary)
                
                VStack(spacing: 12) {
                    ConfigRow(label: "Entorno", value: "DEBUG (Desarrollo)")
                    ConfigRow(label: "URL Base", value: APIConfig.currentURL)
                    ConfigRow(label: "Timeout", value: "30 segundos")
                }
            }
        }
    }
    
    // MARK: - Test Buttons
    private var testButtons: some View {
        VStack(spacing: 12) {
            Text("Pruebas de Conectividad")
                .font(.headline.weight(.bold))
                .foregroundColor(.piumsTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                PiumsButton(
                    "Test Básico de Conexión",
                    icon: "network",
                    style: .primary,
                    isLoading: backendTest.connectionStatus == .connecting
                ) {
                    Task {
                        await backendTest.testConnection()
                    }
                }
                
                PiumsButton(
                    "Test Endpoints de Artista", 
                    icon: "list.bullet.clipboard",
                    style: .secondary,
                    isLoading: backendTest.connectionStatus == .connecting
                ) {
                    Task {
                        await backendTest.testArtistEndpoints()
                    }
                }
                
                PiumsButton(
                    "Test de Autenticación",
                    icon: "person.badge.key",
                    style: .outline,
                    isLoading: backendTest.connectionStatus == .connecting
                ) {
                    Task {
                        await backendTest.testFullAuth()
                    }
                }
                
                PiumsButton(
                    "🎨 Test Login de Artista",
                    icon: "person.crop.artframe",
                    style: .secondary,
                    isLoading: backendTest.connectionStatus == .connecting
                ) {
                    showingLoginTest = true
                }
            }
        }
        .sheet(isPresented: $showingLoginTest) {
            ArtistLoginTestSheet(backendTest: backendTest)
        }
    }
    
    // MARK: - Results Section
    private var resultsSection: some View {
        PiumsCard(style: .bordered) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Resultados del Test")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.piumsTextPrimary)
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = backendTest.responseMessage
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline)
                            .foregroundColor(.piumsPrimary)
                    }
                }
                
                ScrollView {
                    Text(backendTest.responseMessage)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.piumsTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.piumsSurface)
                        .cornerRadius(8)
                }
                .frame(maxHeight: 200)
            }
        }
    }
}

// MARK: - Supporting Views
struct ConfigRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.piumsTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.piumsTextPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Artist Login Test Sheet
struct ArtistLoginTestSheet: View {
    @ObservedObject var backendTest: BackendTest
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Email del artista", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    
                    SecureField("Contraseña", text: $password)
                        .textContentType(.password)
                } header: {
                    Text("Credenciales de Test")
                } footer: {
                    Text("Introduce las credenciales de un artista válido para probar el login. Los datos no se guardan.")
                }
                
                Section {
                    Button(action: {
                        Task {
                            isLoading = true
                            await backendTest.testArtistLogin(email: email, password: password)
                            isLoading = false
                        }
                    }) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "person.crop.artframe")
                            }
                            Text("Probar Login de Artista")
                        }
                    }
                    .disabled(email.isEmpty || password.isEmpty || isLoading)
                } footer: {
                    Text("Se enviará una petición POST a /auth/login con las credenciales proporcionadas")
                }
                
                // Resultados inmediatos en el sheet
                if !backendTest.responseMessage.isEmpty {
                    Section("Resultado del Test") {
                        ScrollView {
                            Text(backendTest.responseMessage)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 200)
                    }
                }
            }
            .navigationTitle("Test Login Artista")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    BackendTestView()
}
