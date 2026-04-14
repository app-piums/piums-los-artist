//
//  BookingsView.swift
//  PiumsArtist
//
//  Rediseño basado en MyBookingsView de la app de cliente.
//

import SwiftUI
import SwiftData

// MARK: - BookingsView

struct BookingsView: View {
    @StateObject private var viewModel = BookingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var selectedBooking: Booking?
    @State private var bookingToDecline: Booking?

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading && viewModel.bookings.isEmpty {
                    loadingState
                } else if viewModel.bookings.isEmpty {
                    emptyState
                } else {
                    bookingsList
                }
            }
            // Barra de filtros pegada bajo la navbar
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(BookingsViewModel.BookingFilter.allCases, id: \.rawValue) { filter in
                                StatusFilterChip(
                                    title: filter.rawValue,
                                    isSelected: viewModel.selectedFilter == filter
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.updateFilter(filter)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    Divider()
                }
                .background(.bar)
            }
            .navigationTitle("Mis Reservas")
            .refreshable { await viewModel.refreshData() }
        }
        .onAppear { viewModel.setModelContext(modelContext) }
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
            isPresented: Binding(get: { bookingToDecline != nil }, set: { if !$0 { bookingToDecline = nil } }),
            titleVisibility: .visible
        ) {
            Button("Sí, rechazar", role: .destructive) {
                if let b = bookingToDecline { viewModel.rejectBooking(b) }
                bookingToDecline = nil
            }
            Button("No", role: .cancel) { bookingToDecline = nil }
        }
    }

    // MARK: - Bookings List
    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let msg = viewModel.errorMessage {
                    errorBanner(msg)
                }
                ForEach(viewModel.filteredBookings) { booking in
                    ArtistBookingRow(booking: booking)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedBooking = booking }
                }
                Color.clear.frame(height: 12)
            }
            .padding(.vertical, 8)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - States
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView().scaleEffect(1.3)
            Text("Cargando reservas…")
                .font(.subheadline).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.minus")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.5))
            Text(emptyTitle)
                .font(.headline)
            Text(emptyMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .padding(.horizontal)
    }

    private var emptyTitle: String {
        switch viewModel.selectedFilter {
        case .all: return "Sin reservas"
        case .pending: return "Sin pendientes"
        case .confirmed: return "Sin confirmadas"
        case .completed: return "Sin completadas"
        case .cancelled: return "Sin canceladas"
        }
    }

    private var emptyMessage: String {
        switch viewModel.selectedFilter {
        case .all: return "Cuando recibas reservas aparecerán aquí. ¡Comparte tu perfil para comenzar!"
        default: return "Las reservas con este estado aparecerán aquí"
        }
    }
}

// MARK: - StatusFilterChip (estilo cliente)

private struct StatusFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14).padding(.vertical, 7)
                .background(isSelected ? Color.piumsOrange : Color(.secondarySystemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - ArtistBookingRow (estilo BookingRowView del cliente)

struct ArtistBookingRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 14) {
            // Icono estado
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: statusIcon)
                        .foregroundStyle(statusColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                // Código + precio
                HStack {
                    Text(booking.bookingCode ?? booking.clientName)
                        .font(.headline)
                    Spacer()
                    Text(formattedPrice)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.piumsOrange)
                }

                // Badge status
                Text(statusLabel)
                    .font(.caption.bold())
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(statusColor.opacity(0.12))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())

                // Fecha + hora
                HStack(spacing: 4) {
                    Image(systemName: "calendar").font(.caption2)
                    Text(formattedDate)
                    Text("·")
                    Image(systemName: "clock").font(.caption2)
                    Text(formattedTime)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                // Nombre del servicio si existe
                if let svc = booking.serviceName, !svc.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "bag").font(.caption2)
                        Text(svc)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Helpers

    private var formattedPrice: String {
        let q = booking.totalPrice
        if q == 0 { return "" }
        return String(format: "Q %.2f", q)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
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
        case .completed:  return .green
        case .cancelled:  return .red
        case .noShow:     return .red
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

// MARK: - ArtistBookingDetailView (estilo BookingDetailView del cliente)

struct ArtistBookingDetailView: View {
    let booking: Booking
    let onAccept: () -> Void
    let onReject: () -> Void
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // ── Hero: estado ──
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

                    // ── Código de reserva ──
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

                    // ── Info del evento ──
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
                            infoCell("CLIENTE") {
                                Text(booking.clientName).font(.subheadline.bold()).lineLimit(1)
                            }
                        }
                    }

                    // ── Resumen de pago ──
                    detailCard("Resumen de Pago") {
                        VStack(spacing: 12) {
                            if let svc = booking.serviceName, !svc.isEmpty {
                                payRow(label: svc, value: formattedPrice, bold: false)
                                Divider()
                            }
                            payRow(label: "Total", value: formattedPrice, bold: true)
                        }
                    }

                    // ── Notas ──
                    if !booking.notes.isEmpty {
                        detailCard("Notas") {
                            Text(booking.notes).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }

                    // ── Acciones del artista ──
                    if booking.status == .pending {
                        detailCard("Acciones") {
                            VStack(spacing: 10) {
                                actionBtn(icon: "checkmark.circle.fill", label: "Aceptar reserva", color: .green) {
                                    onAccept(); dismiss()
                                }
                                Divider()
                                actionBtn(icon: "xmark.circle.fill", label: "Rechazar reserva", color: .red) {
                                    onReject(); dismiss()
                                }
                            }
                        }
                    } else if booking.status == .confirmed {
                        detailCard("Acciones") {
                            actionBtn(icon: "checkmark.seal.fill", label: "Marcar como completada", color: .green) {
                                onComplete(); dismiss()
                            }
                        }
                    }

                    Color.clear.frame(height: 20)
                }
                .padding(.top, 16)
            }
            .scrollIndicators(.hidden)
            .navigationTitle(booking.bookingCode ?? "Detalle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func detailCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.headline)
            content()
        }
        .padding(18)
        .background(Color(.secondarySystemBackground))
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

    // MARK: - Helpers

    private var formattedPrice: String {
        let q = booking.totalPrice
        if q == 0 { return "Q 0.00" }
        return String(format: "Q %.2f", q)
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
        case .completed:  return .green
        case .cancelled:  return .red
        case .noShow:     return .red
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
