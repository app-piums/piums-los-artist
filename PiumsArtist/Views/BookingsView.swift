//
//  BookingsView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI

struct BookingsView: View {
    @State private var selectedFilter: BookingFilter = .all
    @State private var showingFilters = false
    
    enum BookingFilter: String, CaseIterable {
        case all = "Todas"
        case pending = "Pendientes"
        case confirmed = "Confirmadas"
        case completed = "Completadas"
        case cancelled = "Canceladas"
    }
    
    // Mock data - será reemplazado por datos reales
    let mockBookings = [
        BookingItem(id: 1, clientName: "María García", service: "Corte y Peinado", date: Date(), time: "10:00 AM", status: .confirmed, price: 45.0),
        BookingItem(id: 2, clientName: "Ana López", service: "Coloración", date: Date(), time: "2:00 PM", status: .pending, price: 80.0),
        BookingItem(id: 3, clientName: "Carlos Ruiz", service: "Barba", date: Date(), time: "4:30 PM", status: .confirmed, price: 25.0),
        BookingItem(id: 4, clientName: "Laura Martín", service: "Peinado Evento", date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, time: "6:00 PM", status: .completed, price: 65.0),
    ]
    
    var filteredBookings: [BookingItem] {
        switch selectedFilter {
        case .all:
            return mockBookings
        case .pending:
            return mockBookings.filter { $0.status == .pending }
        case .confirmed:
            return mockBookings.filter { $0.status == .confirmed }
        case .completed:
            return mockBookings.filter { $0.status == .completed }
        case .cancelled:
            return mockBookings.filter { $0.status == .cancelled }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Filtros
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(BookingFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Lista de reservas
                if filteredBookings.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No hay reservas")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text("Las nuevas reservas aparecerán aquí")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredBookings) { booking in
                            BookingCard(booking: booking)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Reservas")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Acción para crear nueva reserva
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct BookingItem: Identifiable {
    let id: Int
    let clientName: String
    let service: String
    let date: Date
    let time: String
    let status: BookingStatus
    let price: Double
    
    enum BookingStatus {
        case pending, confirmed, completed, cancelled
        
        var color: Color {
            switch self {
            case .pending: return .orange
            case .confirmed: return .blue
            case .completed: return .green
            case .cancelled: return .red
            }
        }
        
        var text: String {
            switch self {
            case .pending: return "Pendiente"
            case .confirmed: return "Confirmada"
            case .completed: return "Completada"
            case .cancelled: return "Cancelada"
            }
        }
        
        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .confirmed: return "checkmark.circle.fill"
            case .completed: return "checkmark.seal.fill"
            case .cancelled: return "xmark.circle.fill"
            }
        }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct BookingCard: View {
    let booking: BookingItem
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.clientName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(booking.service)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.secondary)
                        Text(booking.date, style: .date)
                            .font(.caption)
                        
                        Image(systemName: "clock")
                            .foregroundColor(.secondary)
                        Text(booking.time)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Image(systemName: booking.status.icon)
                        Text(booking.status.text)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(booking.status.color.opacity(0.2))
                    .foregroundColor(booking.status.color)
                    .cornerRadius(8)
                    
                    Text("$\(booking.price, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
            }
            
            // Botones de acción según el estado
            if booking.status == .pending {
                HStack(spacing: 12) {
                    Button("Rechazar") {
                        // Acción rechazar
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .foregroundColor(.red)
                    .cornerRadius(8)
                    
                    Button("Aceptar") {
                        // Acción aceptar
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else if booking.status == .confirmed {
                HStack(spacing: 12) {
                    Button("Contactar") {
                        // Acción contactar
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                    
                    Button("Completar") {
                        // Acción completar
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    BookingsView()
}