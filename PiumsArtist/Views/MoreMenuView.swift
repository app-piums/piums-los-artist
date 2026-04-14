//
//  MoreMenuView.swift
//  PiumsArtist
//
//  Equivalente al sidebar completo de la web.
//  Agrupa: Servicios, Ausencias/Viajes, Tutorial,
//  Billetera, Facturas, Quejas, Configuración, Perfil, Cerrar Sesión.
//

import SwiftUI

struct MoreMenuView: View {
    @State private var showProfile = false
    @State private var showServices = false
    @State private var showSettings = false
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // ── Profile card ──
                    profileCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // ── MAIN ──
                    sectionHeader("MAIN")
                    menuGroup {
                        menuRow(icon: "bag.fill", title: "Servicios", color: .piumsOrange, badge: nil) { showServices = true }
                        menuDivider()
                        menuRow(icon: "airplane", title: "Ausencias / Viajes", color: .purple) {}
                        menuDivider()
                        menuRow(icon: "sparkles", title: "Tutorial", color: .piumsAccent) {}
                    }

                    // ── FINANCE ──
                    sectionHeader("FINANCE")
                    menuGroup {
                        menuRow(icon: "wallet.pass.fill", title: "Billetera", color: .piumsSuccess) {}
                        menuDivider()
                        menuRow(icon: "doc.text.fill", title: "Facturas", color: .secondary) {}
                    }

                    // ── CUENTA ──
                    sectionHeader("CUENTA")
                    menuGroup {
                        menuRow(icon: "exclamationmark.triangle.fill", title: "Quejas", color: .piumsWarning) {}
                        menuDivider()
                        menuRow(icon: "gearshape.fill", title: "Configuración", color: .secondary) { showSettings = true }
                        menuDivider()
                        menuRow(icon: "rectangle.portrait.and.arrow.right", title: "Cerrar Sesión", color: .piumsError) { showLogoutAlert = true }
                    }

                    Spacer(minLength: 120)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Más")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showProfile) { ProfileView() }
            .sheet(isPresented: $showServices) { NavigationView { ServicesView() }.presentationDetents([.large]) }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .alert("¿Cerrar sesión?", isPresented: $showLogoutAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Cerrar sesión", role: .destructive) {
                    AuthService.shared.logout()
                }
            } message: {
                Text("Se cerrará tu sesión actual y tendrás que iniciar sesión de nuevo.")
            }
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        Button { showProfile = true } label: {
            HStack(spacing: 14) {
                PiumsAvatarView(
                    name: AuthService.shared.currentArtist?.name ?? "A",
                    imageURL: nil,
                    size: 50,
                    gradientColors: [.piumsOrange, .piumsAccent]
                )

                VStack(alignment: .leading, spacing: 3) {
                    Text(AuthService.shared.currentArtist?.name ?? "Artista")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Artista Pro")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Section Header
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    // MARK: - Menu Group
    private func menuGroup<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        .padding(.horizontal, 16)
    }

    // MARK: - Menu Row
    private func menuRow(icon: String, title: String, color: Color, badge: Int? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(title == "Cerrar Sesión" ? .piumsError : .primary)

                Spacer()

                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.piumsOrange)
                        .clipShape(Circle())
                }

                if title != "Cerrar Sesión" {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Divider
    private func menuDivider() -> some View {
        Divider().padding(.leading, 58)
    }
}

#Preview { MoreMenuView() }
