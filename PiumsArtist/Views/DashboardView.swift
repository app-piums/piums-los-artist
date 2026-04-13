//
//  DashboardView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Saludo personalizado
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("¡Hola, Artista!")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Aquí tienes un resumen de tu día")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            // Avatar placeholder
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.blue)
                                )
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Métricas del día
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        MetricCard(
                            title: "Reservas Hoy",
                            value: "3",
                            icon: "calendar.badge.clock",
                            color: .blue
                        )
                        
                        MetricCard(
                            title: "Pendientes",
                            value: "2",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        MetricCard(
                            title: "Completadas",
                            value: "8",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        MetricCard(
                            title: "Ingresos Mes",
                            value: "$2,450",
                            icon: "dollarsign.circle.fill",
                            color: .purple
                        )
                    }
                    
                    // Próximas reservas
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Próximas Reservas")
                                .font(.headline)
                            Spacer()
                            Button("Ver todas") {
                                // Navegar a BookingsView
                            }
                            .font(.caption)
                        }
                        
                        VStack(spacing: 8) {
                            BookingRowView(
                                clientName: "María García",
                                service: "Corte y Peinado",
                                time: "10:00 AM",
                                status: .confirmed
                            )
                            
                            BookingRowView(
                                clientName: "Ana López",
                                service: "Coloración",
                                time: "2:00 PM",
                                status: .pending
                            )
                            
                            BookingRowView(
                                clientName: "Carlos Ruiz",
                                service: "Barba",
                                time: "4:30 PM",
                                status: .confirmed
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(radius: 1)
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
}

struct BookingRowView: View {
    let clientName: String
    let service: String
    let time: String
    let status: BookingStatus
    
    enum BookingStatus {
        case confirmed, pending, completed
        
        var color: Color {
            switch self {
            case .confirmed: return .blue
            case .pending: return .orange
            case .completed: return .green
            }
        }
        
        var text: String {
            switch self {
            case .confirmed: return "Confirmada"
            case .pending: return "Pendiente"
            case .completed: return "Completada"
            }
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(clientName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(service)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(time)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(status.text)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(status.color.opacity(0.2))
                    .foregroundColor(status.color)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    DashboardView()
}