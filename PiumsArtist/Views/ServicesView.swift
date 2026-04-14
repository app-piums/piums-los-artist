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

                    // Info banner (como en la web)
                    infoBanner.padding(.horizontal, 16).padding(.top, 20)
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
            Text("Piums")
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
                Button { } label: {
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
                Button { } label: {
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
                Button { } label: {
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
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "bag.badge.plus")
                    .font(.system(size: 50)).foregroundColor(.piumsOrange)
                Text("Nuevo servicio").font(.title3.weight(.semibold))
                Text("Crea un servicio que los clientes puedan reservar desde tu perfil público.")
                    .font(.subheadline).foregroundColor(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)

                VStack(spacing: 16) {
                    Text("🚧 Próximamente").font(.headline)
                    Text("El formulario de creación se implementará en la siguiente versión.")
                        .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
                }
                .padding().background(Color(.systemGray6)).cornerRadius(12).padding(.horizontal)
                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Crear servicio").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showAddService = false } } }
        }.presentationDetents([.large])
    }

    // MARK: - Helpers
    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Q"
        formatter.maximumFractionDigits = price.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: price)) ?? "Q\(Int(price))"
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
            let profileResp = try await apiService.get(
                endpoint: .artistDashboard,
                responseType: ArtistProfileResponseDTO.self
            )
            let artistId = profileResp.artist.id

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
