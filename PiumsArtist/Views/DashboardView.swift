//
//  DashboardView.swift
//  PiumsArtist
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showingNotifications = false
    @State private var showProfile = false
    @State private var showAllBookings = false
    @State private var animateStats = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d 'de' MMMM"
        f.locale = Locale(identifier: "es_ES")
        return f
    }()

    static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    // Greeting based on hour
    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Buenos días," }
        if h < 19 { return "Buenas tardes," }
        return "Buenas noches,"
    }

    var body: some View {
        ZStack {
            Color(.secondarySystemGroupedBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // ── Header ──
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    VStack(spacing: 24) {
                        // ── Greeting + date ──
                        greetingSection
                            .padding(.horizontal, 20)

                        // ── Earnings card ──
                        earningsCard
                            .padding(.horizontal, 20)

                        // ── Pendientes + Visitas ──
                        secondaryMetricsRow
                            .padding(.horizontal, 20)

                        // ── Fortaleza del Perfil ──
                        profileStrengthCard
                            .padding(.horizontal, 20)

                        // ── Resumen de Ingresos / Próximas presentaciones ──
                        upcomingSection
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 110)
                }
            }
            .refreshable { await viewModel.refreshData() }
            .onAppear {
                viewModel.setModelContext(modelContext)
                withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.15)) {
                    animateStats = true
                }
            }
            .sheet(isPresented: $showingNotifications) { NotificationsSheet() }
            .sheet(isPresented: $showProfile) { ProfileView() }
            .sheet(isPresented: $showAllBookings) { NavigationView { BookingsView() }.presentationDetents([.large]) }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 0) {
            // Avatar
            PiumsAvatarView(
                name: "Artista",
                imageURL: nil,
                size: 42,
                gradientColors: [.piumsOrange, .piumsAccent]
            )

            Spacer()

            // PIUMS logo
            Image("PiumsLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 52)

            Spacer()

            // Settings
            HStack(spacing: 10) {
                Button { showingNotifications = true } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .font(.callout.weight(.medium))
                            .foregroundColor(.piumsTextSecondary)
                            .frame(width: 38, height: 38)
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)

                        if viewModel.pendingCount > 0 {
                            Circle().fill(Color.piumsError)
                                .frame(width: 9, height: 9)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Greeting
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .font(.title2.weight(.regular))
                .foregroundColor(.piumsTextSecondary)

            Text("Tu resumen")
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(.piumsTextPrimary)

            Text(Date(), formatter: Self.dateFormatter)
                .font(.subheadline)
                .foregroundColor(.piumsTextSecondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Earnings Card (main metric)
    private var earningsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INGRESOS TOTALES")
                .font(.caption.weight(.semibold))
                .foregroundColor(.piumsTextSecondary)
                .tracking(0.6)

            Text(viewModel.totalEarnings > 0 ? viewModel.formattedTotalEarnings : "Q0")
                .font(.system(size: 38, weight: .bold))
                .foregroundColor(.piumsOrange)

            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right")
                    .font(.caption2.weight(.bold))
                Text("Este mes: \(viewModel.formattedMonthlyEarnings)")
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(.piumsSuccess)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.piumsSuccess.opacity(0.12))
            .clipShape(Capsule())
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
        .scaleEffect(animateStats ? 1 : 0.95)
        .opacity(animateStats ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: animateStats)
    }

    // MARK: - Secondary Metrics (Pendientes + Confirmadas)
    private var secondaryMetricsRow: some View {
        HStack(spacing: 12) {
            metricCard(
                label: "PENDIENTES",
                value: "\(viewModel.pendingCount)",
                icon: "clock.fill",
                iconColor: .piumsWarning,
                delay: 0.2
            )
            metricCard(
                label: "CONFIRMADAS",
                value: "\(viewModel.confirmedCount)",
                icon: "checkmark.circle.fill",
                iconColor: .piumsSuccess,
                delay: 0.3
            )
        }
    }

    private func metricCard(label: String, value: String, icon: String, iconColor: Color, delay: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.piumsTextSecondary)
                    .tracking(0.4)
                Spacer()
            }

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(.piumsTextPrimary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .scaleEffect(animateStats ? 1 : 0.95)
        .opacity(animateStats ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateStats)
    }

    // MARK: - Profile Strength Card
    private var profileStrengthCard: some View {
        let artist = AuthService.shared.currentArtist
        let hasBio = !(artist?.bio ?? "").isEmpty
        let hasPhone = !(artist?.phone ?? "").isEmpty
        let hasServices = viewModel.totalBookings > 0
        let hasReviews = (artist?.totalReviews ?? 0) > 0 || (artist?.rating ?? 0) > 0
        let items: [(String, Bool)] = [
            ("Foto de perfil agregada", false),
            ("Descripción de perfil", hasBio),
            ("Servicios publicados", hasServices),
            ("Datos de contacto", hasPhone),
            ("Primera reseña obtenida", hasReviews)
        ]
        let percentage = items.filter { $0.1 }.count * 20

        return VStack(alignment: .leading, spacing: 16) {
            // Title row
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Fortaleza del Perfil")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                    Text("Completa tu presencia digital")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                Spacer()
                Text("\(percentage)%")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.piumsOrange)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.piumsOrange, .piumsAccent],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: animateStats ? geo.size.width * CGFloat(percentage) / 100 : 0, height: 8)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.4), value: animateStats)
                }
            }
            .frame(height: 8)

            // Checklist
            VStack(spacing: 10) {
                ForEach(items, id: \.0) { item in
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(item.1 ? Color.piumsSuccess : Color.white.opacity(0.12))
                                .frame(width: 22, height: 22)
                            if item.1 {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                        Text(item.0)
                            .font(.subheadline)
                            .foregroundColor(item.1 ? .white : .white.opacity(0.55))
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.14))
        )
        .scaleEffect(animateStats ? 1 : 0.95)
        .opacity(animateStats ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.35), value: animateStats)
    }

    // MARK: - Upcoming / Empty State
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Resumen de Ingresos")
                    .font(.headline.weight(.bold))
                    .foregroundColor(.piumsTextPrimary)
                Spacer()
                Button("VER TODO") { showAllBookings = true }
                    .font(.caption.weight(.bold))
                    .foregroundColor(.piumsOrange)
            }

            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else if viewModel.todayBookings.isEmpty {
                VStack(spacing: 16) {
                    // Empty state
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 64, height: 64)
                            Image(systemName: "calendar.badge.minus")
                                .font(.title2)
                                .foregroundColor(.piumsTextSecondary)
                        }

                        Text("Sin próximas presentaciones")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.piumsTextPrimary)

                        Text("Tus próximas reservas aparecerán aquí\nuna vez que los clientes confirmen.")
                            .font(.caption)
                            .foregroundColor(.piumsTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)

                    // CTA button
                    Button { showProfile = true } label: {
                        Text("Promocionar Perfil")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.piumsOrange)
                            .clipShape(Capsule())
                    }
                }
                .padding(20)
                .background(Color(.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 3)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.todayBookings.prefix(3), id: \.id) { booking in
                        BookingRowCard(booking: booking)
                    }
                }
            }
        }
    }
}

