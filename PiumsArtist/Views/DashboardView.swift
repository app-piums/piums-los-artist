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
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .refreshable { await viewModel.refreshData() }
        .onAppear {
            viewModel.setModelContext(modelContext)
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.15)) {
                animateStats = true
            }
        }
        .sheet(isPresented: $showingNotifications) { NotificationsSheet() }
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

            // PIUMS wordmark
            Text("PIUMS")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.piumsOrange, .piumsAccent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Spacer()

            // Settings
            HStack(spacing: 10) {
                Button { showingNotifications = true } label: {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "gearshape.fill")
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
        .background(Color(.systemBackground))
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .scaleEffect(animateStats ? 1 : 0.95)
        .opacity(animateStats ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(delay), value: animateStats)
    }

    // MARK: - Profile Strength Card
    private var profileStrengthCard: some View {
        let percentage = 40
        let items: [(String, Bool)] = [
            ("Foto de perfil agregada", false),
            ("Descripción de perfil", true),
            ("Servicios publicados", false),
            ("Redes sociales vinculadas", false),
            ("Primera reseña obtenida", true)
        ]

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
                Button("VER TODO") {}
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
                    Button {
                        // Promote profile action
                    } label: {
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
                .background(Color(.systemBackground))
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
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }
}

// MARK: - Notifications Sheet
struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            PiumsEmptyState(
                icon: "bell.slash",
                title: "Sin notificaciones",
                message: "No tienes notificaciones pendientes en este momento",
                primaryAction: PiumsEmptyState.ActionConfig("Cerrar") { dismiss() }
            )
            .navigationTitle("Notificaciones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }.foregroundColor(.piumsOrange)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
