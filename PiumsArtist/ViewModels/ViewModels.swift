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
        }
        isLoading = false
    }

    private func resolveArtistProfileId() async throws -> String? {
        return nil
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
        defer { isLoading = false }

        guard let url = URL(string: APIConfig.currentURL + APIEndpoint.artistBookings(status: nil, page: 1, artistId: nil).path) else {
            errorMessage = "URL inválida"; return
        }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = APIService.shared.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: req)

            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 {
                    errorMessage = "Sesión expirada. Vuelve a iniciar sesión."; return
                }
                if http.statusCode >= 400 {
                    errorMessage = "Error del servidor (\(http.statusCode))"; return
                }
            }

            let decoder = JSONDecoder()
            if let wrapped = try? decoder.decode(ArtistBookingsResponseDTO.self, from: data) {
                self.bookings = wrapped.bookings.map { $0.toDomainModel() }
                applyFilter(); return
            }
            if let dtos = try? decoder.decode([BookingDTO].self, from: data) {
                self.bookings = dtos.map { $0.toDomainModel() }
                applyFilter(); return
            }

            errorMessage = "Respuesta inesperada del servidor."

        } catch {
            errorMessage = error.localizedDescription
        }
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

}

// MARK: - Calendar ViewModel
@MainActor
final class CalendarViewModel: ObservableObject {
    @Published var selectedDate = Date()
    @Published var currentMonth = Date()
    @Published var availability: [Date: [TimeSlot]] = [:]
    @Published var blockedSlotIds: [Date: String] = [:]
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
        Task { await refreshDataAsync() }
    }

    func refreshData() {
        Task { await refreshDataAsync() }
    }

    @MainActor
    func refreshDataAsync() async {
        isLoading = true
        loadMockAvailability()          // base de disponibilidad inicial
        await loadBlockedSlots()        // superpone bloques reales del backend
        isLoading = false
    }
    
    func updateSelectedDate(_ date: Date) {
        selectedDate = date
    }
    
    @MainActor
    func blockTimeSlot(date: Date, reason: String) async {
        guard let artistId = AuthService.shared.artistBackendId else { return }
        isLoading = true

        // El backend almacena rangos — bloqueamos el día completo (00:00 → 23:59:59)
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: date)
        let dayEnd = cal.date(bySettingHour: 23, minute: 59, second: 59, of: dayStart) ?? dayStart

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]

        let body = CreateBlockedSlotRequest(
            artistId: artistId,
            startTime: iso.string(from: dayStart),
            endTime: iso.string(from: dayEnd),
            reason: reason.isEmpty ? nil : reason,
            isRecurring: false
        )

        do {
            let _ = try await APIService.shared.post(
                endpoint: .createBlockedSlot,
                body: body,
                responseType: BlockedSlotDTO.self
            )
            await loadBlockedSlots()
        } catch { }
        isLoading = false
    }

    @MainActor
    func unblockSlot(slotId: String) async {
        isLoading = true
        do {
            let _ = try await APIService.shared.request(
                endpoint: .deleteBlockedSlot(slotId),
                method: .DELETE,
                responseType: EmptyResponseDTO.self
            )
            await loadBlockedSlots()
        } catch { }
        isLoading = false
    }

    @MainActor
    private func loadBlockedSlots() async {
        guard let artistId = AuthService.shared.artistBackendId else { return }

        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoBasic = ISO8601DateFormatter()
        let cal = Calendar.current
        blockedSlotIds = [:]

        do {
            let slots = try await APIService.shared.get(
                endpoint: .getBlockedSlots(artistId: artistId),
                responseType: [BlockedSlotDTO].self
            )

            for slot in slots {
                guard let start = isoFull.date(from: slot.startTime)
                                ?? isoBasic.date(from: slot.startTime),
                      let end   = isoFull.date(from: slot.endTime)
                                ?? isoBasic.date(from: slot.endTime)
                else { continue }

                var current = cal.startOfDay(for: start)
                while current <= cal.startOfDay(for: end) {
                    blockedSlotIds[current] = slot.id
                    if let existing = availability[current] {
                        availability[current] = existing.map {
                            TimeSlot(time: $0.time, isAvailable: false, isBooked: $0.isBooked)
                        }
                    } else {
                        availability[current] = defaultSlots(for: current, blocked: true)
                    }
                    current = cal.date(byAdding: .day, value: 1, to: current) ?? current
                }
            }
        } catch { }
    }

    func unblockSelectedDay() async {
        let dayStart = Calendar.current.startOfDay(for: selectedDate)
        guard let slotId = blockedSlotIds[dayStart] else { return }
        await unblockSlot(slotId: slotId)
    }

    private func defaultSlots(for date: Date, blocked: Bool) -> [TimeSlot] {
        ["9:00 AM","10:30 AM","12:00 PM","2:00 PM","3:30 PM","5:00 PM"].map {
            TimeSlot(time: $0, isAvailable: !blocked, isBooked: false)
        }
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
        for i in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: i, to: today) {
                let dayStart = calendar.startOfDay(for: date)
                availability[dayStart] = defaultSlots(for: dayStart, blocked: false)
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
        /// Real backend conversation ID (string)
        let conversationId: String
        /// Stable UUID derived from conversationId — avoids re-rendering on refresh
        let stableId: UUID
        var id: UUID { stableId }

        let clientName: String
        let clientEmail: String
        let lastMessage: String
        let timestamp: Date
        let unreadCount: Int
        let isOnline: Bool
        var status: String       // ACTIVE, PENDING, CLOSED
        var messages: [MessageItem]
    }

    struct MessageItem: Identifiable {
        let id: UUID
        let content: String
        let isFromArtist: Bool
        let timestamp: Date
        let isRead: Bool

        init(content: String, isFromArtist: Bool, timestamp: Date, isRead: Bool) {
            self.id = UUID()
            self.content = content
            self.isFromArtist = isFromArtist
            self.timestamp = timestamp
            self.isRead = isRead
        }
    }

    private var modelContext: ModelContext?
    private let apiService = APIService.shared

    init() {
        Task { await loadConversations() }
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        Task { await refreshData() }
    }

    func refreshData() async { await loadConversations() }


    // MARK: - Load conversations

    @MainActor
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        // Hacemos la petición cruda para poder loggear la respuesta y diagnosticar
        guard let url = URL(string: APIConfig.currentURL + APIEndpoint.conversations.path) else {
            errorMessage = "URL inválida"
            return
        }
        var req = URLRequest(url: url)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = APIService.shared.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: req)

            if let http = response as? HTTPURLResponse {
                if http.statusCode == 401 {
                    self.errorMessage = "Sesión expirada. Vuelve a iniciar sesión."
                    return
                }
                if http.statusCode >= 400 {
                    self.errorMessage = "Error del servidor (\(http.statusCode))"
                    return
                }
            }

            let decoder = JSONDecoder()

            if let wrapped = try? decoder.decode(ConversationsResponseDTO.self, from: data) {
                self.conversations = wrapped.conversations.map { $0.toDomainModel() }
                filterConversations()
                return
            }

            if let dtos = try? decoder.decode([ConversationDTO].self, from: data) {
                self.conversations = dtos.map { $0.toDomainModel() }
                filterConversations()
                return
            }

            self.errorMessage = "Respuesta inesperada del servidor."

        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load messages for a conversation

    /// Fetches the message history for `conversationId` from the backend.
    func loadMessages(for conversationId: String) async -> [MessageItem] {
        var messages: [MessageItem] = []
        do {
            if let wrapped = try? await apiService.get(
                endpoint: .conversationMessages(conversationId, page: nil),
                responseType: MessagesResponseDTO.self
            ) {
                messages = wrapped.messages.map { $0.toDomainModel() }
            } else {
                let dtos = try await apiService.get(
                    endpoint: .conversationMessages(conversationId, page: nil),
                    responseType: [MessageDTO].self
                )
                messages = dtos.map { $0.toDomainModel() }
            }
        } catch { }
        // Marcar conversación como leída (igual que hace el cliente)
        try? await apiService.request(
            endpoint: .markConversationRead(conversationId),
            method: .PATCH,
            responseType: EmptyResponseDTO.self
        )
        // Actualizar unreadCount a 0 en la lista local
        if let idx = conversations.firstIndex(where: { $0.conversationId == conversationId }) {
            let c = conversations[idx]
            conversations[idx] = ConversationItem(
                conversationId: c.conversationId,
                stableId: c.stableId,
                clientName: c.clientName,
                clientEmail: c.clientEmail,
                lastMessage: c.lastMessage,
                timestamp: c.timestamp,
                unreadCount: 0,
                isOnline: c.isOnline,
                status: c.status,
                messages: c.messages
            )
        }
        return messages
    }

    // MARK: - Send message

    func sendMessage(_ content: String, conversationId: String) {
        Task { await sendMessageAPI(content, conversationId: conversationId) }
    }

    @MainActor
    private func sendMessageAPI(_ content: String, conversationId: String) async {
        let request = SendMessageRequest(conversationId: conversationId, content: content, type: "TEXT")
        do {
            let response = try await apiService.post(
                endpoint: .sendMessage,
                body: request,
                responseType: MessageDTO.self
            )
            let newMessage = response.toDomainModel()
            if let index = conversations.firstIndex(where: { $0.conversationId == conversationId }) {
                conversations[index].messages.append(newMessage)
                filterConversations()
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Search

    func updateSearchText(_ text: String) {
        searchText = text
        filterConversations()
    }

    private func filterConversations() {
        if searchText.isEmpty {
            filteredConversations = conversations
        } else {
            filteredConversations = conversations.filter {
                $0.clientName.localizedCaseInsensitiveContains(searchText) ||
                $0.lastMessage.localizedCaseInsensitiveContains(searchText)
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
            // 1. Cargar perfil del artista
            let profileResp = try await apiService.get(
                endpoint: .artistDashboard,
                responseType: ArtistProfileResponseDTO.self
            )
            let profile = profileResp.artist

            // Persistir el artistId del backend para que otros ViewModels lo usen sin llamadas extra
            AuthService.shared.artistBackendId = profile.id

            // 2. Cargar stats en paralelo con los servicios del artista
            async let statsTask = apiService.get(
                endpoint: .artistStats,
                responseType: ArtistStatsResponseDTO.self
            )
            async let servicesTask = apiService.get(
                endpoint: .catalogServices(artistId: profile.id, category: nil),
                responseType: ServicesResponseDTO.self
            )
            
            let (statsResp, servicesResp) = try await (statsTask, servicesTask)
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
                email: profile.email ?? "",
                profession: profile.category ?? "Artista",
                specialty: profile.specialties?.joined(separator: ", ") ?? "",
                bio: profile.bio ?? "",
                rating: profile.rating ?? 0,
                totalReviews: profile.reviewsCount ?? 0,
                isVerified: profile.isVerified ?? false
            )
            
            self.services = servicesResp.services.map { $0.toDomainModel() }
            
            self.statistics = ProfileStatistics(
                totalClients: stats.bookings.total,
                completedServices: stats.bookings.completed,
                monthlyEarnings: stats.revenue.thisMonth,
                averageRating: stats.rating.average
            )
            
        } catch {
            self.errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func resolveArtistProfileId() async throws -> String? {
        return nil
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
