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
    @State private var showAddService = false

    var body: some View {
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
                }

                Spacer(minLength: 120)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .refreshable { await viewModel.refreshData() }
        .sheet(isPresented: $showAddService) { addServiceSheet }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            PiumsAvatarView(name: "A", imageURL: nil, size: 38,
                            gradientColors: [.piumsOrange, .piumsAccent])
            Spacer()
            Text("Piuma")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.piumsOrange)
            Spacer()
            Button { } label: {
                Image(systemName: "gearshape.fill").font(.title3).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Mis Servicios")
                    .font(.title2.weight(.bold))
                Text("\(viewModel.services.count) servicio\(viewModel.services.count == 1 ? "" : "s") activo\(viewModel.services.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button { showAddService = true } label: {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.piumsOrange)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Services List
    private var servicesList: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.services) { service in
                serviceCard(service)
            }
        }
    }

    private func serviceCard(_ service: Service) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Status badge
                Text(service.isActive ? "Activo" : "Inactivo")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(service.isActive ? .piumsSuccess : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background((service.isActive ? Color.piumsSuccess : .secondary).opacity(0.12))
                    .cornerRadius(6)

                Spacer()

                // Price
                Text("Q\(Int(service.price))")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.piumsOrange)
            }

            Text(service.name)
                .font(.headline)
                .lineLimit(2)

            if !service.serviceDescription.isEmpty {
                Text(service.serviceDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack(spacing: 16) {
                Label("\(service.duration) min", systemImage: "clock")
                Label(service.category, systemImage: "tag")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            Divider()

            HStack(spacing: 16) {
                Button { } label: {
                    Label("Editar", systemImage: "pencil")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.piumsInfo)
                }
                Spacer()
                Button { } label: {
                    Label(service.isActive ? "Desactivar" : "Activar", systemImage: service.isActive ? "eye.slash" : "eye")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - States
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("Cargando servicios…")
                .font(.subheadline)
                .foregroundColor(.secondary)
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
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button { showAddService = true } label: {
                Label("Agregar servicio", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.piumsOrange)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Add Service Sheet
    private var addServiceSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "bag.badge.plus")
                    .font(.system(size: 50))
                    .foregroundColor(.piumsOrange)

                Text("Nuevo servicio")
                    .font(.title3.weight(.semibold))

                Text("Crea un servicio que los clientes puedan reservar desde tu perfil público.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Placeholder — real form will come later
                VStack(spacing: 16) {
                    Text("🚧 Próximamente")
                        .font(.headline)
                    Text("El formulario de creación se implementará en la siguiente versión.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Crear servicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { showAddService = false }
                }
            }
        }
        .presentationDetents([.large])
    }
}

// MARK: - Services ViewModel
@MainActor
final class ServicesViewModel: ObservableObject {
    @Published var services: [Service] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

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
            // First get artistId from profile
            let profileResp = try await apiService.get(
                endpoint: .artistDashboard,
                responseType: ArtistProfileResponseDTO.self
            )
            let artistId = profileResp.artist.id

            // Then fetch services for this artist
            let servicesResp = try await apiService.get(
                endpoint: .catalogServices(artistId: artistId, category: nil),
                responseType: ServicesResponseDTO.self
            )
            self.services = servicesResp.services.map { $0.toDomainModel() }
        } catch {
            self.errorMessage = error.localizedDescription
            loadMockData()
        }

        isLoading = false
    }

    private func loadMockData() {
        services = Service.previewServices
    }
}

#Preview { ServicesView() }
