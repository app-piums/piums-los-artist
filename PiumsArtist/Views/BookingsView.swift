//
//  BookingsView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI
import SwiftData

struct BookingsView: View {
    @StateObject private var viewModel = BookingsViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showingBookingDetail = false
    @State private var selectedBooking: Booking?
    @State private var showingCreateBooking = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with filters
                headerSection
                
                // Content based on state
                Group {
                    if viewModel.isLoading {
                        loadingState
                    } else if viewModel.filteredBookings.isEmpty {
                        emptyState
                    } else {
                        bookingsList
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .sheet(isPresented: $showingBookingDetail) {
            if let booking = selectedBooking {
                BookingDetailSheet(booking: binding(for: booking))
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .sheet(isPresented: $showingCreateBooking) {
            CreateBookingSheet()
                .presentationDetents([.large])
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Title and actions
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reservas")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(.piumsTextPrimary)
                    
                    Text("\(viewModel.filteredBookings.count) reservas")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.piumsTextSecondary)
                }
                
                Spacer()
                
                Button(action: { showingCreateBooking = true }) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.piumsPrimary)
                        .clipShape(Circle())
                }
                .buttonStyle(PiumsButtonStyle())
            }
            
            // Filter chips
            filterChips
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .background(Color.piumsBackground)
    }
    
    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BookingsViewModel.BookingFilter.allCases, id: \.rawValue) { filter in
                    FilterChip(
                        title: filter.rawValue,
                        isSelected: viewModel.selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.updateFilter(filter)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Content States
    private var loadingState: some View {
        PiumsLoadingView("Cargando reservas...", style: .fullScreen)
    }
    
    private var emptyState: some View {
        PiumsEmptyState(
            icon: "calendar.badge.plus",
            title: emptyStateTitle,
            message: emptyStateMessage,
            primaryAction: PiumsEmptyState.ActionConfig("Nueva Reserva", icon: "plus.circle.fill") {
                showingCreateBooking = true
            },
            secondaryAction: viewModel.selectedFilter != .all ? 
                PiumsEmptyState.ActionConfig("Ver Todas") {
                    viewModel.updateFilter(.all)
                } : nil
        )
    }
    
    // MARK: - Bookings List
    private var bookingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(groupedBookings.keys.sorted(by: >), id: \.self) { date in
                    BookingGroupSection(
                        date: date,
                        bookings: groupedBookings[date] ?? [],
                        onBookingTap: { booking in
                            selectedBooking = booking
                            showingBookingDetail = true
                        },
                        onAccept: { booking in
                            viewModel.acceptBooking(booking)
                        },
                        onReject: { booking in
                            viewModel.rejectBooking(booking)
                        },
                        onComplete: { booking in
                            viewModel.completeBooking(booking)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Tab bar padding
        }
    }
    
    // MARK: - Helper Methods
    private func countForFilter(_ filter: BookingsViewModel.BookingFilter) -> Int {
        switch filter {
        case .all: return viewModel.bookings.count
        case .pending: return viewModel.bookings.filter { $0.status == .pending }.count
        case .confirmed: return viewModel.bookings.filter { $0.status == .confirmed }.count
        case .completed: return viewModel.bookings.filter { $0.status == .completed }.count
        case .cancelled: return viewModel.bookings.filter { $0.status == .cancelled }.count
        }
    }
    
    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .all: return "No tienes reservas"
        case .pending: return "No hay reservas pendientes"
        case .confirmed: return "No hay reservas confirmadas"
        case .completed: return "No hay reservas completadas"
        case .cancelled: return "No hay reservas canceladas"
        }
    }
    
    private var emptyStateMessage: String {
        switch viewModel.selectedFilter {
        case .all: return "Cuando recibas reservas aparecerán aquí. ¡Comparte tu perfil para comenzar!"
        case .pending: return "Las reservas pendientes de confirmación aparecerán aquí"
        case .confirmed: return "Las reservas confirmadas aparecerán aquí"
        case .completed: return "Tus servicios completados aparecerán aquí"
        case .cancelled: return "Las reservas canceladas aparecerán aquí"
        }
    }
    
    private var groupedBookings: [String: [Booking]] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        return Dictionary(grouping: viewModel.filteredBookings) { booking in
            dateFormatter.string(from: booking.scheduledDate)
        }
    }
    
    private func binding(for booking: Booking) -> Binding<Booking> {
        guard let bookingIndex = viewModel.bookings.firstIndex(where: { $0.id == booking.id }) else {
            fatalError("Can't find booking in array")
        }
        return $viewModel.bookings[bookingIndex]
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void
    
    init(title: String, isSelected: Bool, count: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.count = count
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                
                if let count = count, count > 0 {
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(isSelected ? .piumsPrimary : .white)
                        .frame(width: 20, height: 20)
                        .background(isSelected ? .white : Color.piumsPrimary.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            .foregroundColor(isSelected ? .piumsPrimary : .piumsTextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.piumsPrimary.opacity(0.1) : Color.piumsSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.piumsPrimary : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PiumsButtonStyle())
    }
}

// MARK: - Booking Group Section
struct BookingGroupSection: View {
    let date: String
    let bookings: [Booking]
    let onBookingTap: (Booking) -> Void
    let onAccept: (Booking) -> Void
    let onReject: (Booking) -> Void
    let onComplete: (Booking) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date header
            HStack {
                Text(date)
                    .font(.headline.weight(.bold))
                    .foregroundColor(.piumsTextPrimary)
                
                Spacer()
                
                Text("\(bookings.count) reservas")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.piumsTextSecondary)
            }
            
            // Bookings cards
            VStack(spacing: 8) {
                ForEach(bookings, id: \.id) { booking in
                    ModernBookingRow(
                        booking: booking,
                        onTap: { onBookingTap(booking) },
                        onAccept: { onAccept(booking) },
                        onReject: { onReject(booking) },
                        onComplete: { onComplete(booking) }
                    )
                }
            }
        }
    }
}

