//
//  CalendarView.swift
//  PiumsArtist
//
//  Rediseñado según mockup: calendario con estados, agenda del día,
//  botones bloquear/disponible/horarios, próximas reservas.
//

import SwiftUI

// MARK: - Day Status
enum DayStatus {
    case normal, today, hasBooking, blocked, blockedWithBooking

    var dotColor: Color? {
        switch self {
        case .hasBooking:         return .piumsInfo
        case .blocked:            return .piumsError
        case .blockedWithBooking: return .piumsOrange
        default:                  return nil
        }
    }
}

// MARK: - CalendarView
struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()
    @State private var showBlockSheet = false
    @State private var showScheduleSheet = false

    private let cal = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                topBar.padding(.horizontal, 20).padding(.top, 8)

                monthNav.padding(.horizontal, 20).padding(.top, 12)

                calendarCard.padding(.horizontal, 16).padding(.top, 8)

                legendRow.padding(.horizontal, 24).padding(.top, 8)

                dayAgenda.padding(.horizontal, 16).padding(.top, 20)

                actionButtons.padding(.horizontal, 16).padding(.top, 16)

                upcomingSection.padding(.horizontal, 16).padding(.top, 24).padding(.bottom, 120)
            }
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear { viewModel.refreshData() }
        .onChange(of: selectedDate) { _, date in viewModel.updateSelectedDate(date) }
        .sheet(isPresented: $showBlockSheet) { blockSheet }
        .sheet(isPresented: $showScheduleSheet) { scheduleSheet }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            PiumsAvatarView(name: "A", imageURL: nil, size: 38,
                            gradientColors: [.piumsOrange, .piumsAccent])
            Spacer()
            Text("Piums")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundColor(.piumsOrange)
            Spacer()
            Button { } label: {
                Image(systemName: "gearshape.fill").font(.title3).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Month Navigation
    private var monthNav: some View {
        HStack {
            Text(monthYearString)
                .font(.title2.weight(.bold))
            Spacer()
            HStack(spacing: 16) {
                navCircle("chevron.left")  { changeMonth(-1) }
                navCircle("chevron.right") { changeMonth(1)  }
            }
        }
    }

    private func navCircle(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundColor(.secondary)
                .frame(width: 36, height: 36)
                .background(Color(.systemGray6))
                .clipShape(Circle())
        }
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        VStack(spacing: 10) {
            HStack {
                ForEach(["DOM","LUN","MAR","MIÉ","JUE","VIE","SÁB"], id: \.self) { d in
                    Text(d)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 6) {
                ForEach(Array(daysInMonth().enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 44)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let isSel = cal.isDate(date, inSameDayAs: selectedDate)
        let isToday = cal.isDateInToday(date)
        let isCurMonth = cal.isDate(date, equalTo: currentMonth, toGranularity: .month)
        let status = dayStatus(for: date)

        Button { selectedDate = date } label: {
            VStack(spacing: 3) {
                Text("\(cal.component(.day, from: date))")
                    .font(.system(size: 15, weight: isToday || isSel ? .bold : .regular))
                    .foregroundColor(dayFg(isSel, isToday, isCurMonth))

                if let c = status.dotColor {
                    Circle().fill(c).frame(width: 5, height: 5)
                } else {
                    Color.clear.frame(height: 5)
                }
            }
            .frame(width: 42, height: 44)
            .background(
                Group {
                    if isSel { Circle().fill(Color.piumsOrange) }
                    else if isToday { Circle().fill(Color.piumsOrange.opacity(0.12)) }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Legend
    private var legendRow: some View {
        HStack(spacing: 14) {
            dot(.piumsError, "Bloqueado")
            dot(.piumsInfo, "Con reserva")
            dot(.piumsOrange, "Bloq.+reserva")
            dot(.piumsOrange.opacity(0.3), "Hoy")
        }
        .font(.caption2)
    }

    private func dot(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 4) { Circle().fill(c).frame(width: 7, height: 7); Text(t).foregroundColor(.secondary) }
    }

    // MARK: - Agenda del Día
    private var dayAgenda: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AGENDA DEL DÍA")
                .font(.caption.weight(.bold))
                .foregroundColor(.piumsOrange)

            Text(formattedSelectedDate)
                .font(.title3.weight(.bold))

            HStack(spacing: 12) {
                statTile(icon: "calendar.badge.checkmark", label: "RESERVAS",
                         value: "\(slotsForDay.filter { $0.isBooked }.count) Sesiones")
                statTile(icon: "circle.fill", label: "ESTADO",
                         value: "Disponible", valueColor: .piumsSuccess)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func statTile(icon: String, label: String, value: String, valueColor: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.title3).foregroundColor(.piumsOrange)
            Text(label).font(.caption2.weight(.semibold)).foregroundColor(.secondary)
            Text(value).font(.subheadline.weight(.bold)).foregroundColor(valueColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button { showBlockSheet = true } label: {
                Label("Bloquear día", systemImage: "nosign")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.piumsOrange)
                    .cornerRadius(14)
            }

            HStack(spacing: 10) {
                pillButton("Disponible", icon: "checkmark.circle.fill", fg: .piumsSuccess) {}
                pillButton("Horarios", icon: "clock.fill", fg: .piumsOrange) { showScheduleSheet = true }
            }
        }
    }

    private func pillButton(_ title: String, icon: String, fg: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundColor(fg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(fg.opacity(0.12))
                .cornerRadius(12)
        }
    }

    // MARK: - Próximas Reservas
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("PRÓXIMAS RESERVAS")
                .font(.caption.weight(.bold))
                .foregroundColor(.secondary)

            let booked = slotsForDay.filter { $0.isBooked }
            if booked.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.largeTitle).foregroundColor(.secondary.opacity(0.5))
                        Text("Sin reservas para este día")
                            .font(.subheadline).foregroundColor(.secondary)
                    }.padding(.vertical, 24)
                    Spacer()
                }
            } else {
                ForEach(booked) { slot in
                    HStack(alignment: .top, spacing: 14) {
                        Text(slot.time)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 48, alignment: .trailing)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sesión reservada")
                                .font(.subheadline.weight(.semibold))
                            Text(slot.time)
                                .font(.caption).foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.03), radius: 4, y: 1)
                    }
                }
            }
        }
    }

    // MARK: - Sheets
    private var blockSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "nosign").font(.system(size: 50)).foregroundColor(.piumsError)
                Text("Bloquear \(formattedSelectedDate)").font(.title3.weight(.semibold))
                Text("Al bloquear este día, los clientes no podrán agendar citas.")
                    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)

                Button { showBlockSheet = false } label: {
                    Text("Confirmar bloqueo")
                        .font(.subheadline.weight(.semibold)).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(Color.piumsError).cornerRadius(14)
                }.padding(.horizontal)
                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Bloquear día").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { showBlockSheet = false } } }
        }.presentationDetents([.medium])
    }

    private var scheduleSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "clock.badge.checkmark").font(.system(size: 50)).foregroundColor(.piumsOrange)
                Text("Configurar horarios").font(.title3.weight(.semibold))
                Text("Define los horarios en los que aceptas citas.")
                    .font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center).padding(.horizontal)

                let slots = slotsForDay
                if slots.isEmpty {
                    Text("Sin horarios configurados").foregroundColor(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                        ForEach(slots) { slot in
                            Text(slot.time)
                                .font(.caption.weight(.medium))
                                .padding(.vertical, 8).frame(maxWidth: .infinity)
                                .background(slot.isBooked ? Color.piumsInfo.opacity(0.15) : slot.isAvailable ? Color.piumsSuccess.opacity(0.15) : Color(.systemGray6))
                                .foregroundColor(slot.isBooked ? .piumsInfo : slot.isAvailable ? .piumsSuccess : .secondary)
                                .cornerRadius(8)
                        }
                    }.padding(.horizontal)
                }
                Spacer()
            }
            .padding(.top, 30)
            .navigationTitle("Horarios").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cerrar") { showScheduleSheet = false } } }
        }.presentationDetents([.large])
    }

    // MARK: - Helpers
    private var slotsForDay: [CalendarViewModel.TimeSlot] {
        let dayStart = Calendar.current.startOfDay(for: selectedDate)
        return viewModel.availability[dayStart] ?? []
    }

    private var monthYearString: String {
        let f = DateFormatter(); f.dateFormat = "MMMM 'De' yyyy"; f.locale = Locale(identifier: "es_ES")
        let s = f.string(from: currentMonth)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    private var formattedSelectedDate: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, d 'De' MMMM 'De' yyyy"; f.locale = Locale(identifier: "es_ES")
        let s = f.string(from: selectedDate)
        return s.prefix(1).uppercased() + s.dropFirst()
    }

    private func changeMonth(_ d: Int) {
        withAnimation(.easeInOut(duration: 0.25)) {
            currentMonth = cal.date(byAdding: .month, value: d, to: currentMonth) ?? currentMonth
        }
    }

    private func daysInMonth() -> [Date?] {
        guard let range = cal.range(of: .day, in: .month, for: currentMonth),
              let first = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth)) else { return [] }
        let pad = (cal.component(.weekday, from: first) - cal.firstWeekday + 7) % 7
        var r: [Date?] = Array(repeating: nil, count: pad)
        for d in range { if let dt = cal.date(byAdding: .day, value: d - 1, to: first) { r.append(dt) } }
        while r.count % 7 != 0 { r.append(nil) }
        return r
    }

    private func dayFg(_ sel: Bool, _ today: Bool, _ cur: Bool) -> Color {
        if sel { return .white }
        if !cur { return .secondary.opacity(0.4) }
        return .primary
    }

    private func dayStatus(for date: Date) -> DayStatus {
        if cal.isDateInToday(date) { return .today }
        let dayStart = cal.startOfDay(for: date)
        if let slots = viewModel.availability[dayStart] {
            if slots.contains(where: { $0.isBooked }) { return .hasBooking }
        }
        return .normal
    }
}

#Preview { CalendarView() }
