//
//  ViewModels.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Dashboard ViewModel
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var todayBookings: [Booking] = []
    @Published var pendingBookings: [Booking] = []
    @Published var completedBookings: [Booking] = []
    @Published var monthlyEarnings: Double = 0.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    init() {
        loadMockData()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshData()
    }
    
    func refreshData() {
        isLoading = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadMockData()
            self.isLoading = false
        }
    }
    
    private func loadMockData() {
        // Mock data for dashboard
        let calendar = Calendar.current
        let today = Date()
        
        todayBookings = [
            Booking(
                clientName: "María García",
                clientEmail: "maria@email.com",
                scheduledDate: calendar.date(byAdding: .hour, value: 2, to: today) ?? today,
                duration: 60,
                totalPrice: 45.0,
                status: .confirmed
            ),
            Booking(
                clientName: "Ana López",
                clientEmail: "ana@email.com",
                scheduledDate: calendar.date(byAdding: .hour, value: 5, to: today) ?? today,
                duration: 90,
                totalPrice: 65.0,
                status: .pending
            )
        ]
        
        pendingBookings = todayBookings.filter { $0.status == .pending }
        completedBookings = Array(repeating: todayBookings[0], count: 8)
        monthlyEarnings = 2450.0
    }
    
    var todayBookingsCount: Int {
        todayBookings.count
    }
    
    var pendingBookingsCount: Int {
        pendingBookings.count
    }
    
    var completedBookingsCount: Int {
        completedBookings.count
    }
    
    var formattedEarnings: String {
        "$\(Int(monthlyEarnings))"
    }
}

// MARK: - Bookings ViewModel
@MainActor
final class BookingsViewModel: ObservableObject {
    @Published var bookings: [Booking] = []
    @Published var filteredBookings: [Booking] = []
    @Published var selectedFilter: BookingFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    
    enum BookingFilter: String, CaseIterable {
        case all = "Todas"
        case pending = "Pendientes"
        case confirmed = "Confirmadas"
        case completed = "Completadas"
        case cancelled = "Canceladas"
    }
    
    init() {
        loadMockData()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshData()
    }
    
    func refreshData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadMockData()
            self.isLoading = false
        }
    }
    
    func updateFilter(_ filter: BookingFilter) {
        selectedFilter = filter
        applyFilter()
    }
    
    func acceptBooking(_ booking: Booking) {
        // Update booking status
        if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[index].status = .confirmed
            bookings[index].updatedAt = Date()
        }
        applyFilter()
    }
    
    func rejectBooking(_ booking: Booking) {
        // Update booking status
        if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[index].status = .cancelled
            bookings[index].updatedAt = Date()
        }
        applyFilter()
    }
    
    func completeBooking(_ booking: Booking) {
        // Update booking status
        if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
            bookings[index].status = .completed
            bookings[index].updatedAt = Date()
        }
        applyFilter()
    }
    
    private func loadMockData() {
        let calendar = Calendar.current
        let today = Date()
        
        bookings = [
            Booking(
                clientName: "María García",
                clientEmail: "maria.garcia@email.com",
                clientPhone: "+34 666 111 222",
                scheduledDate: today,
                duration: 60,
                totalPrice: 45.0,
                notes: "Corte y peinado para evento",
                status: .confirmed
            ),
            Booking(
                clientName: "Ana López",
                clientEmail: "ana.lopez@email.com",
                scheduledDate: calendar.date(byAdding: .hour, value: 2, to: today) ?? today,
                duration: 120,
                totalPrice: 80.0,
                status: .pending
            ),
            Booking(
                clientName: "Carlos Ruiz",
                clientEmail: "carlos.ruiz@email.com",
                scheduledDate: calendar.date(byAdding: .hour, value: 4, to: today) ?? today,
                duration: 30,
                totalPrice: 25.0,
                status: .confirmed
            ),
            Booking(
                clientName: "Laura Martín",
                clientEmail: "laura.martin@email.com",
                scheduledDate: calendar.date(byAdding: .day, value: -1, to: today) ?? today,
                duration: 90,
                totalPrice: 65.0,
                status: .completed
            )
        ]
        
        applyFilter()
    }
    
    private func applyFilter() {
        switch selectedFilter {
        case .all:
            filteredBookings = bookings
        case .pending:
            filteredBookings = bookings.filter { $0.status == .pending }
        case .confirmed:
            filteredBookings = bookings.filter { $0.status == .confirmed }
        case .completed:
            filteredBookings = bookings.filter { $0.status == .completed }
        case .cancelled:
            filteredBookings = bookings.filter { $0.status == .cancelled }
        }
    }
}

