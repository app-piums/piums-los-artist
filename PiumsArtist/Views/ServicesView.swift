//
//  ServicesView.swift
//  PiumsArtist
//
//  Vista de gestión de servicios del artista.
//  Consume /catalog/services?artistId=X y permite CRUD.
//

import SwiftUI
import Combine

struct ServicesView: View {
    @StateObject private var viewModel = ServicesViewModel()
    @StateObject private var authService = AuthService.shared
    @State private var showAddService = false
    @State private var showEditService = false
    @State private var selectedService: Service?
    @State private var showDeleteConfirmation = false
    @State private var serviceToDelete: Service?
    @State private var showSettings = false

    var body: some View {
        ZStack {
            Color(.secondarySystemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    topBar.padding(.horizontal, 20).padding(.top, 8)

                    headerSection.padding(.horizontal, 20).padding(.top, 16)

                    if viewModel.isLoading {
                        loadingState.padding(.top, 60)
                    } else if viewModel.services.isEmpty {
                        emptyState.padding(.top, 60)
                    } else {
                        servicesList.padding(.horizontal, 16).padding(.top, 16)

                        // Info banner (como en la web)
                        infoBanner.padding(.horizontal, 16).padding(.top, 20)
                    }

                    Spacer(minLength: 120)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .refreshable { await viewModel.refreshData() }
        .sheet(isPresented: $showSettings) { SettingsView().environmentObject(ThemeManager.shared) }
        .sheet(isPresented: $showAddService) { addServiceSheet }
        .sheet(isPresented: $showEditService) {
            if let service = selectedService {
                editServiceSheet(service)
            }
        }
        .confirmationDialog("¿Eliminar este servicio?",
                            isPresented: $showDeleteConfirmation,
                            titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                if let service = serviceToDelete {
                    Task { await viewModel.deleteService(service) }
                }
            }
            Button("Cancelar", role: .cancel) { }
        } message: {
            Text("Esta acción no se puede deshacer")
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            PiumsAvatarView(name: authService.currentArtist?.name ?? "A",
                            imageURL: authService.avatarURL, size: 38,
                            gradientColors: [.piumsOrange, .piumsAccent])
            .id(authService.avatarURL ?? "init")
            Spacer()
            Image("PiumsLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 40)
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape.fill").font(.title3).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mis Servicios")
                        .font(.title2.weight(.bold))
                    Text("Administra los servicios que ofreces")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { showAddService = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.caption.weight(.bold))
                        Text("Nuevo Servicio")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.piumsOrange)
                    .cornerRadius(10)
                }
            }
        }
    }

    // MARK: - Services List
    private var servicesList: some View {
        LazyVStack(spacing: 14) {
            ForEach(viewModel.services) { service in
                serviceCard(service)
            }
        }
    }

    // MARK: - Service Card (estilo web)
    private func serviceCard(_ service: Service) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Row 1: Nombre + badge ──
            HStack(alignment: .top) {
                Text(service.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Text(service.isActive ? "Activo" : "Inactivo")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(service.isActive ? .piumsSuccess : .secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background((service.isActive ? Color.piumsSuccess : .secondary).opacity(0.12))
                    .cornerRadius(20)
            }
            .padding(.bottom, 8)

            // ── Row 2: Descripción ──
            if !service.serviceDescription.isEmpty {
                Text(service.serviceDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.bottom, 12)
            }

            // ── Row 3: Precio base + Tipo ──
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Precio base")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatPrice(service.price))
                        .font(.title3.weight(.bold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Tipo")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(pricingLabel(service))
                        .font(.subheadline.weight(.medium))
                }

                Spacer()
            }
            .padding(.bottom, 14)

            // ── Row 4: Action buttons ──
            HStack(spacing: 8) {
                // Editar
                Button {
                    selectedService = service
                    showEditService = true
                } label: {
                    HStack(spacing: 5) {
                        Text("✏️")
                            .font(.caption2)
                        Text("Editar")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.piumsOrange)
                    .cornerRadius(8)
                }

                // Desactivar / Activar
                Button {
                    Task {
                        await viewModel.toggleServiceStatus(service)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text("⏸")
                            .font(.caption2)
                        Text(service.isActive ? "Desactivar" : "Activar")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }

                // Eliminar
                Button {
                    serviceToDelete = service
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash.fill")
                        .font(.caption)
                        .foregroundColor(.piumsError)
                        .frame(width: 38, height: 38)
                        .background(Color.piumsError.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Info Banner
    private var infoBanner: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("💡")
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Gestión de Servicios")
                    .font(.subheadline.weight(.semibold))
                Text("Los servicios activos aparecen en tu perfil público y están disponibles para reserva. Los servicios inactivos permanecen guardados pero no son visibles para los clientes.")
                    .font(.caption)
                    .foregroundColor(.piumsInfo)
            }
        }
        .padding(14)
        .background(Color.piumsInfo.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - States
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text("Cargando servicios…")
                .font(.subheadline).foregroundColor(.secondary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bag.fill")
                .font(.system(size: 50))
                .foregroundColor(.piumsOrange.opacity(0.4))
            Text("Sin servicios")
                .font(.headline)
            Text("Agrega tu primer servicio para que los clientes puedan reservarte.")
                .font(.subheadline).foregroundColor(.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, 40)

            Button { showAddService = true } label: {
                Label("Agregar servicio", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Color.piumsOrange).cornerRadius(12)
            }.padding(.top, 8)
        }
    }

    // MARK: - Add Service Sheet
    private var addServiceSheet: some View {
        ServiceFormView(mode: .create) {
            showAddService = false
            Task { await viewModel.refreshData() }
        }
    }

    // MARK: - Edit Service Sheet
    private func editServiceSheet(_ service: Service) -> some View {
        ServiceFormView(mode: .edit(service)) {
            showEditService = false
            Task { await viewModel.refreshData() }
        }
    }

    // MARK: - Helpers
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = price.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: price)) ?? "$\(Int(price))"
    }

    private func pricingLabel(_ service: Service) -> String {
        switch service.pricingType.uppercased() {
        case "HOURLY":      return "Por hora"
        case "PER_SESSION": return "Por sesión"
        case "CUSTOM":      return "Personalizado"
        default:            return "Precio fijo"
        }
    }
}

