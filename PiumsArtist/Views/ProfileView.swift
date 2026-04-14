//
//  ProfileView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI

struct ProfileView: View {
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    
    // Mock artist data
    @State private var artist = ArtistData(
        name: "María González",
        profession: "Estilista Profesional",
        rating: 4.8,
        totalReviews: 156,
        yearsOfExperience: 5,
        specialty: "Coloración y Peinados",
        phone: "+34 666 777 888",
        email: "maria.gonzalez@piums.com",
        bio: "Especialista en coloración y peinados con más de 5 años de experiencia. Me apasiona crear looks únicos para cada cliente."
    )
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        // Avatar
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 45))
                                    .foregroundColor(.blue)
                            )
                            .overlay(
                                Button {
                                    // Change avatar action
                                } label: {
                                    Image(systemName: "camera.fill")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(Color.blue)
                                        .cornerRadius(14)
                                }
                                .offset(x: 35, y: 35)
                            )
                        
                        VStack(spacing: 8) {
                            Text(artist.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(artist.profession)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 16) {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text("\(artist.rating, specifier: "%.1f")")
                                        .fontWeight(.medium)
                                    Text("(\(artist.totalReviews) reseñas)")
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                                
                                Text("•")
                                    .foregroundColor(.secondary)
                                
                                Text("\(artist.yearsOfExperience) años exp.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Button("Editar Perfil") {
                            showingEditProfile = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 40)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    
                    // Stats Section
                    StatsSection()
                    
                    // Services Section
                    ServicesSection()
                    
                    // Settings Section
                    SettingsSection(showingSettings: $showingSettings)
                }
                .padding()
            }
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(artist: $artist)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environmentObject(ThemeManager.shared)
            }
        }
    }
}

struct ArtistData {
    var name: String
    var profession: String
    let rating: Double
    let totalReviews: Int
    let yearsOfExperience: Int
    var specialty: String
    var phone: String
    var email: String
    var bio: String
}

struct StatsSection: View {
    // Mock stats data
    let stats = [
        StatItem(title: "Clientes atendidos", value: "1,234", icon: "person.2.fill", color: .blue),
        StatItem(title: "Servicios completados", value: "2,156", icon: "checkmark.circle.fill", color: .green),
        StatItem(title: "Ingresos este mes", value: "$3,250", icon: "dollarsign.circle.fill", color: .purple),
        StatItem(title: "Valoración promedio", value: "4.8⭐", icon: "star.fill", color: .orange)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Estadísticas")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(stats, id: \.title) { stat in
                    StatCard(stat: stat)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct StatItem {
    let title: String
    let value: String
    let icon: String
    let color: Color
}

struct StatCard: View {
    let stat: StatItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: stat.icon)
                    .foregroundColor(stat.color)
                    .font(.title3)
                Spacer()
            }
            
