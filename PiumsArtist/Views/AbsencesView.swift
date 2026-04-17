//
//  AbsencesView.swift
//  PiumsArtist
//
//  Ausencias y Viajes — gestiona periodos de descanso
//  y colaboraciones internacionales.
//  Consume /artists/dashboard/me/absences
//

import SwiftUI
import Combine

// MARK: - AbsencesView

struct AbsencesView: View {
    @StateObject private var viewModel = AbsencesViewModel()
    @State private var showNewAbsence = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ── Header ──
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // ── + Nueva ausencia ──
                Button { showNewAbsence = true } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                        Text("+ Nueva ausencia")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.piumsOrange)
                    .cornerRadius(14)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // ── Info banner ──
                infoBanner
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // ── Cards Vacaciones / Extranjero ──
                statsCards
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // ── Registro de actividad ──
                activitySection
                    .padding(.horizontal, 20)
                    .padding(.top, 28)

                // ── Resumen anual ──
                annualSummary
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
            }
        }
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Ausencias y Viajes")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await viewModel.loadAbsences() }
        .sheet(isPresented: $showNewAbsence) {
            NewAbsenceSheet(onSave: { payload in
                Task { await viewModel.createAbsence(payload) }
            })
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ausencias y Viajes")
                .font(.title.weight(.bold))
            Text("Gestiona tus periodos de descanso y colaboraciones internacionales en un solo lugar.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Info Banner
    private var infoBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("🏖")
                Text("**Vacaciones** — No apareces en ninguna búsqueda mientras estás ausente.")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            HStack(spacing: 8) {
                Text("✈️")
                Text("**Trabajando en el extranjero** — Solo te ven los clientes del país destino; eres invisible en tu país de origen.")
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    // MARK: - Stats Cards
    private var statsCards: some View {
        HStack(spacing: 12) {
            // Vacaciones
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.piumsOrange.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "sun.max.fill")
                        .font(.body)
                        .foregroundColor(.piumsOrange)
                }

                Text("Vacaciones")
                    .font(.subheadline.weight(.semibold))

                Text("DÍAS DISPONIBLES: \(viewModel.vacationDaysUsed)")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.03), radius: 4, y: 1)

            // Extranjero
            VStack(alignment: .leading, spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.piumsAccent.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "globe.americas.fill")
                        .font(.body)
                        .foregroundColor(.piumsAccent)
                }

                Text("Extranjero")
                    .font(.subheadline.weight(.semibold))

                Text("PROYECTOS ACTIVOS: \(viewModel.abroadCount)")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
        }
    }

    // MARK: - Activity Section
    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Registro de actividad")
                .font(.title3.weight(.bold))

            if viewModel.isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical, 40)
            } else if viewModel.absences.isEmpty {
                // Empty state
                VStack(spacing: 14) {
                    Image(systemName: "calendar.badge.minus")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary.opacity(0.4))

                    Text("No hay ausencias registradas")
                        .font(.subheadline.weight(.semibold))

                    Text("Tu calendario está despejado. Las nuevas solicitudes aparecerán aquí.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
                .background(Color(.systemBackground))
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
            } else {
                // Absence list
                ForEach(viewModel.absences) { absence in
                    absenceRow(absence)
                }
            }
        }
    }

    private func absenceRow(_ absence: AbsenceItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill((absence.type == .vacation ? Color.piumsOrange : Color.piumsAccent).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: absence.type == .vacation ? "sun.max.fill" : "airplane")
                    .font(.body)
                    .foregroundColor(absence.type == .vacation ? .piumsOrange : .piumsAccent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(absence.type == .vacation ? "Vacaciones" : "Trabajo en el extranjero")
                    .font(.subheadline.weight(.semibold))
                Text("\(absence.startFormatted) — \(absence.endFormatted)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let country = absence.destinationCountry, !country.isEmpty {
                    Text("📍 \(country)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button {
                Task { await viewModel.deleteAbsence(absence.id) }
            } label: {
                Image(systemName: "trash")
                    .font(.caption)
                    .foregroundColor(.piumsError)
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
    }

    // MARK: - Annual Summary
    private var annualSummary: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("RESUMEN ANUAL")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.piumsOrange)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.daysOutThisMonth)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.piumsOrange)
                    Text("días fuera este mes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Image(systemName: "airplane.departure")
                .font(.system(size: 40))
                .foregroundColor(.piumsOrange.opacity(0.2))
        }
        .padding(20)
        .background(Color.piumsOrange.opacity(0.08))
        .cornerRadius(16)
    }
}

// MARK: - New Absence Sheet