// MARK: - Services ViewModel
@MainActor
final class ServicesViewModel: ObservableObject {
    @Published var services: [Service] = []
    @Published var categories: [ServiceCategoryItemDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// artistId del backend — cacheado para no repetir la llamada al perfil en cada operación
    private(set) var cachedArtistId: String = ""

    private let apiService = APIService.shared

    init() {
        Task { await loadServices() }
    }

    func refreshData() async {
        await loadServices()
    }

    private func loadServices() async {
        isLoading = true
        errorMessage = nil

        do {
            // Usar el artistId persistido si ya está disponible; si no, obtenerlo del perfil
            let artistId: String
            if let saved = AuthService.shared.artistBackendId, !saved.isEmpty {
                artistId = saved
            } else {
                let profileResp = try await apiService.get(
                    endpoint: .artistDashboard,
                    responseType: ArtistProfileResponseDTO.self
                )
                artistId = profileResp.artist.id
                AuthService.shared.artistBackendId = artistId
            }
            cachedArtistId = artistId

            async let servicesTask = apiService.get(
                endpoint: .catalogServices(artistId: artistId, category: nil),
                responseType: ServicesResponseDTO.self
            )
            async let categoriesTask = apiService.get(
                endpoint: .serviceCategories,
                responseType: ServiceCategoriesResponseDTO.self
            )
            let (servicesResp, cats) = try await (servicesTask, categoriesTask)
            self.services = servicesResp.services.map { $0.toDomainModel() }
            self.categories = cats
        } catch {
            self.errorMessage = error.localizedDescription
            loadMockData()
        }

        isLoading = false
    }

    private func loadMockData() {
        services = Service.previewServices
    }

    // MARK: - CRUD

    func deleteService(_ service: Service) async {
        guard !service.remoteId.isEmpty else { return }
        let artistId = cachedArtistId.isEmpty
            ? (AuthService.shared.artistBackendId ?? "") : cachedArtistId
        isLoading = true
        do {
            let _ = try await apiService.request(
                endpoint: .deleteService(service.remoteId, artistId: artistId),
                method: .DELETE,
                responseType: EmptyResponseDTO.self
            )
            await loadServices()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleServiceStatus(_ service: Service) async {
        guard !service.remoteId.isEmpty else { return }
        let artistId = cachedArtistId.isEmpty
            ? (AuthService.shared.artistBackendId ?? "") : cachedArtistId
        isLoading = true
        do {
            struct ToggleBody: Encodable { let artistId: String }
            let body = try JSONEncoder().encode(AnyEncodable(ToggleBody(artistId: artistId)))
            let _ = try await apiService.request(
                endpoint: .toggleServiceStatus(service.remoteId),
                method: .PATCH,
                body: body,
                responseType: ServiceDTO.self
            )
            await loadServices()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createService(name: String, description: String, categoryId: String,
                       pricingType: String, priceUSD: Double, durationMin: Int) async throws {
        let artistId = cachedArtistId.isEmpty
            ? (AuthService.shared.artistBackendId ?? "") : cachedArtistId
        guard !artistId.isEmpty else {
            throw NSError(domain: "ServicesVM", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Perfil de artista no cargado aún. Vuelve a intentarlo."])
        }
        // Generar slug a partir del nombre
        let slug = makeSlug(from: name) + "-" + String(Int.random(in: 1000...9999))
        let body = CreateServiceRequest(
            artistId: artistId,
            name: name,
            slug: slug,
            description: description.count >= 10 ? description : description + String(repeating: ".", count: max(0, 10 - description.count)),
            categoryId: categoryId,
            pricingType: pricingType,
            basePrice: Int(priceUSD * 100),
            currency: "USD",
            durationMin: durationMin
        )
        let _ = try await apiService.post(endpoint: .createService, body: body, responseType: ServiceDTO.self)
        await loadServices()
    }

    func updateServiceFields(_ service: Service, name: String, description: String,
                              categoryId: String, pricingType: String,
                              priceUSD: Double, durationMin: Int) async throws {
        let artistId = cachedArtistId.isEmpty
            ? (AuthService.shared.artistBackendId ?? "") : cachedArtistId
        let slug = service.slug.isEmpty ? makeSlug(from: name) : service.slug
        let body = UpdateServiceRequest(
            artistId: artistId,
            name: name,
            slug: slug,
            description: description.count >= 10 ? description : description + String(repeating: ".", count: max(0, 10 - description.count)),
            categoryId: categoryId.isEmpty ? service.categoryId : categoryId,
            pricingType: pricingType,
            basePrice: Int(priceUSD * 100),
            currency: "USD",
            durationMin: durationMin
        )
        let _ = try await apiService.put(
            endpoint: .updateService(service.remoteId.isEmpty ? service.id.uuidString : service.remoteId),
            body: body,
            responseType: ServiceDTO.self
        )
        await loadServices()
    }

    // MARK: - Helpers

    private func makeSlug(from name: String) -> String {
        let normalized = name
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        let slug = normalized
            .components(separatedBy: CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-")).inverted)
            .joined(separator: "-")
            .components(separatedBy: "--").joined(separator: "-")
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return slug.isEmpty ? "servicio" : slug
    }
}

// MARK: - Service Form View (Crear / Editar)

struct ServiceFormView: View {
    enum Mode {
        case create
        case edit(Service)
    }

    let mode: Mode
    let onDone: () -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: ServicesViewModel = ServicesViewModel()

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var pricingType: String = "FIXED"
    @State private var priceText: String = ""
    @State private var durationMin: Int = 60
    @State private var selectedCategoryId: String = ""

    @State private var isSaving = false
    @State private var errorMessage: String?

    private let pricingOptions: [(String, String)] = [
        ("FIXED",       "Precio fijo"),
        ("HOURLY",      "Por hora"),
        ("PER_SESSION", "Por sesión"),
        ("CUSTOM",      "Personalizado")
    ]

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationView {
            Form {
                // Información básica
                Section("Información del servicio") {
                    TextField("Nombre del servicio *", text: $name)
                    TextField("Descripción (mínimo 10 caracteres)", text: $description, axis: .vertical)
                        .lineLimit(3...5)
                }

                // Categoría
                Section("Categoría") {
                    if vm.categories.isEmpty {
                        HStack {
                            ProgressView().scaleEffect(0.8)
                            Text("Cargando categorías…").foregroundColor(.secondary).font(.subheadline)
                        }
                    } else {
                        Picker("Categoría *", selection: $selectedCategoryId) {
                            Text("Seleccionar…").tag("")
                            ForEach(vm.categories, id: \.id) { cat in
                                Text(cat.name).tag(cat.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // Precio
                Section("Precio") {
                    Picker("Tipo de precio", selection: $pricingType) {
                        ForEach(pricingOptions, id: \.0) { opt in
                            Text(opt.1).tag(opt.0)
                        }
                    }
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                    }
                }

                // Duración
                Section("Duración estimada") {
                    Stepper("\(durationMin) min", value: $durationMin, in: 15...480, step: 15)
                }

                // Error
                if let msg = errorMessage {
                    Section {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.piumsError)
                            Text(msg).font(.caption).foregroundColor(.piumsError)
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle(isEditing ? "Editar servicio" : "Nuevo servicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Guardando…" : "Guardar") {
                        Task { await save() }
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.piumsOrange)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                              || selectedCategoryId.isEmpty
                              || isSaving)
                }
            }
        }
        .task { prefill() }
        .presentationDetents([.large])
    }

    private func prefill() {
        if case .edit(let service) = mode {
            name = service.name
            description = service.serviceDescription
            pricingType = service.pricingType.uppercased()
            priceText = service.price > 0 ? String(format: "%.2f", service.price) : ""
            durationMin = service.duration
            selectedCategoryId = service.categoryId
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        let price = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0
        do {
            if case .edit(let service) = mode {
                try await vm.updateServiceFields(
                    service, name: name, description: description,
                    categoryId: selectedCategoryId,
                    pricingType: pricingType, priceUSD: price, durationMin: durationMin
                )
            } else {
                try await vm.createService(
                    name: name, description: description,
                    categoryId: selectedCategoryId,
                    pricingType: pricingType, priceUSD: price, durationMin: durationMin
                )
            }
            dismiss()
            onDone()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview { ServicesView() }