// MARK: - Modern Booking Row
struct ModernBookingRow: View {
    let booking: Booking
    let onTap: () -> Void
    let onAccept: () -> Void
    let onReject: () -> Void
    let onComplete: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            PiumsCard(style: .bordered, padding: 16) {
                VStack(spacing: 16) {
                    // Main booking info
                    HStack(spacing: 16) {
                        // Time section
                        VStack(spacing: 4) {
                            Text(booking.scheduledDate, formatter: timeFormatter)
                                .font(.title3.weight(.bold))
                                .foregroundColor(.piumsPrimary)
                            
                            Text("\(booking.duration)min")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.piumsTextTertiary)
                        }
                        .frame(width: 70)
                        
                        // Booking details
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(booking.clientName)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.piumsTextPrimary)
                                
                                Spacer()
                                
                                PiumsStatusBadge(
                                    statusText(for: booking.status),
                                    status: badgeStatus(for: booking.status),
                                    size: .small
                                )
                            }
                            
                            if !booking.notes.isEmpty {
                                Text(booking.notes)
                                    .font(.caption)
                                    .foregroundColor(.piumsTextSecondary)
                                    .lineLimit(2)
                            }
                            
                            HStack(spacing: 12) {
                                Label("\(booking.clientEmail)", systemImage: "envelope")
                                    .font(.caption)
                                    .foregroundColor(.piumsTextTertiary)
                                
                                if !booking.clientPhone.isEmpty {
                                    Label("\(booking.clientPhone)", systemImage: "phone")
                                        .font(.caption)
                                        .foregroundColor(.piumsTextTertiary)
                                }
                            }
                        }
                    }
                    
                    // Actions row
                    if booking.status == .pending {
                        HStack(spacing: 8) {
                            PiumsButton(
                                "Rechazar",
                                icon: "xmark",
                                style: .outline,
                                size: .small,
                                action: onReject
                            )
                            
                            PiumsButton(
                                "Aceptar",
                                icon: "checkmark",
                                style: .success,
                                size: .small,
                                action: onAccept
                            )
                        }
                    } else if booking.status == .confirmed {
                        HStack {
                            Text("💰 $\(Int(booking.totalPrice))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.piumsSuccess)
                            
                            Spacer()
                            
                            PiumsButton(
                                "Completar",
                                icon: "checkmark.circle",
                                style: .success,
                                size: .small,
                                action: onComplete
                            )
                        }
                    } else if booking.status == .completed {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.piumsSuccess)
                            
                            Text("Servicio completado - $\(Int(booking.totalPrice))")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.piumsSuccess)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private func statusText(for status: BookingStatus) -> String {
        switch status {
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmada"
        case .inProgress: return "En Progreso"
        case .completed: return "Completada"
        case .cancelled: return "Cancelada"
        case .noShow: return "No Asistió"
        }
    }
    
    private func badgeStatus(for status: BookingStatus) -> PiumsStatusBadge.BadgeStatus {
        switch status {
        case .pending: return .warning
        case .confirmed: return .success
        case .inProgress: return .info
        case .completed: return .success
        case .cancelled: return .error
        case .noShow: return .error
        }
    }
}

