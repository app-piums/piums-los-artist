//
//  TutorialView.swift
//  PiumsArtist
//

import SwiftUI

// MARK: - Data

private struct TutorialPage {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let tip: String
}

private let quickSteps: [(String, String)] = [
    ("chart.bar.fill",                    "Estadísticas clave"),
    ("calendar.badge.checkmark",          "Gestión de reservas"),
    ("calendar",                          "Agenda de disponibilidad"),
    ("bubble.left.and.bubble.right.fill", "Chat con clientes"),
    ("bag.fill",                          "Tus servicios"),
    ("airplane.departure",                "Ausencias y viajes"),
    ("shield.checkered",                  "Verificación de identidad"),
    ("person.fill",                       "Fortaleza del perfil"),
]

// MARK: - Main View

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    private let tutorial = TutorialManager.shared
    private let totalSteps = TutorialManager.shared.steps.count

    var body: some View {
        NavigationView {
            ZStack {
                Color(.secondarySystemGroupedBackground).ignoresSafeArea()
                IntroPage {
                    // Start tour: dismiss sheet first, then activate after animation
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                        tutorial.start()
                    }
                }
            }
            .navigationTitle("Tour para Artistas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Intro Page

private struct IntroPage: View {
    let onStart: () -> Void
    @State private var appeared = false
    private let totalSteps = TutorialManager.shared.steps.count

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Hero icon
                ZStack {
                    Circle()
                        .fill(Color.piumsOrange.opacity(0.1))
                        .frame(width: 110, height: 110)
                    Circle()
                        .fill(Color.piumsOrange.opacity(0.18))
                        .frame(width: 76, height: 76)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.piumsOrange)
                }
                .padding(.top, 32)
                .scaleEffect(appeared ? 1 : 0.6)
                .opacity(appeared ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.05), value: appeared)

                // Title + subtitle
                VStack(spacing: 8) {
                    Text("Tour para Artistas")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.piumsTextPrimary)
                        .multilineTextAlignment(.center)

                    Text("Tour de **\(totalSteps) pasos** que recorre cada herramienta en la app real.")
                        .font(.body)
                        .foregroundColor(.piumsTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Label("Tiempo estimado: ~2 minutos", systemImage: "clock")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.piumsTextSecondary)
                        .padding(.top, 2)
                }
                .padding(.top, 20)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)

                // Quick steps grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(quickSteps.indices, id: \.self) { i in
                        let step = quickSteps[i]
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.piumsOrange.opacity(0.12))
                                    .frame(width: 30, height: 30)
                                Image(systemName: step.0)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.piumsOrange)
                            }
                            Text(step.1)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.piumsTextPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.85)
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(Color(.tertiarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)
                        .animation(.easeOut(duration: 0.4).delay(0.2 + Double(i) * 0.05), value: appeared)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // CTA
                VStack(spacing: 10) {
                    Button(action: onStart) {
                        HStack(spacing: 8) {
                            Text("Iniciar tour interactivo")
                                .font(.body.weight(.semibold))
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.body)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.piumsOrange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.piumsOrange.opacity(0.4), radius: 10, y: 4)
                    }

                    Text("Navega por la app real mientras aprendes")
                        .font(.caption)
                        .foregroundColor(.piumsTextSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.easeOut(duration: 0.4).delay(0.55), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }
}

#Preview { TutorialView() }
