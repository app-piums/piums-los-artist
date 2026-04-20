//
//  TutorialManager.swift
//  PiumsArtist
//

import SwiftUI
import Combine

@MainActor
final class TutorialManager: ObservableObject {
    static let shared = TutorialManager()

    @Published var isActive = false
    @Published var currentStep = 0

    struct TourStep {
        let tab: Int
        let icon: String
        let color: Color
        let title: String
        let description: String
        let tip: String
    }

    let steps: [TourStep] = [
        TourStep(
            tab: 0, icon: "chart.bar.fill", color: .piumsOrange,
            title: "Panel de Control",
            description: "Aquí ves de un vistazo tus ingresos del mes, reservas pendientes y confirmadas, y la fortaleza de tu perfil.",
            tip: "Desliza hacia abajo para actualizar los datos en tiempo real."
        ),
        TourStep(
            tab: 1, icon: "calendar.badge.checkmark", color: .piumsInfo,
            title: "Tus Reservas",
            description: "Acepta, rechaza o completa reservas. Filtra por estado y consulta el detalle de cada cita desde aquí.",
            tip: "Las reservas pendientes activan una alerta en la campana de notificaciones."
        ),
        TourStep(
            tab: 2, icon: "calendar", color: .piumsSuccess,
            title: "Tu Agenda",
            description: "Bloquea días completos para que los clientes no puedan agendar. Toca un día bloqueado y pulsa 'Desbloquear' para recuperar disponibilidad.",
            tip: "Puntos en el calendario: rojo = bloqueado, azul = con reserva."
        ),
        TourStep(
            tab: 3, icon: "bubble.left.and.bubble.right.fill", color: .purple,
            title: "Mensajes",
            description: "Responde consultas de clientes directamente. Las conversaciones se ordenan por actividad reciente y muestran mensajes no leídos.",
            tip: "Al abrir una conversación se marca automáticamente como leída."
        ),
        TourStep(
            tab: 4, icon: "bag.fill", color: .piumsAccent,
            title: "Tus Servicios",
            description: "Desde 'Más → Servicios' crea servicios con nombre, precio, duración y categoría. Activa o desactiva sin eliminar.",
            tip: "Los precios se muestran en Quetzales automáticamente."
        ),
        TourStep(
            tab: 4, icon: "airplane.departure", color: .piumsError,
            title: "Ausencias y Viajes",
            description: "Registra vacaciones o trabajo en el extranjero en 'Más → Ausencias'. Durante una ausencia dejas de aparecer en búsquedas.",
            tip: "Con 'Trabajo en el extranjero' solo te ven los clientes del país destino."
        ),
        TourStep(
            tab: 4, icon: "shield.checkered", color: .piumsOrange,
            title: "Verificación de Identidad",
            description: "Obtén el sello verificado en 'Más → Verificación'. Sube el anverso de tu DPI y una selfie con el documento.",
            tip: "La verificación aumenta la confianza de clientes y mejora tu visibilidad."
        ),
    ]

    var currentTabTarget: Int {
        guard currentStep < steps.count else { return 0 }
        return steps[currentStep].tab
    }

    var currentStepData: TourStep? {
        guard currentStep < steps.count else { return nil }
        return steps[currentStep]
    }

    var isLastStep: Bool { currentStep == steps.count - 1 }

    func start() {
        currentStep = 0
        isActive = true
    }

    func next() {
        if isLastStep {
            end()
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep += 1
            }
        }
    }

    func previous() {
        guard currentStep > 0 else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentStep -= 1
        }
    }

    func end() {
        withAnimation(.easeOut(duration: 0.25)) {
            isActive = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentStep = 0
        }
    }
}