struct NewAbsenceSheet: View {
    let onSave: (CreateAbsencePayload) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var absenceType: AbsenceType = .vacation
    @State private var country = ""
    @State private var reason = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Tipo de ausencia") {
                    Picker("Tipo", selection: $absenceType) {
                        Text("🏖 Vacaciones").tag(AbsenceType.vacation)
                        Text("✈️ Trabajo en el extranjero").tag(AbsenceType.workingAbroad)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Fechas") {
                    DatePicker("Inicio", selection: $startDate, displayedComponents: .date)
                    DatePicker("Fin", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                if absenceType == .workingAbroad {
                    Section("País destino") {
                        TextField("Ej: México, Colombia…", text: $country)
                    }
                }

                Section("Razón (opcional)") {
                    TextField("¿Por qué te ausentas?", text: $reason, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Nueva ausencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        let iso = ISO8601DateFormatter()
                        let payload = CreateAbsencePayload(
                            startAt: iso.string(from: startDate),
                            endAt: iso.string(from: endDate),
                            type: absenceType.rawValue,
                            destinationCountry: absenceType == .workingAbroad ? country : nil,
                            reason: reason.isEmpty ? nil : reason
                        )
                        onSave(payload)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Models

enum AbsenceType: String, CaseIterable {
    case vacation = "VACATION"
    case workingAbroad = "WORKING_ABROAD"
}

struct AbsenceItem: Identifiable {
    let id: String
    let type: AbsenceType
    let startAt: Date
    let endAt: Date
    let destinationCountry: String?
    let reason: String?

    var startFormatted: String { Self.fmt.string(from: startAt) }
    var endFormatted: String { Self.fmt.string(from: endAt) }

    private static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        f.locale = Locale(identifier: "es_ES")
        return f
    }()
}

struct AbsencesResponseDTO: Codable {
    let absences: [AbsenceDTO]
}

struct AbsenceDTO: Codable {
    let id: String
    let artistId: String?
    let startAt: String
    let endAt: String
    let type: String // VACATION | WORKING_ABROAD
    let destinationCountry: String?
    let reason: String?
    let createdAt: String?

    func toDomain() -> AbsenceItem {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let start = iso.date(from: startAt) ?? ISO8601DateFormatter().date(from: startAt) ?? Date()
        let end = iso.date(from: endAt) ?? ISO8601DateFormatter().date(from: endAt) ?? Date()
        return AbsenceItem(
            id: id,
            type: type == "WORKING_ABROAD" ? .workingAbroad : .vacation,
            startAt: start,
            endAt: end,
            destinationCountry: destinationCountry,
            reason: reason
        )
    }
}

struct CreateAbsencePayload: Codable {
    let startAt: String
    let endAt: String
    let type: String
    let destinationCountry: String?
    let reason: String?
}

struct CreateAbsenceResponseDTO: Codable {
    let absence: AbsenceDTO
}

// MARK: - ViewModel

@MainActor
final class AbsencesViewModel: ObservableObject {
    @Published var absences: [AbsenceItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    var vacationDaysUsed: Int {
        let cal = Calendar.current
        return absences
            .filter { $0.type == .vacation }
            .reduce(0) { sum, a in
                sum + max(1, cal.dateComponents([.day], from: a.startAt, to: a.endAt).day ?? 0)
            }
    }

    var abroadCount: Int {
        absences.filter { $0.type == .workingAbroad }.count
    }

    var daysOutThisMonth: Int {
        let cal = Calendar.current
        let now = Date()
        return absences.reduce(0) { sum, a in
            guard cal.isDate(a.startAt, equalTo: now, toGranularity: .month)
               || cal.isDate(a.endAt, equalTo: now, toGranularity: .month) else { return sum }
            return sum + max(1, cal.dateComponents([.day], from: a.startAt, to: a.endAt).day ?? 0)
        }
    }

    init() {
        Task { await loadAbsences() }
    }

    func loadAbsences() async {
        isLoading = true
        errorMessage = nil
        do {
            let resp = try await api.get(
                endpoint: .artistAbsences,
                responseType: AbsencesResponseDTO.self
            )
            self.absences = resp.absences.map { $0.toDomain() }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func createAbsence(_ payload: CreateAbsencePayload) async {
        do {
            let resp = try await api.post(
                endpoint: .createAbsence,
                body: payload,
                responseType: CreateAbsenceResponseDTO.self
            )
            absences.append(resp.absence.toDomain())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAbsence(_ id: String) async {
        do {
            let _ = try await api.delete(
                endpoint: .deleteAbsence(id),
                responseType: EmptyResponseDTO.self
            )
            absences.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview { NavigationView { AbsencesView() } }
