//
//  MoreMenuView.swift
//  PiumsArtist
//

import SwiftUI

struct MoreMenuView: View {
    @State private var showProfile = false
    @State private var showServices = false
    @State private var showAbsences = false
    @State private var showSettings = false
    @State private var showLogoutAlert = false
    @State private var showReviews = false
    @State private var showDisputas = false

    var body: some View {
        NavigationView {
            List {
                // ── Profile ──
                Section {
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
                                Text(AuthService.shared.currentArtist?.email ?? "Artista Pro")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Artista Pro")
                                    .font(.caption)
                                    .padding(.horizontal, 8).padding(.vertical, 3)
                                    .background(Color.piumsOrange.opacity(0.12))
                                    .foregroundColor(.piumsOrange)
                                    .clipShape(Capsule())
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color(.tertiarySystemGroupedBackground))

                // ── MAIN ──
                Section("Main") {
                    menuRow(icon: "bag.fill", title: "Servicios", color: .piumsOrange) { showServices = true }
                    menuRow(icon: "airplane.departure", title: "Ausencias / Viajes", color: .purple) { showAbsences = true }
                    menuRow(icon: "sparkles", title: "Tutorial", color: .piumsAccent) {}
                }
                .listRowBackground(Color(.tertiarySystemGroupedBackground))

                // ── FINANCE ──
                Section("Finance") {
                    menuRow(icon: "wallet.pass.fill", title: "Billetera", color: .piumsSuccess) {}
                    menuRow(icon: "doc.text.fill", title: "Facturas", color: Color(.systemIndigo)) {}
                }
                .listRowBackground(Color(.tertiarySystemGroupedBackground))

                // ── CUENTA ──
                Section("Cuenta") {
                    menuRow(icon: "star.fill", title: "Reseñas", color: .yellow) { showReviews = true }
                    menuRow(icon: "exclamationmark.triangle.fill", title: "Quejas", color: .piumsWarning) { showDisputas = true }
                    menuRow(icon: "gearshape.fill", title: "Configuración", color: Color(.systemGray)) { showSettings = true }
                }
                .listRowBackground(Color(.tertiarySystemGroupedBackground))

                // ── CERRAR SESIÓN ──
                Section {
                    Button(role: .destructive) { showLogoutAlert = true } label: {
                        HStack {
                            Spacer()
                            Text("Cerrar Sesión")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                        }
                    }
                }
                .listRowBackground(Color(.tertiarySystemGroupedBackground))
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Más")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(.secondarySystemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .sheet(isPresented: $showProfile) { ProfileView() }
            .sheet(isPresented: $showServices) { NavigationView { ServicesView() }.presentationDetents([.large]) }
            .sheet(isPresented: $showAbsences) { NavigationView { AbsencesView() }.presentationDetents([.large]) }
            .sheet(isPresented: $showReviews) { NavigationView { ReviewsView() }.presentationDetents([.large]) }
            .sheet(isPresented: $showDisputas) { DisputasView().presentationDetents([.large]) }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(ThemeManager.shared)
            }
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

    // MARK: - Menu Row
    private func menuRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label {
                Text(title)
                    .foregroundColor(.primary)
            } icon: {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(color)
                        .frame(width: 28, height: 28)
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .foregroundColor(.primary)
    }
}

#Preview { MoreMenuView() }