// MARK: - Booking Row Card
struct BookingRowCard: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 14) {
            // Time
            VStack(spacing: 2) {
                Text(booking.scheduledDate, formatter: DashboardView.timeFormatter)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.piumsOrange)
                Text("\(booking.duration)m")
                    .font(.caption2)
                    .foregroundColor(.piumsTextTertiary)
            }
            .frame(width: 54)

            VStack(alignment: .leading, spacing: 4) {
                Text(booking.clientName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.piumsTextPrimary)
                Text("Q\(Int(booking.totalPrice))")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.piumsSuccess)
            }

            Spacer()

            PiumsStatusBadge(
                booking.status == .confirmed ? "Confirmada" :
                    booking.status == .pending ? "Pendiente" : "Completada",
                status: booking.status == .confirmed ? .success :
                    booking.status == .pending ? .warning : .info,
                size: .small
            )
        }
        .padding(16)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}

// MARK: - Notifications Sheet
struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = NotificationsViewModel()

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if vm.notifications.isEmpty {
                    PiumsEmptyState(
                        icon: "bell.slash",
                        title: "Sin notificaciones",
                        message: "No tienes notificaciones pendientes en este momento",
                        primaryAction: PiumsEmptyState.ActionConfig("Cerrar") { dismiss() }
                    )
                } else {
                    List {
                        ForEach(vm.notifications) { notif in
                            NotificationRow(notification: notif)
                                .listRowBackground(Color(.tertiarySystemGroupedBackground))
                                .onTapGesture { Task { await vm.markRead(notif.id) } }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
                }
            }
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(.secondarySystemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }.foregroundColor(.piumsOrange)
                }
                if !vm.notifications.filter({ !$0.isRead }).isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Leer todo") { Task { await vm.markAllRead() } }
                            .font(.subheadline)
                            .foregroundColor(.piumsOrange)
                    }
                }
            }
            .task { await vm.load() }
        }
    }
}

