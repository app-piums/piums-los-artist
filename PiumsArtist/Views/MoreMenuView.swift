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
    @State private var showTutorial = false
    @State private var showComingSoon = false
    @State private var comingSoonTitle = ""

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
                    Button { showServices = true } label: {
                        Label("Servicios", systemImage: "bag")
                    }
                    Button { showAbsences = true } label: {
                        Label("Ausencias / Viajes", systemImage: "airplane.departure")
                    }
                    Button { showTutorial = true } label: {
                        Label("Tutorial", systemImage: "sparkles")
                    }
                }
                .listRowBackground(Color(.tertiarySystemGroupedBackground))
                .foregroundStyle(.primary)

                // ── FINANCE ──
                Section("Finance") {
                    Button { comingSoonTitle = "Billetera"; showComingSoon = true } label: {
                        Label("Billetera", systemImage: "wallet.pass")
                    }
                    Button { comingSoonTitle = "Facturas"; showComingSoon = true } label: {
                        Label("Facturas", systemImage: "doc.text")
                    }
                }
                .listRowBackground(Color(.tertiarySystemGroupedBackground))
                .foregroundStyle(.primary)

                // ── CUENTA ──
                Section("Cuenta") {
                    Button { showReviews = true } label: {
                        Label("Reseñas", systemImage: "star")
                    }
                    Button { showDisputas = true } label: {
                        Label("Quejas", systemImage: "exclamationmark.bubble")
                    }
                    Button { showSettings = true } label: {
                        Label("Configuración", systemImage: "gearshape")
                    }
                }
                .listRowBackground(Color(.tertiarySystemGroupedBackground))
                .foregroundStyle(.primary)

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
            .sheet(isPresented: $showTutorial) { TutorialView().presentationDetents([.large]) }
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
            .alert("Próximamente", isPresented: $showComingSoon) {
                Button("Entendido", role: .cancel) {}
            } message: {
                Text("\(comingSoonTitle) estará disponible en una próxima actualización.")
            }
        }
    }

}

#Preview { MoreMenuView() }
