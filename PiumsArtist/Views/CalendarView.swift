//
//  CalendarView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var showingAvailabilitySheet = false
    @State private var currentMonth = Date()
    
    // Mock availability data
    @State private var availability: [Date: [TimeSlot]] = [:]
    
    init() {
        // Initialize with some mock availability
        let today = Date()
        let calendar = Calendar.current
        
        // Add some sample time slots for the next 7 days
        for i in 0...6 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                _availability = State(initialValue: [
                    date: [
                        TimeSlot(time: "9:00 AM", isAvailable: true, isBooked: i % 3 == 0),
                        TimeSlot(time: "10:30 AM", isAvailable: true, isBooked: false),
                        TimeSlot(time: "12:00 PM", isAvailable: i % 2 == 0, isBooked: false),
                        TimeSlot(time: "2:00 PM", isAvailable: true, isBooked: i % 4 == 0),
                        TimeSlot(time: "3:30 PM", isAvailable: true, isBooked: false),
                        TimeSlot(time: "5:00 PM", isAvailable: i % 3 != 0, isBooked: false)
                    ]
                ])
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Calendar Header
                CalendarHeaderView(currentMonth: $currentMonth)
                
                // Calendar Grid
                CalendarGridView(
                    currentMonth: currentMonth,
                    selectedDate: $selectedDate,
                    availability: availability
                )
                
                Divider()
                    .padding(.horizontal)
                
                // Time slots for selected date
                TimeSlotListView(
                    selectedDate: selectedDate,
                    timeSlots: availability[Calendar.current.startOfDay(for: selectedDate)] ?? []
                )
            }
            .navigationTitle("Calendario")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Disponibilidad") {
                        showingAvailabilitySheet = true
                    }
                }
            }
            .sheet(isPresented: $showingAvailabilitySheet) {
                AvailabilitySettingsView()
            }
        }
    }
}

struct TimeSlot: Identifiable {
    let id = UUID()
    let time: String
    let isAvailable: Bool
    let isBooked: Bool
}

struct CalendarHeaderView: View {
    @Binding var currentMonth: Date
    
    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }
    
    var body: some View {
        HStack {
            Button {
                withAnimation {
                    currentMonth = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            Text(monthFormatter.string(from: currentMonth))
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button {
                withAnimation {
                    currentMonth = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
    }
}

struct CalendarGridView: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    let availability: [Date: [TimeSlot]]
    
    private let calendar = Calendar.current
    private let dateFormatter = DateFormatter()
    
    private var monthDates: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let monthFirstWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)
        let monthLastWeek = calendar.dateInterval(of: .weekOfYear, for: monthInterval.end - 1)
        
        guard let firstWeek = monthFirstWeek,
              let lastWeek = monthLastWeek else {
            return []
        }
        
        var dates: [Date] = []
        var date = firstWeek.start
        
        while date <= lastWeek.end {
            dates.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return dates
    }
    
    private let weekdays = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
    
    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            HStack {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(monthDates, id: \.self) { date in
                    CalendarDayView(
                        date: date,
                        isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(date, equalTo: currentMonth, toGranularity: .month),
                        hasAvailability: availability[calendar.startOfDay(for: date)]?.contains { $0.isAvailable } ?? false,
                        hasBookings: availability[calendar.startOfDay(for: date)]?.contains { $0.isBooked } ?? false
                    ) {
                        selectedDate = date
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

struct CalendarDayView: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasAvailability: Bool
    let hasBookings: Bool
    let action: () -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(textColor)
                
                // Indicators
                HStack(spacing: 2) {
                    if hasBookings {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                    }
                    if hasAvailability {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(width: 35, height: 35)
            .background(backgroundColor)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return .secondary
        } else if isSelected {
            return .white
        } else {
            return .primary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return .blue
        } else {
            return Color.clear
        }
    }
}

struct TimeSlotListView: View {
    let selectedDate: Date
    let timeSlots: [TimeSlot]
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Horarios - \(dateFormatter.string(from: selectedDate))")
                    .font(.headline)
                    .fontWeight(.medium)
                Spacer()
                Button("Editar") {
                    // Action to edit time slots
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(.horizontal)
            
            if timeSlots.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No hay horarios configurados")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 100)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(timeSlots) { slot in
                        TimeSlotCard(timeSlot: slot)
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TimeSlotCard: View {
    let timeSlot: TimeSlot
    
    var body: some View {
        VStack(spacing: 4) {
            Text(timeSlot.time)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(statusText)
                .font(.caption2)
                .foregroundColor(statusColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var statusText: String {
        if timeSlot.isBooked {
            return "Reservado"
        } else if timeSlot.isAvailable {
            return "Disponible"
        } else {
            return "No disponible"
        }
    }
    
    private var statusColor: Color {
        if timeSlot.isBooked {
            return .blue
        } else if timeSlot.isAvailable {
            return .green
        } else {
            return .gray
        }
    }
    
    private var backgroundColor: Color {
        statusColor.opacity(0.1)
    }
}

struct AvailabilitySettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Configuración de Disponibilidad")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Aquí podrás configurar tus horarios de trabajo y disponibilidad")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Placeholder for availability settings
                VStack(spacing: 16) {
                    Text("🚧 Próximamente 🚧")
                        .font(.headline)
                    
                    Text("Esta funcionalidad se implementará en la siguiente versión")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Disponibilidad")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarView()
}