// MARK: - Notification Row
private struct NotificationRow: View {
    let notification: NotificationsViewModel.NotificationItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(notification.iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: notification.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(notification.iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline.weight(notification.isRead ? .regular : .semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    if !notification.isRead {
                        Circle().fill(Color.piumsOrange).frame(width: 8, height: 8)
                    }
                }
                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                Text(notification.relativeTime)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(.vertical, 6)
        .opacity(notification.isRead ? 0.65 : 1)
    }
}

// MARK: - Notifications ViewModel
@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var isLoading = false

    struct NotificationItem: Identifiable {
        let id: String
        let title: String
        let message: String
        var isRead: Bool
        let type: String
        let createdAt: Date

        var iconName: String {
            switch type {
            case "BOOKING_CONFIRMED":  return "calendar.badge.checkmark"
            case "BOOKING_CANCELLED":  return "calendar.badge.minus"
            case "PAYMENT_RECEIVED":   return "dollarsign.circle.fill"
            case "REVIEW_RECEIVED":    return "star.fill"
            case "MESSAGE_RECEIVED":   return "bubble.left.fill"
            default:                   return "bell.fill"
            }
        }

        var iconColor: Color {
            switch type {
            case "BOOKING_CONFIRMED":  return .piumsSuccess
            case "BOOKING_CANCELLED":  return .piumsError
            case "PAYMENT_RECEIVED":   return .piumsOrange
            case "REVIEW_RECEIVED":    return .yellow
            case "MESSAGE_RECEIVED":   return .piumsInfo
            default:                   return .secondary
            }
        }

        var relativeTime: String {
            let diff = Date().timeIntervalSince(createdAt)
            if diff < 60 { return "Ahora" }
            if diff < 3600 { return "Hace \(Int(diff/60)) min" }
            if diff < 86400 { return "Hace \(Int(diff/3600)) h" }
            return "Hace \(Int(diff/86400)) días"
        }
    }

    func load() async {
        isLoading = true
        do {
            let dtos = try await APIService.shared.get(
                endpoint: .notifications(unread: nil, page: 1),
                responseType: [NotificationDTO].self
            )
            notifications = dtos.map { dto in
                let iso = ISO8601DateFormatter()
                iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                let iso2 = ISO8601DateFormatter()
                let date = iso.date(from: dto.createdAt) ?? iso2.date(from: dto.createdAt) ?? Date()
                return NotificationItem(id: dto.id, title: dto.title, message: dto.message,
                                        isRead: dto.read, type: dto.type, createdAt: date)
            }
        } catch { }
        isLoading = false
    }

    func markRead(_ id: String) async {
        guard let idx = notifications.firstIndex(where: { $0.id == id }),
              !notifications[idx].isRead else { return }
        notifications[idx].isRead = true
        try? await APIService.shared.request(
            endpoint: .markNotificationRead(id),
            method: .PATCH,
            responseType: EmptyResponseDTO.self
        )
    }

    func markAllRead() async {
        notifications.indices.forEach { notifications[$0].isRead = true }
        try? await APIService.shared.request(
            endpoint: .markAllNotificationsRead,
            method: .PATCH,
            responseType: EmptyResponseDTO.self
        )
    }
}

#Preview {
    DashboardView()
}
