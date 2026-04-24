//
//  BookingsView.swift
//  PiumsArtist
//

import SwiftUI
import SwiftData

// MARK: - BookingsView

struct BookingsView: View {
    @StateObject private var viewModel = BookingsViewModel()
    @StateObject private var authService = AuthService.shared
    @Environment(\.modelContext) private var modelContext
    @State private var selectedBooking: Booking?
    @State private var bookingToDecline: Booking?

    var body: some View {
        ZStack {
            Color(.secondarySystemGroupedBackground).ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                filterBar

                Divider()

                Group {
                    if viewModel.isLoading && viewModel.bookings.isEmpty {
                        loadingState
                    } else if viewModel.filteredBookings.isEmpty {
                        emptyState
                    } else {
                        bookingsList
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear { viewModel.setModelContext(modelContext) }
        .refreshable { await viewModel.refreshData() }
        .sheet(item: $selectedBooking) { booking in
            ArtistBookingDetailView(
                booking: booking,
                onAccept: { viewModel.acceptBooking(booking) },
                onReject: { bookingToDecline = booking },
                onComplete: { viewModel.completeBooking(booking) }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "¿Rechazar esta reserva?",
            isPresented: Binding(
                get: { bookingToDecline != nil },
                set: { if !$0 { bookingToDecline = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Sí, rechazar", role: .destructive) {
                if let b = bookingToDecline { viewModel.rejectBooking(b) }
                bookingToDecline = nil
            }
            Button("Cancelar", role: .cancel) { bookingToDecline = nil }
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
            // Contador de pendientes
            if viewModel.bookings.filter({ $0.status == .pending }).count > 0 {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Circle()
                        .fill(Color.piumsOrange)
                        .frame(width: 10, height: 10)
                        .offset(x: 4, y: -4)
                }
            } else {
                Image(systemName: "bell.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BookingsViewModel.BookingFilter.allCases, id: \.rawValue) { filter in
                    StatusFilterChip(
                        title: filterLabel(filter),
                        count: countForFilter(filter),
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.updateFilter(filter)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private func filterLabel(_ filter: BookingsViewModel.BookingFilter) -> String {
        filter.rawValue
    }

    private func countForFilter(_ filter: BookingsViewModel.BookingFilter) -> Int? {
        switch filter {
        case .all:       return viewModel.bookings.isEmpty ? nil : viewModel.bookings.count
        case .pending:   return viewModel.bookings.filter { $0.status == .pending }.count > 0
                                ? viewModel.bookings.filter { $0.status == .pending }.count : nil
        case .confirmed: return viewModel.bookings.filter { $0.status == .confirmed }.count > 0
                                ? viewModel.bookings.filter { $0.status == .confirmed }.count : nil
        case .completed: return viewModel.bookings.filter { $0.status == .completed }.count > 0
                                ? viewModel.bookings.filter { $0.status == .completed }.count : nil
        case .cancelled: return viewModel.bookings.filter { $0.status == .cancelled }.count > 0
                                ? viewModel.bookings.filter { $0.status == .cancelled }.count : nil
        }
    }

    // MARK: - Bookings List

    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                if let msg = viewModel.errorMessage {
                    errorBanner(msg)
                }

                // Stats summary
                if viewModel.selectedFilter == .all && !viewModel.bookings.isEmpty {
                    statsRow.padding(.horizontal, 16).padding(.top, 4)
                }

                ForEach(viewModel.filteredBookings) { booking in
                    ArtistBookingRow(booking: booking)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedBooking = booking }
                }
                Color.clear.frame(height: 100)
            }
            .padding(.top, 12)
        }
        .scrollIndicators(.hidden)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            statPill(
                value: "\(viewModel.bookings.filter { $0.status == .pending }.count)",
                label: "Pendientes",
                color: .orange
            )
            statPill(
                value: "\(viewModel.bookings.filter { $0.status == .confirmed }.count)",
                label: "Confirmadas",
                color: .blue
            )
            statPill(
                value: "\(viewModel.bookings.filter { $0.status == .completed }.count)",
                label: "Completadas",
                color: .piumsSuccess
            )
        }
    }

    private func statPill(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.bold())
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().scaleEffect(1.3).tint(.piumsOrange)
            Text("Cargando reservas…")
                .font(.subheadline).foregroundColor(.secondary)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()

            // Ilustración
            ZStack {
                Circle()
                    .fill(Color.piumsOrange.opacity(0.08))
                    .frame(width: 120, height: 120)
                Circle()
                    .fill(Color.piumsOrange.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: emptyIcon)
                    .font(.system(size: 42, weight: .light))
                    .foregroundColor(.piumsOrange.opacity(0.7))
            }
            .padding(.bottom, 24)

            Text(emptyTitle)
                .font(.title3.bold())
                .padding(.bottom, 8)

            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if viewModel.selectedFilter == .all && !viewModel.isLoading {
                Button {
                    Task { await viewModel.refreshData() }
                } label: {
                    Label("Actualizar", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.piumsOrange)
                        .clipShape(Capsule())
                }
                .padding(.top, 24)
            }

            Spacer()
        }
    }

    private var emptyIcon: String {
        switch viewModel.selectedFilter {
        case .all:       return "calendar.badge.clock"
        case .pending:   return "clock.badge.questionmark"
        case .confirmed: return "calendar.badge.checkmark"
        case .completed: return "checkmark.seal"
        case .cancelled: return "xmark.circle"
        }
    }

    private var emptyTitle: String {
        switch viewModel.selectedFilter {
        case .all:       return "Sin reservas"
        case .pending:   return "Sin pendientes"
        case .confirmed: return "Sin confirmadas"
        case .completed: return "Sin completadas"
        case .cancelled: return "Sin canceladas"
        }
    }

    private var emptyMessage: String {
        switch viewModel.selectedFilter {
        case .all: return "Cuando recibas reservas de clientes aparecerán aquí. ¡Comparte tu perfil para comenzar!"
        default:   return "Las reservas con este estado aparecerán aquí"
        }
    }

    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.piumsWarning)
            Text(msg).font(.caption).foregroundColor(.secondary)
            Spacer()
        }
        .padding(12)
        .background(Color.piumsWarning.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }
}

// MARK: - StatusFilterChip

private struct StatusFilterChip: View {
    let title: String
    let count: Int?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                if let count = count {
                    Text("\(count)")
                        .font(.caption.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(isSelected ? Color.white.opacity(0.25) : Color.piumsOrange.opacity(0.15))
                        .foregroundStyle(isSelected ? .white : .piumsOrange)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(isSelected ? Color.piumsOrange : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - ArtistBookingRow

struct ArtistBookingRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 14) {
            // Status icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: statusIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(booking.serviceName ?? booking.clientName)
                            .font(.subheadline.bold())
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            if booking.clientName != "Cliente" && !booking.clientName.isEmpty {
                                Text(booking.clientName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            if let code = booking.bookingCode {
                                if booking.clientName != "Cliente" && !booking.clientName.isEmpty {
                                    Text("·").font(.caption).foregroundStyle(.secondary)
                                }
                                Text(code)
                                    .font(.caption2.monospaced())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        if booking.totalPrice > 0 {
                            Text(formattedPrice)
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.piumsOrange)
                        }
                        Text(formattedDate)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 6) {
                    // Status badge
                    Text(statusLabel)
                        .font(.caption2.bold())
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(statusColor.opacity(0.12))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())

                    // Time
                    HStack(spacing: 3) {
                        Image(systemName: "clock").font(.caption2)
                        Text(formattedTime)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    // Duration
                    HStack(spacing: 3) {
                        Image(systemName: "timer").font(.caption2)
                        Text("\(booking.duration) min")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var formattedPrice: String {
        let q = booking.totalPrice
        if q == 0 { return "" }
        return String(format: "$%.0f", q)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM"
        f.locale = Locale(identifier: "es_ES")
        return f.string(from: booking.scheduledDate)
    }

    private var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: booking.scheduledDate)
    }

    private var statusLabel: String {
        switch booking.status {
        case .pending:    return "Pendiente"
        case .confirmed:  return "Confirmada"
        case .inProgress: return "En progreso"
        case .completed:  return "Completada"
        case .cancelled:  return "Cancelada"
        case .noShow:     return "No asistió"
        }
    }

    private var statusColor: Color {
        switch booking.status {
        case .pending:    return .orange
        case .confirmed:  return .blue
        case .inProgress: return .piumsOrange
        case .completed:  return .piumsSuccess
        case .cancelled:  return .piumsError
        case .noShow:     return .piumsError
        }
    }

    private var statusIcon: String {
        switch booking.status {
        case .pending:    return "clock"
        case .confirmed:  return "checkmark.circle"
        case .inProgress: return "play.circle"
        case .completed:  return "checkmark.seal"
        case .cancelled:  return "xmark.circle"
        case .noShow:     return "person.slash"
        }
    }
}

// MARK: - ArtistBookingDetailView

struct ArtistBookingDetailView: View {
    let booking: Booking
    let onAccept: () -> Void
    let onReject: () -> Void
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthService.shared
    @State private var enrichedClientName: String?
    @State private var enrichedClientEmail: String?
    @State private var clientFetchDone = false

    private var hasClientInfo: Bool {
        !booking.clientName.isEmpty && booking.clientName != "Cliente"
    }
    private var displayClientName: String {
        if let name = enrichedClientName { return name }
        if !clientFetchDone && booking.clientName.hasPrefix("Cliente ···") { return "Cargando..." }
        return booking.clientName
    }
    private var displayClientEmail: String {
        enrichedClientEmail ?? (booking.clientName.hasPrefix("Cliente ···") ? "" : booking.clientEmail)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Hero estado
                    VStack(spacing: 14) {
                        ZStack {
                            Circle().fill(statusColor.opacity(0.15)).frame(width: 72, height: 72)
                            Image(systemName: statusIcon).font(.system(size: 36)).foregroundStyle(statusColor)
                        }
                        VStack(spacing: 4) {
                            Text(statusLabel).font(.title2.bold())
                            if let code = booking.bookingCode {
                                Text(code)
                                    .font(.caption.weight(.semibold).monospaced())
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(statusColor.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 20)

                    // Código de reserva
                    if let code = booking.bookingCode {
                        VStack(spacing: 6) {
                            Text("CÓDIGO DE RESERVA")
                                .font(.caption2.weight(.semibold)).foregroundStyle(.secondary).tracking(1.2)
                            Text(code).font(.title3.bold().monospaced())
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 18)
                        .background(Color.piumsOrange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.piumsOrange.opacity(0.2)))
                        .padding(.horizontal, 20)
                    }

                    // Participantes
                    detailCard("Participantes") {
                        VStack(spacing: 0) {
                            let artistName = booking.artistName.isEmpty
                                ? (authService.currentArtist?.name ?? "Artista")
                                : booking.artistName
                            let artistEmail = booking.artistEmail.isEmpty
                                ? (authService.currentArtist?.email ?? "")
                                : booking.artistEmail
                            participantRow(
                                role: "ARTISTA",
                                name: artistName,
                                email: artistEmail,
                                imageURL: authService.avatarURL,
                                gradientColors: [.piumsOrange, .piumsAccent]
                            )
                            if hasClientInfo {
                                Divider().padding(.vertical, 10)
                                participantRow(
                                    role: "CLIENTE",
                                    name: displayClientName,
                                    email: displayClientEmail,
                                    gradientColors: [.piumsInfo],
                                    systemIcon: "person.fill"
                                )
                            }
                        }
                    }

                    // Info evento
                    detailCard("Información del Evento") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                            infoCell("FECHA") {
                                Text(formattedDateLong).font(.subheadline.bold()).lineLimit(2)
                                Text(formattedTime).font(.caption).foregroundStyle(.secondary)
                            }
                            infoCell("DURACIÓN") {
                                Text("\(booking.duration) min").font(.subheadline.bold())
                            }
                            infoCell("ESTADO") {
                                HStack(spacing: 5) {
                                    Circle().fill(statusColor).frame(width: 7, height: 7)
                                    Text(statusLabel).font(.caption.weight(.semibold)).foregroundStyle(statusColor)
                                }
                            }
                            infoCell("SERVICIO") {
                                Text(booking.serviceName ?? booking.clientName)
                                    .font(.subheadline.bold()).lineLimit(1)
                            }
                        }
                    }

                    // Resumen de pago
                    detailCard("Resumen de Pago") {
                        VStack(spacing: 12) {
                            if let svc = booking.serviceName, !svc.isEmpty {
                                payRow(label: svc, value: formattedPrice, bold: false)
                                Divider()
                            }
                            payRow(label: "Total", value: formattedPrice, bold: true)
                        }
                    }

                    // Notas
                    if !booking.notes.isEmpty {
                        detailCard("Notas") {
                            Text(booking.notes).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }

                    // Acciones
                    if booking.status == .pending {
                        detailCard("Acciones") {
                            VStack(spacing: 10) {
                                actionBtn(icon: "checkmark.circle.fill", label: "Aceptar reserva", color: .piumsSuccess) {
                                    onAccept(); dismiss()
                                }
                                Divider()
                                actionBtn(icon: "xmark.circle.fill", label: "Rechazar reserva", color: .piumsError) {
                                    onReject(); dismiss()
                                }
                            }
                        }
                    } else if booking.status == .confirmed {
                        detailCard("Acciones") {
                            actionBtn(icon: "checkmark.seal.fill", label: "Marcar como completada", color: .piumsSuccess) {
                                onComplete(); dismiss()
                            }
                        }
                    }

                    Color.clear.frame(height: 20)
                }
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)
            .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
            .navigationTitle(booking.bookingCode ?? "Detalle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .task { await fetchBookingDetail() }
        }
    }

    private func fetchBookingDetail() async {
        defer { Task { await MainActor.run { clientFetchDone = true } } }
        guard !booking.remoteId.isEmpty else { return }

        let token = APIService.shared.authToken
        let decoder = JSONDecoder()

        for urlString in [
            APIConfig.currentURL + "/artists/dashboard/me/bookings/\(booking.remoteId)",
            APIConfig.currentURL + "/bookings/\(booking.remoteId)"
        ] {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let t = token { req.setValue("Bearer \(t)", forHTTPHeaderField: "Authorization") }

            guard let (data, _) = try? await URLSession.shared.data(for: req) else { continue }

            let dto: BookingDTO? = (try? decoder.decode(BookingDTO.self, from: data))
                ?? (try? decoder.decode(BookingDetailWrapper.self, from: data))?.booking

            guard let dto else { continue }
            let name = dto.resolvedClientName
            let email = dto.resolvedClientEmail
            if !name.hasPrefix("Cliente ···") && name != "Cliente" {
                await MainActor.run {
                    enrichedClientName = name
                    enrichedClientEmail = email.isEmpty ? nil : email
                }
                return
            }
        }
    }

    @ViewBuilder
    private func detailCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.headline)
            content()
        }
        .padding(18)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func infoCell<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary).tracking(0.8)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func participantRow(role: String, name: String, email: String, imageURL: String? = nil, gradientColors: [Color], systemIcon: String? = nil) -> some View {
        HStack(spacing: 12) {
            if let icon = systemIcon {
                ZStack {
                    Circle().fill(gradientColors.first?.opacity(0.12) ?? Color.blue.opacity(0.12)).frame(width: 42, height: 42)
                    Image(systemName: icon).font(.system(size: 18)).foregroundStyle(gradientColors.first ?? .blue)
                }
            } else {
                PiumsAvatarView(name: name, imageURL: imageURL, size: 42, gradientColors: gradientColors)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(role)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .tracking(0.8)
                Text(name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                if !email.isEmpty {
                    Text(email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func payRow(label: String, value: String, bold: Bool) -> some View {
        HStack {
            Text(label).font(bold ? .headline : .subheadline).foregroundStyle(bold ? .primary : .secondary)
            Spacer()
            Text(value).font(bold ? .title3.bold() : .subheadline.weight(.medium))
                .foregroundStyle(bold ? Color.piumsOrange : .primary)
        }
    }

    @ViewBuilder
    private func actionBtn(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9).fill(color.opacity(0.12)).frame(width: 36, height: 36)
                    Image(systemName: icon).font(.system(size: 15)).foregroundStyle(color)
                }
                Text(label).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var formattedPrice: String {
        let q = booking.totalPrice
        if q == 0 { return "$0.00" }
        return String(format: "$%.2f", q)
    }

    private var formattedDateLong: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE d 'de' MMMM, yyyy"
        f.locale = Locale(identifier: "es_ES")
        return f.string(from: booking.scheduledDate).capitalized
    }

    private var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: booking.scheduledDate)
    }

    private var statusLabel: String {
        switch booking.status {
        case .pending:    return "Pendiente"
        case .confirmed:  return "Confirmada"
        case .inProgress: return "En progreso"
        case .completed:  return "Completada"
        case .cancelled:  return "Cancelada"
        case .noShow:     return "No asistió"
        }
    }

    private var statusColor: Color {
        switch booking.status {
        case .pending:    return .orange
        case .confirmed:  return .blue
        case .inProgress: return .piumsOrange
        case .completed:  return .piumsSuccess
        case .cancelled:  return .piumsError
        case .noShow:     return .piumsError
        }
    }

    private var statusIcon: String {
        switch booking.status {
        case .pending:    return "clock"
        case .confirmed:  return "checkmark.circle.fill"
        case .inProgress: return "play.circle.fill"
        case .completed:  return "checkmark.seal.fill"
        case .cancelled:  return "xmark.circle.fill"
        case .noShow:     return "person.slash.fill"
        }
    }
}

#Preview {
    BookingsView()
}