// MARK: - Calendar ViewModel
@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var currentMonth = Date()
    @Published var availability: [Date: [TimeSlot]] = [:]
    @Published var isLoading = false
    
    struct TimeSlot: Identifiable {
        let id = UUID()
        let time: String
        let isAvailable: Bool
        let isBooked: Bool
        
        init(time: String, isAvailable: Bool = true, isBooked: Bool = false) {
            self.time = time
            self.isAvailable = isAvailable
            self.isBooked = isBooked
        }
    }
    
    private var modelContext: ModelContext?
    
    init() {
        loadMockAvailability()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshData()
    }
    
    func refreshData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadMockAvailability()
            self.isLoading = false
        }
    }
    
    func updateSelectedDate(_ date: Date) {
        selectedDate = date
    }
    
    func updateCurrentMonth(_ month: Date) {
        currentMonth = month
    }
    
    func toggleTimeSlotAvailability(_ slot: TimeSlot, for date: Date) {
        let dayStart = Calendar.current.startOfDay(for: date)
        
        if var daySlots = availability[dayStart],
           let index = daySlots.firstIndex(where: { $0.id == slot.id }) {
            daySlots[index] = TimeSlot(
                time: slot.time,
                isAvailable: !slot.isAvailable,
                isBooked: slot.isBooked
            )
            availability[dayStart] = daySlots
        }
    }
    
    private func loadMockAvailability() {
        let calendar = Calendar.current
        let today = Date()
        
        // Generate availability for next 30 days
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                
                availability[dayStart] = [
                    TimeSlot(time: "9:00 AM", isAvailable: true, isBooked: i % 3 == 0),
                    TimeSlot(time: "10:30 AM", isAvailable: true, isBooked: false),
                    TimeSlot(time: "12:00 PM", isAvailable: i % 2 == 0, isBooked: false),
                    TimeSlot(time: "2:00 PM", isAvailable: true, isBooked: i % 4 == 0),
                    TimeSlot(time: "3:30 PM", isAvailable: true, isBooked: false),
                    TimeSlot(time: "5:00 PM", isAvailable: i % 3 != 0, isBooked: false)
                ]
            }
        }
    }
    
    var selectedDateTimeSlots: [TimeSlot] {
        let dayStart = Calendar.current.startOfDay(for: selectedDate)
        return availability[dayStart] ?? []
    }
}

// MARK: - Messages ViewModel
@MainActor
final class MessagesViewModel: ObservableObject {
    @Published var conversations: [ConversationItem] = []
    @Published var filteredConversations: [ConversationItem] = []
    @Published var searchText = ""
    @Published var isLoading = false
    
    struct ConversationItem: Identifiable {
        let id = UUID()
        let clientName: String
        let clientEmail: String
        let lastMessage: String
        let timestamp: Date
        let unreadCount: Int
        let isOnline: Bool
        var messages: [MessageItem]
    }
    
    struct MessageItem: Identifiable {
        let id = UUID()
        let content: String
        let isFromArtist: Bool
        let timestamp: Date
        let isRead: Bool
    }
    
    private var modelContext: ModelContext?
    
    init() {
        loadMockConversations()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshData()
    }
    
    func refreshData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadMockConversations()
            self.isLoading = false
        }
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        filterConversations()
    }
    
    func sendMessage(_ content: String, to conversationId: UUID) {
        if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
            let newMessage = MessageItem(
                content: content,
                isFromArtist: true,
                timestamp: Date(),
                isRead: true
            )
            
            conversations[index].messages.append(newMessage)
            filterConversations()
        }
    }
    
    private func loadMockConversations() {
        let calendar = Calendar.current
        
        conversations = [
            ConversationItem(
                clientName: "María García",
                clientEmail: "maria.garcia@email.com",
                lastMessage: "¡Perfecto! Nos vemos mañana a las 10:00",
                timestamp: Date(),
                unreadCount: 0,
                isOnline: true,
                messages: [
                    MessageItem(content: "Hola, ¿tienes disponibilidad para mañana?", isFromArtist: false, timestamp: calendar.date(byAdding: .hour, value: -2, to: Date()) ?? Date(), isRead: true),
                    MessageItem(content: "¡Hola! Sí, tengo disponibilidad. ¿A qué hora te vendría bien?", isFromArtist: true, timestamp: calendar.date(byAdding: .hour, value: -1, to: Date()) ?? Date(), isRead: true)
                ]
            ),
            ConversationItem(
                clientName: "Ana López",
                clientEmail: "ana.lopez@email.com",
                lastMessage: "¿Podrías confirmar la cita?",
                timestamp: calendar.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                unreadCount: 2,
                isOnline: false,
                messages: []
            )
        ]
        
        filterConversations()
    }
    
    private func filterConversations() {
        if searchText.isEmpty {
            filteredConversations = conversations
        } else {
            filteredConversations = conversations.filter { conversation in
                conversation.clientName.localizedCaseInsensitiveContains(searchText) ||
                conversation.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Profile ViewModel
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var artist: Artist?
    @Published var services: [Service] = []
    @Published var statistics: ProfileStatistics = ProfileStatistics()
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    struct ProfileStatistics {
        var totalClients: Int = 1234
        var completedServices: Int = 2156
        var monthlyEarnings: Double = 3250.0
        var averageRating: Double = 4.8
    }
    
    private var modelContext: ModelContext?
    
    init() {
        loadMockData()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        refreshData()
    }
    
    func refreshData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.loadMockData()
            self.isLoading = false
        }
    }
    
    func updateProfile(_ updatedArtist: Artist) {
        artist = updatedArtist
        // Save to model context if available
    }
    
    private func loadMockData() {
        artist = Artist.preview
        services = Service.previewServices
        statistics = ProfileStatistics(
            totalClients: 1234,
            completedServices: 2156,
            monthlyEarnings: 3250.0,
            averageRating: 4.8
        )
    }
}