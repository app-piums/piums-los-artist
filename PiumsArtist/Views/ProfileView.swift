//
//  ProfileView.swift
//  PiumsArtist
//
//  Conectado a ProfileViewModel — muestra datos reales del backend.
//

import SwiftUI

// MARK: - Profile View

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @StateObject private var authService = AuthService.shared
    @State private var showingSettings = false
    @State private var showVerificacion = false
    @State private var showEditProfile = false
    @State private var showPhotoAlert = false

    private var artist: Artist? { vm.artist ?? AuthService.shared.currentArtist }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    statsSection
                    servicesSection
                    settingsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Perfil")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(.secondarySystemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .refreshable { await vm.refreshData() }
            .sheet(isPresented: $showEditProfile) { EditArtistProfileSheet() }
            .alert("Foto de perfil", isPresented: $showPhotoAlert) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text("La subida de foto de perfil estará disponible en una próxima actualización.")
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView().environmentObject(ThemeManager.shared)
            }
            .sheet(isPresented: $showVerificacion) {
                VerificacionView(onComplete: {
                    authService.needsVerification = false
                })
            }
            .overlay {
                if vm.isLoading && vm.artist == nil {
                    PiumsLoadingView("Cargando perfil...")
                }
            }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            PiumsAvatarView(
                name: artist?.name ?? "A",
                imageURL: nil,
                size: 90,
                gradientColors: [.piumsOrange, .piumsAccent]
            )
            .overlay(alignment: .bottomTrailing) {
                Button { showPhotoAlert = true } label: {
                    Image(systemName: "camera.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.piumsOrange)
                        .clipShape(Circle())
                }
                .offset(x: 4, y: 4)
            }

            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Text(artist?.name ?? "—")
                        .font(.title2.weight(.bold))
                    if artist?.isVerified == true {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.piumsOrange)
                    }
                }

                Text(artist?.profession.isEmpty == false ? artist!.profession : "Artista")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                let rating = artist?.rating ?? 0
                if rating > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text(String(format: "%.1f", rating)).fontWeight(.medium)
                        Text("(\(artist?.totalReviews ?? 0) reseñas)").foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
            }

            Button { showEditProfile = true } label: {
                Label("Editar Perfil", systemImage: "pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.piumsOrange)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
            }
        }
        .padding(20)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Stats

    private var statsSection: some View {
        let s = vm.statistics
        return VStack(alignment: .leading, spacing: 14) {
            Text("Estadísticas")
                .font(.headline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard("Reservas totales",   value: "\(s.totalClients)",
                         icon: "person.2.fill",         color: .piumsOrange)
                statCard("Completados",        value: "\(s.completedServices)",
                         icon: "checkmark.circle.fill", color: .piumsSuccess)
                statCard("Ingresos mes",       value: "Q\(Int(s.monthlyEarnings))",
                         icon: "dollarsign.circle.fill", color: .purple)
                statCard("Valoración",         value: s.averageRating > 0
                            ? String(format: "%.1f ⭐", s.averageRating) : "—",
                         icon: "star.fill",             color: .yellow)
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private func statCard(_ title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundColor(color).font(.title3)
            Text(value).font(.title3.weight(.bold))
            Text(title).font(.caption).foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - Services

    private var servicesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Mis Servicios")
                .font(.headline.weight(.semibold))

            if vm.services.isEmpty {
                Text("Sin servicios configurados")
                    .font(.subheadline).foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(vm.services.prefix(6)) { svc in
                        Text(svc.name)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.piumsOrange.opacity(0.1))
                            .foregroundColor(.piumsOrange)
                            .cornerRadius(20)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingsRow(icon: "gearshape.fill",   label: "Configuración",   color: Color(.systemGray)) { showingSettings = true }
            Divider().padding(.leading, 58)
            // Fila de verificación con badge si aún no está enviada
            verificationRow
            Divider().padding(.leading, 58)
            settingsRow(icon: "bell.fill",         label: "Notificaciones",  color: .piumsInfo) {}
            Divider().padding(.leading, 58)
            settingsRow(icon: "hand.raised.fill",  label: "Privacidad",      color: .piumsSuccess) {}
            Divider().padding(.leading, 58)
            settingsRow(icon: "questionmark.circle.fill", label: "Ayuda y Soporte", color: .piumsWarning) {}
            Divider().padding(.leading, 58)
            settingsRow(icon: "rectangle.portrait.and.arrow.right.fill",
                        label: "Cerrar Sesión", color: .piumsError) {
                AuthService.shared.logout()
            }
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var verificationRow: some View {
        Button { showVerificacion = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(Color.piumsOrange)
                        .frame(width: 30, height: 30)
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                Text("Verificación de Identidad")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                Spacer()
                if authService.needsVerification {
                    Text("Pendiente")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color.piumsError)
                        .clipShape(Capsule())
                } else if artist?.isVerified == true {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.piumsSuccess)
                        .font(.subheadline)
                } else {
                    Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsRow(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7).fill(color).frame(width: 30, height: 30)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(label == "Cerrar Sesión" ? .piumsError : .primary)
                Spacer()
                if label != "Cerrar Sesión" {
                    Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ArtistData (retrocompatibilidad)

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

// MARK: - Edit Artist Profile Sheet

private struct EditArtistProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = AuthService.shared.currentArtist?.name ?? ""
    @State private var phone: String = AuthService.shared.currentArtist?.phone ?? ""
    @State private var bio: String = AuthService.shared.currentArtist?.bio ?? ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
                Section("Nombre") {
                    TextField("Nombre completo", text: $name)
                }
                Section("Teléfono") {
                    TextField("Teléfono", text: $phone).keyboardType(.phonePad)
                }
                Section("Biografía") {
                    TextField("Cuéntanos sobre ti", text: $bio, axis: .vertical).lineLimit(3...6)
                }
                if let msg = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.piumsError)
                            Text(msg).font(.caption)
                        }
                    }.listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Editar Perfil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { Task { await save() } }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.piumsOrange)
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .overlay { if isSaving { ProgressView() } }
        }
    }

    private func save() async {
        isSaving = true; errorMessage = nil
        do {
            let body = UpdateUserRequest(name: name, phone: phone, bio: bio, location: nil)
            let _ = try await APIService.shared.put(endpoint: .updateUserProfile, body: body, responseType: UserDTO.self)
            AuthService.shared.currentArtist?.name = name
            AuthService.shared.currentArtist?.phone = phone
            AuthService.shared.currentArtist?.bio = bio
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showLogoutConfirm = false
    @State private var showEditProfile = false
    @State private var showChangePassword = false

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
                            Text(artist?.name ?? "Artista").font(.headline)
                            Text(artist?.email ?? "").font(.subheadline).foregroundStyle(.secondary)
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

                if let msg = successMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.piumsSuccess)
                            Text(msg).font(.caption)
                        }
                        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.piumsSuccess.opacity(0.1)).cornerRadius(8)
                    }
                    .listRowSeparator(.hidden)
                }
                if let msg = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.piumsError)
                            Text(msg).font(.caption)
                        }
                        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.piumsError.opacity(0.1)).cornerRadius(8)
                    }
                    .listRowSeparator(.hidden)
                }

                Section("Cuenta") {
                    Button { prepareEdit(); showEditProfile = true } label: {
                        Label("Editar perfil", systemImage: "person.circle")
                    }
                    Button { clearPassFields(); showChangePassword = true } label: {
                        Label("Cambiar contraseña", systemImage: "lock.rotation")
                    }
                }

                Section("Apariencia") {
                    Toggle(isOn: Binding(
                        get: { themeManager.storedScheme == "dark" },
                        set: { themeManager.storedScheme = $0 ? "dark" : "light" }
                    )) {
                        Label("Modo oscuro", systemImage: "moon.fill")
                    }
                    .tint(.piumsOrange)
                }

                Section("Ayuda y soporte") {
                    Label("Mis quejas",               systemImage: "exclamationmark.bubble")
                    Label("Términos y condiciones",   systemImage: "doc.text")
                    Label("Política de privacidad",   systemImage: "hand.raised")
                    Label("Contactar soporte",        systemImage: "message")
                }
                .foregroundStyle(.primary)

                Section {
                    Button(role: .destructive) { showLogoutConfirm = true } label: {
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
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { dismiss() } } }
            .confirmationDialog("¿Cerrar sesión?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Cerrar sesión", role: .destructive) { AuthService.shared.logout() }
                Button("Cancelar", role: .cancel) {}
            }
            .sheet(isPresented: $showEditProfile) { editProfileSheet }
            .sheet(isPresented: $showChangePassword) { changePasswordSheet }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }

    private var editProfileSheet: some View {
        NavigationView {
            Form {
                Section("Nombre") { TextField("Nombre completo", text: $editName) }
                Section("Teléfono") { TextField("Teléfono", text: $editPhone).keyboardType(.phonePad) }
                Section("Biografía") {
                    TextField("Cuéntanos sobre ti", text: $editBio, axis: .vertical).lineLimit(3...6)
                }
                if let msg = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.piumsError)
                            Text(msg).font(.caption)
                        }
                    }.listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Editar perfil").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { Task { await saveProfile() } }
                        .fontWeight(.semibold).foregroundStyle(Color.piumsOrange).disabled(isSaving)
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showEditProfile = false } }
            }
            .overlay { if isSaving { ProgressView() } }
        }
    }

    private var changePasswordSheet: some View {
        NavigationView {
            Form {
                Section("Contraseña actual") { SecureField("Contraseña actual", text: $currentPassword) }
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
                    }.listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Cambiar contraseña").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") { Task { await changePassword() } }
                        .fontWeight(.semibold).foregroundStyle(Color.piumsOrange).disabled(isSaving)
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showChangePassword = false } }
            }
        }
    }

    private var initials: String {
        (artist?.name ?? "A").components(separatedBy: " ")
            .compactMap { $0.first.map(String.init) }.prefix(2).joined().uppercased()
    }

    private func prepareEdit() {
        editName = artist?.name ?? ""; editPhone = artist?.phone ?? ""; editBio = artist?.bio ?? ""
        errorMessage = nil; successMessage = nil
    }

    private func clearPassFields() {
        currentPassword = ""; newPassword = ""; confirmPassword = ""
        errorMessage = nil; successMessage = nil
    }

    private func saveProfile() async {
        isSaving = true; errorMessage = nil
        do {
            let body = UpdateUserRequest(name: editName, phone: editPhone, bio: editBio, location: nil)
            let _ = try await APIService.shared.put(endpoint: .updateUserProfile, body: body, responseType: UserDTO.self)
            artist?.name = editName; artist?.phone = editPhone; artist?.bio = editBio
            successMessage = "Perfil actualizado correctamente"
            showEditProfile = false
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }

    private func changePassword() async {
        guard newPassword == confirmPassword else { errorMessage = "Las contraseñas no coinciden"; return }
        guard newPassword.count >= 6 else { errorMessage = "Mínimo 6 caracteres"; return }
        isSaving = true; errorMessage = nil
        do {
            struct Body: Codable { let currentPassword: String; let newPassword: String }
            let _ = try await APIService.shared.post(
                endpoint: .changePassword, body: Body(currentPassword: currentPassword, newPassword: newPassword),
                responseType: EmptyResponseDTO.self)
            successMessage = "Contraseña cambiada correctamente"
            showChangePassword = false
        } catch { errorMessage = error.localizedDescription }
        isSaving = false
    }
}

#Preview { ProfileView() }
