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
    @Published var totalEarnings: Double = 0.0
    @Published var totalBookings: Int = 0
    @Published var pendingCount: Int = 0
    @Published var confirmedCount: Int = 0
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
            // Cargar stats reales del dashboard
            let statsResp = try await apiService.get(
                endpoint: .artistStats,
                responseType: ArtistStatsResponseDTO.self
            )
            let stats = statsResp.stats
            
            // Cargar reservas próximas (CONFIRMED y PENDING)
            let bookingsResp = try await apiService.get(
                endpoint: .artistBookings(status: nil, page: 1, artistId: nil),
                responseType: ArtistBookingsResponseDTO.self
            )
            
            let allBookings = bookingsResp.bookings.map { $0.toDomainModel() }
            
            let today = Date()
            let calendar = Calendar.current
            self.todayBookings = allBookings.filter {
                calendar.isDate($0.scheduledDate, inSameDayAs: today)
            }
            self.pendingBookings  = allBookings.filter { $0.status == .pending }
            self.completedBookings = allBookings.filter { $0.status == .completed }
            
            // Usar ingresos del backend
            self.monthlyEarnings = stats.revenue.thisMonth
            self.totalEarnings   = stats.revenue.total
            
            // Stats de bookings reales
            self.totalBookings  = stats.bookings.total
            self.pendingCount   = stats.bookings.pending
            self.confirmedCount = stats.bookings.confirmed
            
        } catch {
            self.errorMessage = error.localizedDescription
            loadMockData()
        }
        isLoading = false
    }

    private func resolveArtistProfileId() async throws -> String? {
        return nil
    }

    private func loadMockData() {
        let calendar = Calendar.current
        let today = Date()
        todayBookings = [
            Booking(clientName: "María García", clientEmail: "maria@email.com", scheduledDate: today, duration: 60, totalPrice: 45, status: .confirmed),
            Booking(clientName: "Ana López", clientEmail: "ana@email.com", scheduledDate: calendar.date(byAdding: .hour, value: 2, to: today) ?? today, duration: 90, totalPrice: 65, status: .pending)
        ]
        pendingBookings = todayBookings.filter { $0.status == .pending }
        completedBookings = []
        monthlyEarnings = 0
        totalEarnings = 0
        totalBookings = 0
        pendingCount = pendingBookings.count
        confirmedCount = todayBookings.filter { $0.status == .confirmed }.count
    }

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "Q"
        formatter.maximumFractionDigits = 0
        return formatter
    }

    var formattedTotalEarnings: String {
        currencyFormatter.string(from: NSNumber(value: totalEarnings)) ?? "Q\(Int(totalEarnings))"
    }

    var formattedMonthlyEarnings: String {
        currencyFormatter.string(from: NSNumber(value: monthlyEarnings)) ?? "Q\(Int(monthlyEarnings))"
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
                endpoint: .artistBookings(status: nil, page: 1, artistId: nil),
                responseType: ArtistBookingsResponseDTO.self
            )
            
            self.bookings = response.bookings.map { $0.toDomainModel() }
            applyFilter()
            
        } catch {
            self.errorMessage = error.localizedDescription
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
            let endpoint: APIEndpoint
            let body: Data?
            
            switch status {
            case "CONFIRMED":
                endpoint = .acceptBooking(booking.remoteId)
                body = nil
            case "CANCELLED":
                endpoint = .declineBooking(booking.remoteId)
                let req = RejectBookingRequest(reason: "No disponibilidad en el horario solicitado", artistId: nil)
                body = try JSONEncoder().encode(AnyEncodable(req))
            case "COMPLETED":
                endpoint = .completeBooking(booking.remoteId)
                body = nil
            default:
                return
            }
            
            let _ = try await apiService.request(
                endpoint: endpoint,
                method: .PATCH,
                body: body,
                responseType: EmptyResponseDTO.self
            )
            
            if let index = bookings.firstIndex(where: { $0.id == booking.id }) {
                let newStatus: BookingStatus = {
                    switch status {
                    case "CONFIRMED": return .confirmed
                    case "CANCELLED": return .cancelled
                    case "COMPLETED": return .completed
                    default: return booking.status
                    }
                }()
                bookings[index].status = newStatus
                applyFilter()
            }
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolveArtistProfileId() async throws -> String? {
        let email = AuthService.shared.currentArtist?.email ?? extractEmailFromToken(APIService.shared.authToken)
        guard let email = email, !email.isEmpty else { return nil }
        
        let artistsResp = try await apiService.get(
            endpoint: .artists(page: 1, limit: 50, category: nil, location: nil),
            responseType: ArtistsSearchResponseDTO.self
        )
        return artistsResp.artists.first { $0.email?.lowercased() == email.lowercased() }?.id
    }

    private func extractEmailFromToken(_ token: String?) -> String? {
        guard let token = token else { return nil }
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var b64 = String(parts[1])
        let rem = b64.count % 4
        if rem > 0 { b64 += String(repeating: "=", count: 4 - rem) }
        b64 = b64.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: b64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["email"] as? String
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

    private func loadMockData() {
        let calendar = Calendar.current
        let today = Date()
        bookings = [
            Booking(clientName: "María García", clientEmail: "maria@email.com", scheduledDate: today, duration: 60, totalPrice: 45, status: .confirmed),
            Booking(clientName: "Ana López", clientEmail: "ana@email.com", scheduledDate: calendar.date(byAdding: .hour, value: 2, to: today) ?? today, duration: 90, totalPrice: 65, status: .pending)
        ]
        applyFilter()
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
            // Cargar perfil y stats en paralelo
            async let profileTask = apiService.get(
                endpoint: .artistDashboard,
                responseType: ArtistProfileResponseDTO.self
            )
            async let statsTask = apiService.get(
                endpoint: .artistStats,
                responseType: ArtistStatsResponseDTO.self
            )
            async let servicesTask = apiService.get(
                endpoint: .catalogServices(artistId: nil, category: nil),
                responseType: [ServiceDTO].self
            )
            
            let (profileResp, statsResp, servicesResp) = try await (profileTask, statsTask, servicesTask)
            
            let profile = profileResp.artist
            let stats = statsResp.stats
            
            // Convertir perfil a modelo local
            let currentArtist = AuthService.shared.currentArtist
            if let currentArtist = currentArtist {
                currentArtist.rating = profile.rating ?? 0
                currentArtist.totalReviews = profile.reviewsCount ?? 0
                currentArtist.isVerified = profile.isVerified ?? false
                if let bio = profile.bio { currentArtist.bio = bio }
            }
            self.artist = currentArtist ?? Artist(
                name: profile.displayName,
                email: "",
                profession: profile.category ?? "Artista",
                specialty: profile.specialties?.joined(separator: ", ") ?? "",
                bio: profile.bio ?? "",
                rating: profile.rating ?? 0,
                totalReviews: profile.reviewsCount ?? 0,
                isVerified: profile.isVerified ?? false
            )
            
            self.services = servicesResp.map { $0.toDomainModel() }
            
            self.statistics = ProfileStatistics(
                totalClients: stats.bookings.total,
                completedServices: stats.bookings.completed,
                monthlyEarnings: stats.revenue.thisMonth,
                averageRating: stats.rating.average
            )
            
        } catch {
            self.errorMessage = error.localizedDescription
            loadMockData()
        }
        
        isLoading = false
    }

    private func resolveArtistProfileId() async throws -> String? {
        return nil
    }

    private func extractEmailFromToken(_ token: String?) -> String? {
        guard let token = token else { return nil }
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var b64 = String(parts[1])
        let rem = b64.count % 4
        if rem > 0 { b64 += String(repeating: "=", count: 4 - rem) }
        b64 = b64.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        guard let data = Data(base64Encoded: b64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return json["email"] as? String
    }

    private func loadMockData() {
        artist = Artist.preview
        services = Service.previewServices
        statistics = ProfileStatistics(
            totalClients: 0,
            completedServices: 0,
            monthlyEarnings: 0,
            averageRating: artist?.rating ?? 0
        )
    }
}

// MARK: - AnyEncodable helper
struct AnyEncodable: Encodable {
    private let encodeFunc: (Encoder) throws -> Void
    init<T: Encodable>(_ value: T) { self.encodeFunc = value.encode }
    func encode(to encoder: Encoder) throws { try encodeFunc(encoder) }
}

// MARK: - Booking action DTOs
struct ConfirmBookingRequest: Codable {
    let artistNotes: String?
    let artistId: String?
}

struct RejectBookingRequest: Codable {
    let reason: String
    let artistId: String?
}
