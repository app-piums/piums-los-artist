//
//  ViewModels.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

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
    private let apiService = APIService.shared
    
    init() {
        Task {
            await loadDashboardData()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await refreshData()
        }
    }
    
    func refreshData() async {
        await loadDashboardData()
    }
    
    @MainActor
    private func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load artist dashboard data
            let dashboardResponse = try await apiService.get(
                endpoint: .artistDashboard,
                responseType: ArtistDashboardDTO.self
            )
            
            let (_, revenueStats, _) = dashboardResponse.toDashboardStats()
            self.monthlyEarnings = revenueStats.thisMonth
            
            // Load artist bookings to get detailed booking data
            let bookingsResponse = try await apiService.get(
                endpoint: .artistBookings(status: nil, page: 1),
                responseType: PaginatedResponseDTO<BookingDTO>.self
            )
            
            let allBookings = bookingsResponse.data.map { $0.toDomainModel() }
            
            // Filter bookings for today
            let today = Date()
            let calendar = Calendar.current
            self.todayBookings = allBookings.filter { booking in
                calendar.isDate(booking.scheduledDate, inSameDayAs: today)
            }
            
            self.pendingBookings = allBookings.filter { $0.status == .pending }
            self.completedBookings = allBookings.filter { $0.status == .completed }
            
        } catch {
            self.errorMessage = error.localizedDescription
            // Fallback to mock data if API fails
            loadMockData()
        }
        
        isLoading = false
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
    private let apiService = APIService.shared
    
    enum BookingFilter: String, CaseIterable {
        case all = "Todas"
        case pending = "Pendientes"
        case confirmed = "Confirmadas"
        case completed = "Completadas"
        case cancelled = "Canceladas"
    }
    
    init() {
        Task {
            await loadBookings()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await refreshData()
        }
    }
    
    func refreshData() async {
        await loadBookings()
    }
    
    @MainActor
    private func loadBookings() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.get(
                endpoint: .artistBookings(status: nil, page: 1),
                responseType: PaginatedResponseDTO<BookingDTO>.self
            )
            
            self.bookings = response.data.map { $0.toDomainModel() }
            applyFilter()
            
        } catch {
            self.errorMessage = error.localizedDescription
            // Fallback to mock data if API fails
            loadMockData()
        }
        
        isLoading = false
    }
    
    func updateFilter(_ filter: BookingFilter) {
        selectedFilter = filter
        applyFilter()
    }
    
    func acceptBooking(_ booking: Booking) {
        Task {
            await updateBookingStatus(booking, status: "CONFIRMED")
        }
    }
    
    func rejectBooking(_ booking: Booking) {
        Task {
            await updateBookingStatus(booking, status: "CANCELLED")
        }
    }
    
    func completeBooking(_ booking: Booking) {
        Task {
            await updateBookingStatus(booking, status: "COMPLETED")
        }
    }
    
    @MainActor
    private func updateBookingStatus(_ booking: Booking, status: String) async {
        do {
            // Use specific artist endpoints for accepting/declining bookings
            let endpoint: APIEndpoint
            
            switch status {
            case "CONFIRMED":
                endpoint = .acceptBooking(booking.id.uuidString)
            case "CANCELLED":
                endpoint = .declineBooking(booking.id.uuidString)
            default:
                // For other statuses like completed, might need different approach
                // For now, we'll skip as they may not have direct endpoints
                return
            }
            
            let _ = try await apiService.request(
                endpoint: endpoint,
                method: .POST,
                responseType: SuccessResponseDTO.self
            )
            
            // Update local booking
            if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
                let newStatus: BookingStatus = {
                    switch status {
                    case "CONFIRMED": return .confirmed
                    case "CANCELLED": return .cancelled
                    case "COMPLETED": return .completed
                    default: return .pending
                    }
                }()
                
                bookings[index].status = newStatus
                bookings[index].updatedAt = Date()
            }
            
            applyFilter()
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // Keep as fallback
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
    @Published var errorMessage: String?
    
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
    private let apiService = APIService.shared
    
    init() {
        Task {
            await loadConversations()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await refreshData()
        }
    }
    
    func refreshData() async {
        await loadConversations()
    }
    
    @MainActor
    private func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.get(
                endpoint: .conversations,
                responseType: [ConversationDTO].self
            )
            
            self.conversations = response.map { dto in
                let conversation = dto.toDomainModel()
                return conversation
            }
            filterConversations()
            
        } catch {
            self.errorMessage = error.localizedDescription
            // Fallback to mock data if API fails
            loadMockConversations()
        }
        
        isLoading = false
    }
    
    func updateSearchText(_ text: String) {
        searchText = text
        filterConversations()
    }
    
    func sendMessage(_ content: String, to conversationId: UUID) {
        Task {
            await sendMessageAPI(content, to: conversationId)
        }
    }
    
    @MainActor
    private func sendMessageAPI(_ content: String, to conversationId: UUID) async {
        do {
            let request = SendMessageRequest(conversationId: conversationId.uuidString, content: content, type: "TEXT")
            let response = try await apiService.post(
                endpoint: .sendMessage,
                body: request,
                responseType: MessageDTO.self
            )
            
            if let index = conversations.firstIndex(where: { $0.id == conversationId }) {
                let newMessage = response.toDomainModel()
                conversations[index].messages.append(newMessage)
                filterConversations()
            }
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // Keep as fallback
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
        var totalClients: Int = 0
        var completedServices: Int = 0
        var monthlyEarnings: Double = 0.0
        var averageRating: Double = 0.0
    }
    
    private var modelContext: ModelContext?
    private let apiService = APIService.shared
    
    init() {
        Task {
            await loadProfileData()
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task {
            await refreshData()
        }
    }
    
    func refreshData() async {
        await loadProfileData()
    }
    
    @MainActor
    private func loadProfileData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load user profile (basic user info)
            let userResponse = try await apiService.get(
                endpoint: .userProfile,
                responseType: UserDTO.self
            )
            
            // Try to get artist profile if exists
            // For now we'll use user info and mock artist data
            self.artist = userResponse.toDomainModel()
            
            // Load artist dashboard for statistics
            let dashboardResponse = try await apiService.get(
                endpoint: .artistDashboard,
                responseType: ArtistDashboardDTO.self
            )
            
            let (_, revenueStats, ratingStats) = dashboardResponse.toDashboardStats()
            self.statistics = ProfileStatistics(
                totalClients: 0, // Not available in current API
                completedServices: 0, // Not available in current API  
                monthlyEarnings: revenueStats.thisMonth,
                averageRating: ratingStats.average
            )
            
            // Load services from catalog
            let servicesResponse = try await apiService.get(
                endpoint: .catalogServices(artistId: userResponse.id, category: nil),
                responseType: [ServiceDTO].self
            )
            
            self.services = servicesResponse.map { $0.toDomainModel() }
            
        } catch {
            self.errorMessage = error.localizedDescription
            // Fallback to mock data if API fails
            loadMockData()
        }
        
        isLoading = false
    }
    
    func updateProfile(_ updatedArtist: Artist) {
        Task {
            await saveProfile(updatedArtist)
        }
    }
    
    @MainActor
    private func saveProfile(_ updatedArtist: Artist) async {
        do {
            let request = UpdateUserRequest(
                name: updatedArtist.name,
                phone: updatedArtist.phone,
                bio: updatedArtist.bio,
                location: nil // Can add location support later
            )
            
            let response = try await apiService.put(
                endpoint: .updateUserProfile,
                body: request,
                responseType: UserDTO.self
            )
            
            self.artist = response.toDomainModel()
            
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    // Keep as fallback
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
