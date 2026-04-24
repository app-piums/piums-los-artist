//
//  ProfileView.swift
//  PiumsArtist
//
//  Conectado a ProfileViewModel — muestra datos reales del backend.
//

import SwiftUI
import PhotosUI
import Combine

// MARK: - Profile View

struct ProfileView: View {
    @StateObject private var vm = ProfileViewModel()
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    @State private var showVerificacion = false
    @State private var showEditProfile = false
    @State private var showPrivacidad = false
    @State private var showSoporte = false
    @State private var showPhotoPicker = false
    @State private var photoItem: PhotosPickerItem?
    @State private var isUploadingPhoto = false

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
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(.secondarySystemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .refreshable { await vm.refreshData() }
            .sheet(isPresented: $showEditProfile, onDismiss: {
                Task { await vm.refreshData() }
            }) { EditArtistProfileSheet() }
            .sheet(isPresented: $showPrivacidad) { LegalTextSheet(title: "Política de privacidad", systemImage: "hand.raised") }
            .sheet(isPresented: $showSoporte) { ContactSoporteSheet() }
            .sheet(isPresented: $showingSettings) {
                SettingsView().environmentObject(ThemeManager.shared)
            }
            .sheet(isPresented: $showVerificacion) {
                VerificacionView(onComplete: {
                    authService.needsVerification = false
                })
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task { await uploadPhoto(item) }
            }
            .overlay {
                if vm.isLoading && vm.artist == nil {
                    PiumsLoadingView("Cargando perfil...")
                }
            }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("Aceptar") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: - Header

    private var profileHeader: some View {
        VStack(spacing: 16) {
            PiumsAvatarView(
                name: artist?.name ?? "A",
                imageURL: vm.avatarURL ?? artist?.avatarURL,
                size: 90,
                gradientColors: [.piumsOrange, .piumsAccent]
            )
            .id(vm.avatarURL ?? artist?.avatarURL ?? "init")
            .overlay(alignment: .bottomTrailing) {
                Button { showPhotoPicker = true } label: {
                    ZStack {
                        if isUploadingPhoto {
                            ProgressView().scaleEffect(0.7).tint(.white)
                        } else {
                            Image(systemName: "camera.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 28, height: 28)
                    .background(Color.piumsOrange)
                    .clipShape(Circle())
                }
                .disabled(isUploadingPhoto)
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
            settingsRow("Configuración",            icon: "gearshape")          { showingSettings = true }
            rowDivider
            // Verificación con badge dinámico
            Button { showVerificacion = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "shield.checkered")
                        .frame(width: 22)
                    Text("Verificación de Identidad")
                        .font(.subheadline)
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
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption2).foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
            rowDivider
            settingsRow("Notificaciones",           icon: "bell") {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            rowDivider
            settingsRow("Privacidad",               icon: "hand.raised")        { showPrivacidad = true }
            rowDivider
            settingsRow("Ayuda y Soporte",          icon: "questionmark.circle") { showSoporte = true }
            rowDivider
            Button(role: .destructive) { AuthService.shared.logout() } label: {
                HStack {
                    Spacer()
                    Text("Cerrar Sesión").font(.subheadline.weight(.medium))
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    private var rowDivider: some View {
        Divider().padding(.leading, 16)
    }

    private func settingsRow(_ label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).frame(width: 22)
                Text(label).font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right").font(.caption2).foregroundColor(.secondary)
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
    }

    // MARK: - Photo upload
    private func uploadPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let jpeg = resizedJPEG(from: image, maxDimension: 800, quality: 0.7) else {
            photoItem = nil; return
        }
        isUploadingPhoto = true
        defer { isUploadingPhoto = false; photoItem = nil }

        guard let url = URL(string: APIConfig.currentURL + APIEndpoint.uploadAvatar.path) else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        if let token = APIService.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        // Boundary simple sin guiones para mayor compatibilidad
        let boundary = "piumsboundary\(Int(Date().timeIntervalSince1970))"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        let crlf = "\r\n"
        body.append("--\(boundary)\(crlf)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\(crlf)".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\(crlf)\(crlf)".data(using: .utf8)!)
        body.append(jpeg)
        body.append("\(crlf)--\(boundary)--\(crlf)".data(using: .utf8)!)
        request.httpBody = body

        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            let rawResponse = String(data: responseData, encoding: .utf8) ?? "(no decodificable)"
            print("[AVATAR UPLOAD] status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
            print("[AVATAR UPLOAD] body: \(rawResponse)")

            if let http = response as? HTTPURLResponse, http.statusCode >= 300 {
                let serverMsg = (try? JSONDecoder().decode([String: String].self, from: responseData))?["message"]
                             ?? (try? JSONDecoder().decode([String: String].self, from: responseData))?["error"]
                             ?? rawResponse.prefix(300).description
                vm.errorMessage = "Error \(http.statusCode): \(serverMsg)"
                return
            }

            // Extraer la URL del avatar de la respuesta del servidor
            let newAvatarURL = extractAvatarURL(from: responseData)

            // Limpiar caché de imágenes para forzar recarga
            URLCache.shared.removeAllCachedResponses()

            if let newURL = newAvatarURL {
                vm.avatarURL = newURL
                AuthService.shared.avatarURL = newURL
                AuthService.shared.currentArtist?.avatarURL = newURL

                // Sincronizar con el artists-service para que la web también vea el cambio
                let avatarBody = UpdateArtistAvatarRequest(avatar: newURL, imageUrl: newURL)
                try? await APIService.shared.put(
                    endpoint: .updateArtistProfile,
                    body: avatarBody,
                    responseType: ArtistProfileResponseDTO.self
                )
            }
            // Siempre refrescar para sincronizar el resto del perfil
            await vm.refreshData()
        } catch {
            vm.errorMessage = "Error al subir la foto: \(error.localizedDescription)"
        }
    }

    private func resizedJPEG(from image: UIImage, maxDimension: CGFloat, quality: CGFloat) -> Data? {
        let size = image.size
        let ratio = min(maxDimension / size.width, maxDimension / size.height, 1)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: quality)
    }

    private func extractAvatarURL(from data: Data) -> String? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let resp = try? decoder.decode(AvatarUploadResponseDTO.self, from: data),
           let url = resp.resolvedURL { return url }
        if let resp = try? decoder.decode(AvatarUploadUserWrapperDTO.self, from: data),
           let url = resp.resolvedURL { return url }
        // Buscar cualquier valor de string que parezca URL de imagen
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let candidates = json.values.compactMap { $0 as? String }
            return candidates.first { $0.hasPrefix("http") && (
                $0.contains("avatar") || $0.contains("image") || $0.contains("upload") || $0.contains("cdn")
            )}
        }
        return nil
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
            // Perfil del artista → PUT /artists/dashboard/me
            let trimmedName = name.trimmingCharacters(in: .whitespaces)
            let body = UpdateArtistProfileRequest(
                displayName: trimmedName.isEmpty ? nil : trimmedName,
                nombre: trimmedName.isEmpty ? nil : trimmedName,
                bio: bio.isEmpty ? nil : bio,
                phone: phone.isEmpty ? nil : phone
            )
            let _ = try await APIService.shared.put(
                endpoint: .updateArtistProfile,
                body: body,
                responseType: ArtistProfileResponseDTO.self
            )

            // Actualizar estado local y notificar a todas las vistas
            AuthService.shared.objectWillChange.send()
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
    @State private var showDisputas = false
    @State private var showTerminos = false
    @State private var showPrivacidad = false
    @State private var showSoporte = false

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
                    Button { showDisputas = true } label: {
                        Label("Mis quejas", systemImage: "exclamationmark.bubble")
                    }
                    Button { showTerminos = true } label: {
                        Label("Términos y condiciones", systemImage: "doc.text")
                    }
                    Button { showPrivacidad = true } label: {
                        Label("Política de privacidad", systemImage: "hand.raised")
                    }
                    Button { showSoporte = true } label: {
                        Label("Contactar soporte", systemImage: "message")
                    }
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
            .sheet(isPresented: $showDisputas) { DisputasView().presentationDetents([.large]) }
            .sheet(isPresented: $showTerminos) { LegalTextSheet(title: "Términos y condiciones", systemImage: "doc.text") }
            .sheet(isPresented: $showPrivacidad) { LegalTextSheet(title: "Política de privacidad", systemImage: "hand.raised") }
            .sheet(isPresented: $showSoporte) { ContactSoporteSheet() }
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

// MARK: - Legal Text Sheet (reutilizable para Términos y Privacidad)

struct LegalTextSheet: View {
    let title: String
    let systemImage: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.piumsOrange.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: systemImage)
                            .font(.system(size: 32))
                            .foregroundColor(.piumsOrange)
                    }
                    .padding(.top, 20)

                    Text("Este documento estará disponible en piums.com. Por el momento puedes consultarlo en nuestra página web oficial.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Link("Visitar piums.com", destination: URL(string: "https://piums.com")!)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.piumsOrange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.piumsOrange.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Contact Support Sheet

struct ContactSoporteSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.piumsInfo.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: "headphones")
                            .font(.system(size: 32))
                            .foregroundColor(.piumsInfo)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 6) {
                        Text("¿Necesitas ayuda?")
                            .font(.title3.weight(.bold))
                        Text("Nuestro equipo de soporte está disponible para ayudarte.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    VStack(spacing: 12) {
                        Link(destination: URL(string: "mailto:soporte@piums.io")!) {
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.piumsOrange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Correo electrónico")
                                        .font(.subheadline.weight(.semibold))
                                    Text("soporte@piums.io")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)

                        Link(destination: URL(string: "https://piums.com")!) {
                            HStack(spacing: 12) {
                                Image(systemName: "globe")
                                    .foregroundColor(.piumsInfo)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Centro de ayuda")
                                        .font(.subheadline.weight(.semibold))
                                    Text("piums.com")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(16)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
            }
            .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Contactar soporte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

#Preview { ProfileView() }
