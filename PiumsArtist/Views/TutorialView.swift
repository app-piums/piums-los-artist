//
//  TutorialView.swift
//  PiumsArtist
//

import SwiftUI

struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage = 0

    private let pages: [TutorialPage] = [
        TutorialPage(
            icon: "chart.bar.fill",
            color: .piumsOrange,
            title: "Tu Panel de Control",
            description: "Desde Inicio tienes un resumen de tus ingresos del mes, reservas pendientes y confirmadas. Todo de un vistazo.",
            tip: "Desliza hacia abajo para actualizar los datos en tiempo real."
        ),
        TutorialPage(
            icon: "calendar.badge.checkmark",
            color: .piumsInfo,
            title: "Gestiona tus Reservas",
            description: "Acepta, rechaza o completa reservas desde la pestaña Reservas. Filtra por estado y consulta el detalle de cada cita.",
            tip: "Las reservas pendientes muestran una campana roja en la campana de notificaciones."
        ),
        TutorialPage(
            icon: "calendar",
            color: .piumsSuccess,
            title: "Controla tu Agenda",
            description: "En Agenda puedes bloquear días completos para que los clientes no puedan agendar citas. Toca un día bloqueado y pulsa 'Desbloquear' para recuperar la disponibilidad.",
            tip: "Los puntos de colores en el calendario indican: rojo = bloqueado, azul = con reserva."
        ),
        TutorialPage(
            icon: "bubble.left.and.bubble.right.fill",
            color: .purple,
            title: "Chatea con tus Clientes",
            description: "En Mensajes puedes responder consultas directamente. Las conversaciones se ordenan por actividad reciente y muestran mensajes no leídos.",
            tip: "Al abrir una conversación se marca automáticamente como leída."
        ),
        TutorialPage(
            icon: "bag.fill",
            color: .piumsAccent,
            title: "Publica tus Servicios",
            description: "Crea servicios con nombre, precio, duración y categoría. Activa o desactiva servicios sin eliminarlos para controlar qué ofreces en cada momento.",
            tip: "Los precios se guardan en centavos internamente — el app los muestra en Quetzales automáticamente."
        ),
        TutorialPage(
            icon: "airplane.departure",
            color: .piumsError,
            title: "Ausencias y Viajes",
            description: "Registra vacaciones o trabajo en el extranjero. Durante una ausencia dejas de aparecer en búsquedas de tu país de origen.",
            tip: "Con 'Trabajo en el extranjero' solo te ven los clientes del país destino."
        ),
        TutorialPage(
            icon: "shield.checkered",
            color: .piumsOrange,
            title: "Verifica tu Identidad",
            description: "Completa la verificación de identidad para obtener el sello verificado en tu perfil. Sube el anverso de tu DPI y una selfie con el documento.",
            tip: "La verificación aumenta la confianza de los clientes y mejora tu visibilidad."
        )
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        TutorialPageView(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Indicadores + botones
                VStack(spacing: 20) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            Circle()
                                .fill(i == currentPage ? Color.piumsOrange : Color.secondary.opacity(0.3))
                                .frame(width: i == currentPage ? 10 : 7, height: i == currentPage ? 10 : 7)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    // Botón principal
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Siguiente" : "¡Empezar!")
                            .font(.body.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.piumsOrange)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)

                    // Saltar
                    if currentPage < pages.count - 1 {
                        Button("Saltar tutorial") { dismiss() }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 40)
                .padding(.top, 16)
            }
            .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Tutorial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - Page Model

private struct TutorialPage {
    let icon: String
    let color: Color
    let title: String
    let description: String
    let tip: String
}

// MARK: - Page View

private struct TutorialPageView: View {
    let page: TutorialPage

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Ilustración
                ZStack {
                    Circle()
                        .fill(page.color.opacity(0.1))
                        .frame(width: 140, height: 140)
                    Circle()
                        .fill(page.color.opacity(0.18))
                        .frame(width: 100, height: 100)
                    Image(systemName: page.icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(page.color)
                }
                .padding(.top, 32)

                // Texto
                VStack(spacing: 12) {
                    Text(page.title)
                        .font(.title2.weight(.bold))
                        .multilineTextAlignment(.center)

                    Text(page.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                }
                .padding(.horizontal, 24)

                // Tip
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(page.color)
                        .font(.subheadline)
                    Text(page.tip)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .background(page.color.opacity(0.08))
                .cornerRadius(14)
                .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview { TutorialView() }