// MARK: - Booking Detail Sheet
struct BookingDetailSheet: View {
    @Binding var booking: Booking
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header info
                    PiumsCard(style: .highlighted) {
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(booking.clientName)
                                        .font(.title2.weight(.bold))
                                        .foregroundColor(.piumsTextPrimary)
                                    
                                    Text("Cliente desde hace 2 meses")
                                        .font(.subheadline)
                                        .foregroundColor(.piumsTextSecondary)
                                }
                                
                                Spacer()
                                
                                AsyncImage(url: URL(string: "https://i.pravatar.cc/150?img=2")) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.piumsPrimary)
                                        .font(.title2)
                                }
                                .frame(width: 60, height: 60)
                                .background(Color.piumsPrimary.opacity(0.1))
                                .clipShape(Circle())
                            }
                            
                            Divider()
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Fecha y Hora")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.piumsTextSecondary)
                                    
                                    Text("\(booking.scheduledDate, formatter: detailDateFormatter)")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.piumsTextPrimary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Duración")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(.piumsTextSecondary)
                                    
                                    Text("\(booking.duration) minutos")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.piumsTextPrimary)
                                }
                            }
                        }
                    }
                    
                    // Service details
                    PiumsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Detalles del Servicio")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.piumsTextPrimary)
                            
                            VStack(spacing: 12) {
                                DetailRow(label: "Servicio", value: "Corte y Peinado Premium")
                                DetailRow(label: "Precio", value: "$\(Int(booking.totalPrice))")
                                
                                if !booking.notes.isEmpty {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Notas")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(.piumsTextSecondary)
                                        
                                        Text(booking.notes)
                                            .font(.body)
                                            .foregroundColor(.piumsTextPrimary)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Contact info
                    PiumsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Información de Contacto")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.piumsTextPrimary)
                            
                            VStack(spacing: 12) {
                                ContactRow(icon: "envelope.fill", label: "Email", value: booking.clientEmail)
                                
                                if !booking.clientPhone.isEmpty {
                                    ContactRow(icon: "phone.fill", label: "Teléfono", value: booking.clientPhone)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationTitle("Detalle de Reserva")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(.piumsPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Llamar Cliente", systemImage: "phone") {
                            // Call action
                        }
                        
                        Button("Enviar Mensaje", systemImage: "message") {
                            // Message action  
                        }
                        
                        Button("Cancelar Reserva", systemImage: "xmark.circle") {
                            // Cancel action
                        }
                        .foregroundColor(.piumsError)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.piumsPrimary)
                    }
                }
            }
        }
    }
    
    private var detailDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter
    }
}

// MARK: - Create Booking Sheet
struct CreateBookingSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            PiumsEmptyState(
                icon: "calendar.badge.plus",
                title: "Crear Nueva Reserva",
                message: "Esta funcionalidad se implementará próximamente",
                primaryAction: PiumsEmptyState.ActionConfig("Cerrar") {
                    dismiss()
                }
            )
            .navigationTitle("Nueva Reserva")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(.piumsPrimary)
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.piumsTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.piumsTextPrimary)
        }
    }
}

struct ContactRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(.piumsPrimary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.piumsTextSecondary)
                
                Text(value)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.piumsTextPrimary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.piumsPrimary)
            }
        }
    }
}

#Preview {
    BookingsView()
}
