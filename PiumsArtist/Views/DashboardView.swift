//
//  DashboardView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showingNotifications = false
    @State private var showingBackendTest = false
    @State private var animateStats = false
    
    // MARK: - Constants
    private enum Constants {
        static let bottomPadding: CGFloat = 100
        static let emptyStateHeight: CGFloat = 200
        static let cardHeight: CGFloat = 120
        static let horizontalPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let headerSize: CGFloat = 44
    }
    
    // MARK: - Formatters (Static for performance)
    static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d 'de' MMMM"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Custom Navigation Header
                    headerView
                        .padding(.horizontal, Constants.horizontalPadding)
                        .padding(.bottom, Constants.sectionSpacing)
                    
                    VStack(spacing: Constants.sectionSpacing) {
                        // Welcome Section
                        welcomeSection
                        
                        // Quick Stats Grid
                        statsGrid
                        
                        // Today's Schedule
                        todayScheduleSection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Promo Banner (inspirado en cliente)
                        promoBannerSection
                        
                        // Recent Activity
                        recentActivitySection
                    }
                    .padding(.horizontal, Constants.horizontalPadding)
                    .padding(.bottom, Constants.bottomPadding) // Tab bar padding
                }
            }
            .refreshable {
                await viewModel.refreshData()
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            withAnimation(.easeInOut(duration: 0.6).delay(0.2)) {
                animateStats = true
            }
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsSheet()
        }
        .sheet(isPresented: $showingBackendTest) {
            BackendTestView()
                .presentationDetents([.large])
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Dashboard")
                    .font(.largeTitle.weight(.bold))
                    .foregroundColor(.piumsTextPrimary)
                
                Text("Bienvenido de vuelta")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.piumsTextSecondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Backend Test Button (only in DEBUG)
                #if DEBUG
                Button(action: { showingBackendTest = true }) {
                    Image(systemName: "link")
                        .font(.title3.weight(.medium))
                        .foregroundColor(.piumsSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color.piumsSecondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(PiumsButtonStyle())
                #endif
                
                Button(action: { showingNotifications = true }) {
                    ZStack {
                        Image(systemName: "bell.fill")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.piumsPrimary)
                            .frame(width: 44, height: 44)
                            .background(Color.piumsPrimary.opacity(0.1))
                            .clipShape(Circle())
                        
                        // Notification badge
                        if viewModel.pendingBookingsCount > 0 {
                            Circle()
                                .fill(Color.piumsError)
                                .frame(width: 12, height: 12)
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .buttonStyle(PiumsButtonStyle())
                
                Button {
                    // Navigate to profile
                } label: {
                    PiumsAvatarView(
                        name: "Artista", // TODO: Implementar viewModel.artistName
                        imageURL: nil, // TODO: Implementar viewModel.artistAvatarURL
                        size: Constants.headerSize,
                        gradientColors: [.piumsOrange, .piumsAccent]
                    )
                }
                .buttonStyle(PiumsButtonStyle())
                .accessibilityLabel("Perfil del artista")
                .accessibilityHint("Toca para ver y editar tu perfil")
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - Welcome Section
    private var welcomeSection: some View {
        PiumsCard(style: .highlighted) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("¡Hola, Artista! 👋")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.piumsTextPrimary)
                        
                        Text("Tienes \(viewModel.todayBookingsCount) reservas programadas para hoy")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.piumsTextSecondary)
                            .multilineTextAlignment(.leading)
                        
                        // Availability status
                        HStack(spacing: 12) {
                            PiumsAvailabilityBadge(isAvailable: true, size: .small)
                            
                            Text("•")
                                .foregroundColor(.piumsTextTertiary)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.piumsWarning)
                                Text("4.9")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.piumsTextSecondary)
                                Text("(124 reseñas)")
                                    .font(.caption2)
                                    .foregroundColor(.piumsTextTertiary)
                            }
                        }
                        
                        // Backend status indicator (DEBUG only)
                        #if DEBUG
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.piumsSuccess)
                                .frame(width: 8, height: 8)
                            
                            Text("Backend conectado")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(.piumsSuccess)
                            
                            Button("Test") {
                                showingBackendTest = true
                            }
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.piumsSecondary)
                        }
                        #endif
                        
                        if !viewModel.isLoading && viewModel.todayBookingsCount > 0 {
                            HStack(spacing: 8) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                    .foregroundColor(.piumsInfo)
                                
                                if let nextBooking = viewModel.todayBookings.first {
                                    Text("Próxima: \(nextBooking.scheduledDate, formatter: Self.timeFormatter)")
                                        .font(.caption.weight(.medium))
                                        .foregroundColor(.piumsInfo)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.piumsInfo.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.piumsPrimary.opacity(0.7))
                        
                        if viewModel.todayBookingsCount > 0 {
                            Text("\(viewModel.todayBookingsCount)")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.piumsPrimary)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            PiumsStatsCard(
                title: "Reservas Hoy",
                value: "\(viewModel.todayBookingsCount)",
                subtitle: viewModel.pendingBookingsCount > 0 ? "\(viewModel.pendingBookingsCount) pendientes" : "Todo confirmado",
                icon: "calendar.day.timeline.leading",
                trend: viewModel.todayBookingsCount > 0 ? .up : .neutral,
                trendValue: viewModel.todayBookingsCount > 0 ? "+\(viewModel.todayBookingsCount)" : nil,
                color: .piumsPrimary
            )
            .scaleEffect(animateStats ? 1.0 : 0.8)
            .opacity(animateStats ? 1.0 : 0.5)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateStats)
            
            PiumsStatsCard(
                title: "Ingresos del Mes",
                value: viewModel.formattedEarnings,
                subtitle: "Meta: $3,000",
                icon: "dollarsign.circle.fill",
                trend: .up,
                trendValue: "+12%",
                color: .piumsSuccess
            )
            .scaleEffect(animateStats ? 1.0 : 0.8)
            .opacity(animateStats ? 1.0 : 0.5)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: animateStats)
            
            PiumsStatsCard(
                title: "Completadas",
                value: "\(viewModel.completedBookingsCount)",
                subtitle: "Este mes",
                icon: "checkmark.seal.fill",
                trend: .up,
                trendValue: "+18%",
                color: .piumsInfo
            )
            .scaleEffect(animateStats ? 1.0 : 0.8)
            .opacity(animateStats ? 1.0 : 0.5)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: animateStats)
            
            PiumsStatsCard(
                title: "Valoración",
                value: "4.9",
                subtitle: "⭐⭐⭐⭐⭐",
                icon: "star.fill",
                trend: .up,
                trendValue: "+0.2",
                color: .piumsWarning
            )
            .scaleEffect(animateStats ? 1.0 : 0.8)
            .opacity(animateStats ? 1.0 : 0.5)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateStats)
        }
    }
    
    // MARK: - Today's Schedule
    private var todayScheduleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Agenda de Hoy")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.piumsTextPrimary)
                    
                    Text("\(Date(), formatter: Self.dateFormatter)")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.piumsTextSecondary)
                }
                
                Spacer()
                
                NavigationLink(destination: CalendarView()) {
                    HStack(spacing: 6) {
                        Text("Ver calendario")
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.caption.weight(.bold))
                    }
                    .foregroundColor(.piumsPrimary)
                }
            }
            
            if viewModel.isLoading {
                PiumsLoadingView("Cargando agenda...", style: .card)
                    .frame(height: Constants.cardHeight)
            } else if viewModel.todayBookings.isEmpty {
                PiumsEmptyState(
                    icon: "calendar.badge.plus",
                    title: "No hay reservas hoy",
                    message: "¡Perfecto momento para relajarse o promocionar tus servicios!",
                    primaryAction: PiumsEmptyState.ActionConfig("Añadir Disponibilidad", icon: "plus.circle.fill") {
                        // Action to add availability
                    }
                )
                .frame(height: Constants.emptyStateHeight)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.todayBookings.prefix(3), id: \.id) { booking in
                        ModernBookingCard(booking: booking)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Acciones Rápidas")
                .font(.title2.weight(.bold))
                .foregroundColor(.piumsTextPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                QuickActionButton(
                    title: "Gestionar Reservas",
                    icon: "calendar.badge.clock",
                    color: .piumsPrimary
                ) {
                    // Navigate to bookings
                }
                
                QuickActionButton(
                    title: "Mis Servicios",
                    icon: "list.bullet.rectangle.portrait.fill",
                    color: .piumsSecondary
                ) {
                    // Navigate to services
                }
                
                QuickActionButton(
                    title: "Mensajes",
                    icon: "message.fill",
                    color: .piumsInfo,
                    badge: 3
                ) {
                    // Navigate to messages
                }
                
                QuickActionButton(
                    title: "Mi Perfil",
                    icon: "person.circle.fill",
                    color: .piumsSuccess
                ) {
                    // Navigate to profile
                }
            }
        }
    }
    
    // MARK: - Promo Banner Section
    private var promoBannerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            PiumsCard(style: .elevated, padding: 0) {
                ZStack {
                    LinearGradient(
                        colors: [.piumsOrange, .piumsAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("¡Aumenta tus ventas!")
                                .font(.headline.weight(.bold))
                                .foregroundColor(.white)
                            
                            Text("Activa tu perfil premium y aparece en los primeros resultados")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                            
                            Button(action: {}) {
                                Text("Activar Premium")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.piumsOrange)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text("PREMIUM")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actividad Reciente")
                .font(.title2.weight(.bold))
                .foregroundColor(.piumsTextPrimary)
            
            PiumsCard {
                VStack(spacing: 12) {
                    ActivityItem(
                        icon: "checkmark.circle.fill",
                        iconColor: .piumsSuccess,
                        title: "Reserva completada",
                        subtitle: "María García - Corte y peinado",
                        time: "Hace 2 horas"
                    )
                    
                    Divider()
                    
                    ActivityItem(
                        icon: "message.fill",
                        iconColor: .piumsInfo,
                        title: "Nuevo mensaje",
                        subtitle: "Ana López pregunta sobre disponibilidad",
                        time: "Hace 3 horas"
                    )
                    
                    Divider()
                    
                    ActivityItem(
                        icon: "star.fill",
                        iconColor: .piumsWarning,
                        title: "Nueva reseña",
                        subtitle: "5 estrellas de Carlos Ruiz",
                        time: "Hace 5 horas"
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views
struct ModernBookingCard: View {
    let booking: Booking
    
    var body: some View {
        PiumsCard(style: .bordered, padding: 16) {
            HStack(spacing: 16) {
                // Time indicator
                VStack(spacing: 4) {
                    Text(booking.scheduledDate, formatter: DashboardView.timeFormatter)
                        .font(.headline.weight(.bold))
                        .foregroundColor(.piumsPrimary)
                    
                    Text("\(booking.duration)min")
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.piumsTextTertiary)
                }
                .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(booking.clientName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.piumsTextPrimary)
                    
                    Text("Servicio premium")
                        .font(.caption)
                        .foregroundColor(.piumsTextSecondary)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.piumsSuccess)
                        
                        Text("$\(Int(booking.totalPrice))")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.piumsSuccess)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    PiumsStatusBadge(
                        booking.status == .confirmed ? "Confirmada" : 
                        booking.status == .pending ? "Pendiente" : "Completada",
                        status: booking.status == .confirmed ? .success : 
                               booking.status == .pending ? .warning : .info,
                        size: .small
                    )
                    
                    if booking.status == .pending {
                        Button(action: {}) {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Color.piumsSuccess)
                                .clipShape(Circle())
                        }
                        .buttonStyle(PiumsButtonStyle())
                    }
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let badge: Int?
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, badge: Int? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.badge = badge
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            PiumsCard(style: .bordered, padding: 16) {
                VStack(spacing: 12) {
                    ZStack {
                        Image(systemName: icon)
                            .font(.title2.weight(.medium))
                            .foregroundColor(color)
                            .frame(width: 44, height: 44)
                            .background(color.opacity(0.1))
                            .clipShape(Circle())
                        
                        if let badge = badge, badge > 0 {
                            Text("\(badge)")
                                .font(.caption2.weight(.bold))
                                .foregroundColor(.white)
                                .frame(width: 18, height: 18)
                                .background(Color.piumsError)
                                .clipShape(Circle())
                                .offset(x: 16, y: -16)
                        }
                    }
                    
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.piumsTextPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .buttonStyle(PiumsButtonStyle())
    }
}

struct ActivityItem: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3.weight(.medium))
                .foregroundColor(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.piumsTextPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.piumsTextSecondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption2.weight(.medium))
                .foregroundColor(.piumsTextTertiary)
        }
    }
}

struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            PiumsEmptyState(
                icon: "bell.slash",
                title: "Sin notificaciones",
                message: "No tienes notificaciones pendientes en este momento",
                primaryAction: PiumsEmptyState.ActionConfig("Cerrar") {
                    dismiss()
                }
            )
            .navigationTitle("Notificaciones")
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

#Preview {
    DashboardView()
}