            Text(stat.value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(stat.title)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(stat.color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ServicesSection: View {
    let services = [
        "Corte de cabello",
        "Coloración",
        "Peinados",
        "Tratamientos",
        "Barba y bigote"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Mis Servicios")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Gestionar") {
                    // Navigate to service management
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(services, id: \.self) { service in
                    ServiceTag(service: service)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct ServiceTag: View {
    let service: String
    
    var body: some View {
        Text(service)
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(20)
    }
}

struct SettingsSection: View {
    @Binding var showingSettings: Bool
    
    let settingsOptions = [
        SettingsOption(title: "Configuración", icon: "gearshape.fill", color: .gray),
        SettingsOption(title: "Notificaciones", icon: "bell.fill", color: .blue),
        SettingsOption(title: "Privacidad", icon: "lock.fill", color: .green),
        SettingsOption(title: "Ayuda y Soporte", icon: "questionmark.circle.fill", color: .orange),
        SettingsOption(title: "Acerca de", icon: "info.circle.fill", color: .purple),
        SettingsOption(title: "Cerrar Sesión", icon: "rectangle.portrait.and.arrow.right.fill", color: .red)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Configuración")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            
            VStack(spacing: 0) {
                ForEach(Array(settingsOptions.enumerated()), id: \.offset) { index, option in
                    Button {
                        if option.title == "Configuración" {
                            showingSettings = true
                        } else {
                            // Handle other settings actions
                        }
                    } label: {
                        SettingsRow(option: option)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if index < settingsOptions.count - 1 {
                        Divider()
                            .padding(.leading, 50)
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct SettingsOption {
    let title: String
    let icon: String
    let color: Color
}

struct SettingsRow: View {
    let option: SettingsOption
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: option.icon)
                .foregroundColor(option.color)
                .frame(width: 24, height: 24)
            
            Text(option.title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct EditProfileView: View {
    @Binding var artist: ArtistData
    @Environment(\.presentationMode) var presentationMode
    @State private var tempArtist: ArtistData
    
    init(artist: Binding<ArtistData>) {
        self._artist = artist
        self._tempArtist = State(initialValue: artist.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Información Personal") {
                    TextField("Nombre completo", text: $tempArtist.name)
                    TextField("Profesión", text: $tempArtist.profession)
                    TextField("Especialidad", text: $tempArtist.specialty)
                }
                
                Section("Contacto") {
                    TextField("Teléfono", text: $tempArtist.phone)
                        .keyboardType(.phonePad)
                    TextField("Correo electrónico", text: $tempArtist.email)
                        .keyboardType(.emailAddress)
                }
                
                Section("Descripción") {
                    TextField("Biografía", text: $tempArtist.bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        artist = tempArtist
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showLogoutConfirm = false
    @State private var showEditProfile = false
    @State private var showChangePassword = false

    // Editable fields
    @State private var editName = ""
    @State private var editPhone = ""
    @State private var editBio = ""
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    private var artist: Artist? { AuthService.shared.currentArtist }

    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.piumsOrange.opacity(0.15))
                                .frame(width: 68, height: 68)
                            Text(initials)
                                .font(.title2.bold())
                                .foregroundStyle(Color.piumsOrange)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(artist?.name ?? "Artista")
                                .font(.headline)
                            Text(artist?.email ?? "")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Artista Pro")
                                .font(.caption)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Color.piumsOrange.opacity(0.12))
                                .foregroundStyle(Color.piumsOrange)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 8)
                }

                // ── Mensajes ──
                if let msg = successMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.piumsSuccess)
                            Text(msg).font(.caption)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.piumsSuccess.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .listRowSeparator(.hidden)
                }
                if let msg = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.piumsError)
                            Text(msg).font(.caption)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.piumsError.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .listRowSeparator(.hidden)
                }

                // ── Cuenta ──
                Section("Cuenta") {
                    Button {
                        prepareEdit()
                        showEditProfile = true
                    } label: {
                        Label("Editar perfil", systemImage: "person.circle")
                    }

                    Button {
                        clearPassFields()
                        showChangePassword = true
                    } label: {
                        Label("Cambiar contraseña", systemImage: "lock.rotation")
                    }
                }

                // ── Apariencia ──
                Section("Apariencia") {
                    Toggle(isOn: Binding(
                        get: { themeManager.storedScheme == "dark" },
                        set: { themeManager.storedScheme = $0 ? "dark" : "light" }
                    )) {
                        Label("Modo oscuro", systemImage: "moon.fill")
                    }
                    .tint(.piumsOrange)
                }

                // ── Ayuda y soporte ──
                Section("Ayuda y soporte") {
                    Label("Mis quejas", systemImage: "exclamationmark.bubble")
                    Label("Términos y condiciones", systemImage: "doc.text")
                    Label("Política de privacidad", systemImage: "hand.raised")
                    Label("Contactar soporte", systemImage: "message")
                }
                .foregroundStyle(.primary)

                // ── Cerrar sesión ──
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirm = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Configuración")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .confirmationDialog("¿Cerrar sesión?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Cerrar sesión", role: .destructive) {
                    AuthService.shared.logout()
                }
                Button("Cancelar", role: .cancel) {}
            }
            .sheet(isPresented: $showEditProfile) {
                editProfileSheet
            }
            .sheet(isPresented: $showChangePassword) {
                changePasswordSheet
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }

    // MARK: - Edit Profile Sheet
    private var editProfileSheet: some View {
        NavigationView {
            Form {
                Section("Nombre") {
                    TextField("Nombre completo", text: $editName)
                }
                Section("Teléfono") {
                    TextField("Teléfono", text: $editPhone)
                        .keyboardType(.phonePad)
                }
                Section("Biografía") {
                    TextField("Cuéntanos sobre ti", text: $editBio, axis: .vertical)
                        .lineLimit(3...6)
                }
                if let msg = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.piumsError)
                            Text(msg).font(.caption)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Editar perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await saveProfile() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.piumsOrange)
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showEditProfile = false }
                }
            }
            .overlay { if isSaving { ProgressView() } }
        }
    }

    // MARK: - Change Password Sheet
    private var changePasswordSheet: some View {
        NavigationView {
            Form {
                Section("Contraseña actual") {
                    SecureField("Contraseña actual", text: $currentPassword)
                }
                Section("Nueva contraseña") {
                    SecureField("Nueva contraseña", text: $newPassword)
                    SecureField("Confirmar nueva contraseña", text: $confirmPassword)
                }
                if let msg = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.piumsError)
                            Text(msg).font(.caption)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Cambiar contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        Task { await changePassword() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.piumsOrange)
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showChangePassword = false }
                }
            }
        }
    }

    // MARK: - Helpers

    private var initials: String {
        let name = artist?.name ?? "A"
        return name.components(separatedBy: " ")
            .compactMap { $0.first.map(String.init) }
            .prefix(2)
            .joined()
            .uppercased()
    }

    private func prepareEdit() {
        editName = artist?.name ?? ""
        editPhone = artist?.phone ?? ""
        editBio = artist?.bio ?? ""
        errorMessage = nil
        successMessage = nil
    }

    private func clearPassFields() {
        currentPassword = ""
        newPassword = ""
        confirmPassword = ""
        errorMessage = nil
        successMessage = nil
    }

    private func saveProfile() async {
        isSaving = true
        errorMessage = nil
        do {
            let body = UpdateUserRequest(name: editName, phone: editPhone, bio: editBio, location: nil)
            let _ = try await APIService.shared.put(
                endpoint: .updateUserProfile,
                body: body,
                responseType: UserDTO.self
            )
            // Update local
            artist?.name = editName
            artist?.phone = editPhone
            artist?.bio = editBio
            successMessage = "Perfil actualizado correctamente"
            showEditProfile = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private func changePassword() async {
        guard newPassword == confirmPassword else {
            errorMessage = "Las contraseñas no coinciden"
            return
        }
        guard newPassword.count >= 6 else {
            errorMessage = "La contraseña debe tener al menos 6 caracteres"
            return
        }
        isSaving = true
        errorMessage = nil
        do {
            struct ChangePassBody: Codable {
                let currentPassword: String
                let newPassword: String
            }
            let body = ChangePassBody(currentPassword: currentPassword, newPassword: newPassword)
            let _ = try await APIService.shared.post(
                endpoint: .changePassword,
                body: body,
                responseType: EmptyResponseDTO.self
            )
            successMessage = "Contraseña cambiada correctamente"
            showChangePassword = false
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    ProfileView()
}
