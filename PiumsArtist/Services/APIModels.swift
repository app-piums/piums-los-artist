//
//  APIModels.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import Foundation

// MARK: - Authentication DTOs
struct RegisterRequest: Codable {
    let email: String
    let password: String
    let name: String
    let role: String
    let phone: String?

    // Send both "name" and "nombre" because backend may use either field
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(email, forKey: .email)
        try c.encode(password, forKey: .password)
        try c.encode(name, forKey: .name)
        try c.encode(name, forKey: .nombre)
        try c.encode(role, forKey: .role)
        try c.encodeIfPresent(phone, forKey: .phone)
    }

    init(email: String, password: String, name: String, role: String, phone: String?) {
        self.email = email; self.password = password; self.name = name
        self.role = role; self.phone = phone
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        email    = try c.decode(String.self, forKey: .email)
        password = try c.decode(String.self, forKey: .password)
        let rawName = (try? c.decode(String.self, forKey: .name)) ?? (try? c.decode(String.self, forKey: .nombre)) ?? ""
        name = rawName
        role     = try c.decode(String.self, forKey: .role)
        phone    = try c.decodeIfPresent(String.self, forKey: .phone)
    }

    enum CodingKeys: String, CodingKey {
        case email, password, name, nombre, role, phone
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct AuthResponse: Codable {
    let success: Bool?
    let token: String
    let refreshToken: String?
    let user: UserDTO
    let expiresIn: String?
    let message: String?
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

// MARK: - User DTOs
struct UserDTO: Codable {
    let id: String
    let email: String
    // Backend puede enviar "nombre" o "name"
    let nombre: String?
    let name: String?
    let role: String
    let avatar: String?
    let phone: String?
    let emailVerified: Bool?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    
    // Helper para obtener el nombre sin importar qué campo use el backend
    var displayName: String {
        nombre ?? name ?? email
    }
}

struct UpdateUserRequest: Codable {
    let name: String?
    let phone: String?
    let bio: String?
    let location: String?
}

struct NotificationSettingsDTO: Codable {
    let emailNotifications: Bool
    let smsNotifications: Bool
    let pushNotifications: Bool
}

// MARK: - Artist DTOs
struct ArtistDTO: Codable {
    let id: String
    let userId: String
    let stageName: String
    let bio: String
    let specialties: [String]
    let location: LocationDTO?
    let rating: Double
    let reviewCount: Int
    let verified: Bool
    let portfolio: [String]
    let socialLinks: SocialLinksDTO?
    let createdAt: String
}

struct LocationDTO: Codable {
    let city: String
    let country: String
    let coordinates: CoordinatesDTO?
}

struct CoordinatesDTO: Codable {
    let lat: Double
    let lng: Double
}

struct SocialLinksDTO: Codable {
    let instagram: String?
    let youtube: String?
    let tiktok: String?
}

struct CreateArtistRequest: Codable {
    let stageName: String
    let bio: String
    let specialties: [String]
    let location: LocationDTO?
}

struct ArtistDashboardDTO: Codable {
    let bookings: BookingStatsDTO
    let revenue: RevenueStatsDTO
    let rating: RatingStatsDTO
}

struct BookingStatsDTO: Codable {
    let total: Int
    let pending: Int
    let confirmed: Int
}

struct RevenueStatsDTO: Codable {
    let total: Double
    let thisMonth: Double
    let currency: String
}

struct RatingStatsDTO: Codable {
    let average: Double
    let count: Int
}

// MARK: - Service DTOs  (estructura real de /catalog/services)
struct ServiceDTO: Codable {
    let id: String
    let artistId: String
    let name: String            // backend usa "name" no "title"
    let slug: String?
    let description: String?
    let categoryId: String?
    let cityId: String?
    let pricingType: String?    // FIXED, HOURLY, etc.
    let basePrice: Int?         // Cambiado a Int? (centavos)
    let currency: String?
    let durationMin: Int?
    let durationMax: Int?
    let thumbnail: String?
    let images: [String]?
    let status: String?         // ACTIVE, INACTIVE, DRAFT
    let isAvailable: Bool?
    let isFeatured: Bool?
    let bookingCount: Int?
    let viewCount: Int?
    let createdAt: String?
    let updatedAt: String?
    // Nested
    let category: ServiceCategoryDTO?
    
    // Compat: title → name
    var title: String { name }
    var priceDecimal: Double { Double(basePrice ?? 0) / 100.0 } // Helper para precio en formato decimal
    var active: Bool { status == "ACTIVE" || isAvailable == true }
    var duration: Int { durationMin ?? 60 }
}

struct ServiceCategoryDTO: Codable {
    let id: String?
    let name: String?
    let slug: String?
}

// MARK: - Booking DTOs (estructura real del SDK/backend)
struct BookingDTO: Codable {
    let id: String
    let code: String?
    let clientId: String?
    let artistId: String?
    let serviceId: String?
    let scheduledDate: String?   // ISO string — fecha original
    let startAt: String?         // ISO string — startAt (puede diferir de scheduledDate)
    let endAt: String?
    let durationMinutes: Int?
    let location: String?
    let locationLat: Double?
    let locationLng: Double?
    let status: String?
    let servicePrice: Int?       // centavos
    let addonsPrice: Int?        // centavos
    let totalPrice: Int?         // centavos
    let currency: String?
    let paymentStatus: String?
    let depositRequired: Bool?
    let depositAmount: Int?
    let selectedAddons: [String]?
    let clientNotes: String?
    let artistNotes: String?
    let cancellationReason: String?
    let serviceName: String?     // nombre del servicio reservado
    let artistName: String?
    let createdAt: String?
    let updatedAt: String?
}

// Respuesta de /artists/dashboard/me/bookings
struct ArtistBookingsResponseDTO: Codable {
    let bookings: [BookingDTO]
    let total: Int
    let page: Int
    let totalPages: Int
    let artistId: String?
}

// Respuesta de /artists/dashboard/me/stats
struct ArtistStatsResponseDTO: Codable {
    let stats: ArtistStatsDTO
}

struct ArtistStatsDTO: Codable {
    let artistId: String?
    let bookings: ArtistBookingStatsDTO
    let revenue: ArtistRevenueStatsDTO
    let rating: ArtistRatingStatsDTO
    let upcomingBookings: [BookingDTO]?
}

struct ArtistBookingStatsDTO: Codable {
    let total: Int
    let thisMonth: Int
    let pending: Int
    let confirmed: Int
    let completed: Int
}

struct ArtistRevenueStatsDTO: Codable {
    let total: Double
    let thisMonth: Double
    let currency: String
}

struct ArtistRatingStatsDTO: Codable {
    let average: Double
    let totalReviews: Int
}

// Respuesta de /artists/dashboard/me
struct ArtistProfileResponseDTO: Codable {
    let artist: ArtistProfileDTO
}

struct ArtistProfileDTO: Codable {
    let id: String
    let authId: String?        // ← campo real del backend (antes "userId")
    let userId: String?        // alias por si algún endpoint lo devuelve así
    let email: String?
    let nombre: String?
    let artistName: String?
    let slug: String?
    let bio: String?
    let avatar: String?
    let coverPhoto: String?
    let category: String?
    let categoryId: String?
    let specialties: [String]?
    let cityId: String?
    let city: String?
    let country: String?
    let yearsExperience: Int?  // ← campo real del backend (antes "experienceYears")
    let experienceYears: Int?  // alias por si algún endpoint lo devuelve así
    let reviewsCount: Int?
    let bookingsCount: Int?
    let isVerified: Bool?
    let isActive: Bool?
    let rating: Double?
    let imageUrl: String?
    let baseLocationLabel: String?
    let baseLocationLat: Double?
    let baseLocationLng: Double?
    let coverageRadius: Int?
    let currency: String?
    let socialLinks: SocialLinksDTO?

    var displayName: String { artistName ?? nombre ?? "Artista" }
    var resolvedExperienceYears: Int { yearsExperience ?? experienceYears ?? 0 }
    var resolvedAuthId: String? { authId ?? userId }
}

struct BookingLocationDTO: Codable {
    let address: String?
    let city: String?
    let postalCode: String?
    let coordinates: CoordinatesDTO?
}

// Estas DTOs se conservan por compatibilidad si el backend las expone en el futuro
struct BookingClientDTO: Codable {
    let id: String?
    let nombre: String?
    let name: String?
    let email: String?
    var displayName: String { nombre ?? name ?? email ?? "Cliente" }
}

struct BookingServiceDTO: Codable {
    let id: String?
    let name: String?
    let basePrice: Int?
}

struct CreateBookingRequest: Codable {
    let artistId: String
    let serviceId: String
    let date: String
    let time: String
    let location: BookingLocationDTO
    let notes: String?
}

struct RescheduleBookingRequest: Codable {
    let newDate: String
    let newTime: String
    let reason: String?
}

// MARK: - Payment DTOs
struct PaymentMethodDTO: Codable {
    let id: String
    let userId: String
    let type: String // CARD, PAYPAL, BANK_TRANSFER
    let last4: String?
    let brand: String?
    let expiryMonth: Int?
    let expiryYear: Int?
    let isDefault: Bool
    let stripePaymentMethodId: String?
    let createdAt: String
}

struct AddPaymentMethodRequest: Codable {
    let stripePaymentMethodId: String
    let setAsDefault: Bool?
}

struct PaymentDTO: Codable {
    let id: String
    let bookingId: String
    let amount: Double
    let currency: String
    let status: String // PENDING, PROCESSING, COMPLETED, FAILED, REFUNDED
    let paymentMethodId: String
    let stripePaymentIntentId: String?
    let createdAt: String
}

struct ProcessPaymentRequest: Codable {
    let bookingId: String
    let paymentMethodId: String
}

// MARK: - Review DTOs
struct ReviewDTO: Codable {
    let id: String
    let bookingId: String
    let artistId: String
    let clientId: String
    let rating: Int // 1-5
    let comment: String?
    let response: String?
    let images: [String]?
    let helpful: Int
    let createdAt: String
}

struct CreateReviewRequest: Codable {
    let bookingId: String
    let rating: Int
    let comment: String?
    let images: [String]?
}

// MARK: - Notification DTOs
struct NotificationDTO: Codable {
    let id: String
    let userId: String
    let type: String // BOOKING_CONFIRMED, BOOKING_CANCELLED, PAYMENT_RECEIVED, REVIEW_RECEIVED, MESSAGE_RECEIVED
    let title: String
    let message: String
    let read: Bool
    let data: [String: String]?
    let createdAt: String
}

// MARK: - Chat DTOs
/// Estructura real del chat-service (GET /chat/conversations)
struct ConversationDTO: Codable {
    let id: String
    let userId: String?        // ID del cliente
    let artistId: String?      // ID del artista
    let bookingId: String?
    let status: String?        // PENDING, ACTIVE, CLOSED
    let lastMessageAt: String? // ISO timestamp del último mensaje
    let unreadCount: Int?      // Opcional — puede venir null o faltar
    let createdAt: String?     // Opcional por seguridad
    let updatedAt: String?     // Opcional por seguridad
    // messages[] viene vacío en el listado — se carga por separado
}

struct MessageDTO: Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let senderType: String?  // "artist" | "user" | "client"
    let content: String
    let type: String?        // TEXT, IMAGE, FILE
    let read: Bool?
    let readAt: String?
    let createdAt: String
}

struct CreateConversationRequest: Codable {
    let participantId: String
}

struct SendMessageRequest: Codable {
    let conversationId: String
    let content: String
    let type: String? // defaults to TEXT
}

// MARK: - Search DTOs
struct SearchFiltersDTO: Codable {
    let query: String?
    let category: String?
    let location: String?
    let priceMin: Double?
    let priceMax: Double?
    let rating: Double?
    let availability: String?
    let sort: String? // relevance, price_asc, price_desc, rating, reviews
    let page: Int?
    let limit: Int?
}

// MARK: - Common DTOs
struct PaginatedResponseDTO<T: Codable>: Codable {
    let data: [T]
    let pagination: PaginationDTO
}

// Respuestas reales del backend (usan nombres de campo específicos)
struct BookingsResponseDTO: Codable {
    let bookings: [BookingDTO]
    let pagination: PaginationBackendDTO
}

struct ServicesResponseDTO: Codable {
    let services: [ServiceDTO]
    let pagination: PaginationBackendDTO
}

struct ArtistsSearchResponseDTO: Codable {
    let artists: [ArtistSearchDTO]
    let pagination: PaginationBackendDTO
}

struct ArtistSearchDTO: Codable {
    let id: String
    let name: String?
    let email: String?
    let bio: String?
    let specialties: [String]?
    let city: String?
    let state: String?
    let country: String?
    let averageRating: Double?
    let totalReviews: Int?
    let totalBookings: Int?
    let isVerified: Bool?
    let isActive: Bool?
    let mainServicePrice: Double?
    let mainServiceName: String?
}

struct PaginationDTO: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let pages: Int
}

struct PaginationBackendDTO: Codable {
    let page: Int
    let limit: Int
    let total: Int
    // Backend usa "totalPages" o "pages"
    let totalPages: Int?
    let pages: Int?
    var pageCount: Int { totalPages ?? pages ?? 1 }
}

struct ErrorResponseDTO: Codable {
    let error: String
    let message: String
    let details: [ErrorDetailDTO]?
}

struct ErrorDetailDTO: Codable {
    let field: String?
    let message: String
}

struct SuccessResponseDTO: Codable {
    let status: String
    let message: String?
}

struct EmptyResponseDTO: Codable {
    let message: String?
    let bookingId: String?
}

// MARK: - Health Check DTO
struct HealthCheckDTO: Codable {
    let status: String
    let timestamp: String
}

// MARK: - Auth Me / Verification DTOs

struct AuthMeDTO: Codable {
    let id: String?
    let nombre: String?
    let email: String?
    let emailVerified: Bool?
    let role: String?
    let status: String?
    let avatar: String?
    let ciudad: String?
    let birthDate: String?
    let documentType: String?
    let documentNumber: String?
    let documentFrontUrl: String?
    let documentBackUrl: String?
    let documentSelfieUrl: String?
}

struct DocumentUploadResponse: Codable {
    let url: String
}

// MARK: - Extensions for Conversion to Domain Models

extension UserDTO {
    func toDomainModel() -> Artist {
        return Artist(
            name: displayName,
            email: email,
            phone: phone ?? "",
            profession: "Artist",
            specialty: "General",
            bio: "",
            rating: 0.0,
            totalReviews: 0,
            yearsOfExperience: 0,
            isVerified: emailVerified ?? false
        )
    }
}

extension ArtistSearchDTO {
    func toDomainModel() -> Artist {
        Artist(
            name: name ?? email ?? "Artista",
            email: email ?? "",
            phone: "",
            profession: specialties?.first ?? "Artist",
            specialty: specialties?.joined(separator: ", ") ?? "",
            bio: bio ?? "",
            rating: averageRating ?? 0,
            totalReviews: totalReviews ?? 0,
            yearsOfExperience: 0,
            isVerified: isVerified ?? false
        )
    }
}

extension BookingDTO {
    func toDomainModel() -> Booking {
        // Usar startAt preferiblemente, si no scheduledDate
        let dateString = startAt ?? scheduledDate ?? ""
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let scheduledAt = isoFormatter.date(from: dateString)
            ?? ISO8601DateFormatter().date(from: dateString)
            ?? Date()

        let statusValue = (status ?? "").uppercased()
        let bookingStatus: BookingStatus = {
            switch statusValue {
            case "PENDING": return .pending
            case "CONFIRMED": return .confirmed
            case "IN_PROGRESS": return .inProgress
            case "COMPLETED": return .completed
            case "CANCELLED", "CANCELLED_CLIENT", "CANCELLED_ARTIST", "REJECTED": return .cancelled
            case "NO_SHOW": return .noShow
            default: return .pending
            }
        }()

        // totalPrice viene en centavos
        let total = Double(totalPrice ?? 0) / 100.0

        return Booking(
            remoteId: id,
            clientName: serviceName ?? code ?? "Cliente",
            clientEmail: clientNotes ?? "",
            clientPhone: "",
            scheduledDate: scheduledAt,
            duration: durationMinutes ?? 60,
            totalPrice: total,
            notes: clientNotes ?? artistNotes ?? "",
            status: bookingStatus,
            serviceName: serviceName,
            bookingCode: code
        )
    }
}

extension ServiceDTO {
    func toDomainModel() -> Service {
        return Service(
            remoteId: id,
            name: name,
            description: description ?? "",
            duration: durationMin ?? 60,
            price: priceDecimal,
            category: category?.name ?? categoryId ?? "General",
            categoryId: categoryId ?? "",
            slug: slug ?? "",
            isActive: status == "ACTIVE" || isAvailable == true,
            pricingType: pricingType ?? "FIXED"
        )
    }
}

extension ConversationDTO {
    func toDomainModel() -> MessagesViewModel.ConversationItem {
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoBasic = ISO8601DateFormatter()

        // Usar lastMessageAt → updatedAt → ahora como fallback
        let timestampStr = lastMessageAt ?? updatedAt ?? ""
        let timestamp = isoFull.date(from: timestampStr)
            ?? isoBasic.date(from: timestampStr)
            ?? Date()

        // Stable UUID para SwiftUI identity
        let stableId = UUID(uuidString: id) ?? UUID()

        // El "otro" participante es el cliente (userId)
        let clientId = userId ?? ""
        let clientName = clientId.isEmpty
            ? "Conversación"
            : "Cliente ···\(String(clientId.suffix(6)))"

        return MessagesViewModel.ConversationItem(
            conversationId: id,
            stableId: stableId,
            clientName: clientName,
            clientEmail: "",
            lastMessage: "",  // se carga al abrir el chat
            timestamp: timestamp,
            unreadCount: unreadCount ?? 0,
            isOnline: false,
            status: status ?? "ACTIVE",
            messages: []
        )
    }
}

extension MessageDTO {
    func toDomainModel() -> MessagesViewModel.MessageItem {
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let timestamp = isoFull.date(from: createdAt)
            ?? ISO8601DateFormatter().date(from: createdAt)
            ?? Date()
        // Usar senderType si está disponible; fallback a comparar senderId con JWT
        let isArtist: Bool
        if let st = senderType {
            isArtist = (st == "artist")
        } else {
            let currentUserId = AuthService.shared.currentUserId ?? ""
            isArtist = !currentUserId.isEmpty && senderId == currentUserId
        }
        return MessagesViewModel.MessageItem(
            content: content,
            isFromArtist: isArtist,
            timestamp: timestamp,
            isRead: read ?? false
        )
    }
}

// MARK: - Messages list response DTO
/// Backend may return messages directly as array or wrapped in { "messages": [...] }
struct MessagesResponseDTO: Codable {
    let messages: [MessageDTO]
}

extension ArtistDashboardDTO {
    func toDashboardStats() -> (BookingStatsDTO, RevenueStatsDTO, RatingStatsDTO) {
        return (bookings, revenue, rating)
    }
}

// MARK: - Blocked Slots DTOs
/// Estructura real del booking-service (POST /blocked-slots / GET /artists/:id/blocked-slots)
struct BlockedSlotDTO: Codable {
    let id: String
    let artistId: String?
    let startTime: String    // ISO8601 datetime
    let endTime: String      // ISO8601 datetime
    let reason: String?
    let isRecurring: Bool?
    let createdAt: String?
}

/// El backend devuelve el array directamente, sin wrapper.
/// Este alias queda para compatibilidad con código existente que espera BlockedSlotsResponseDTO.
struct BlockedSlotsResponseDTO: Codable {
    // Wrapper vacío — en la práctica se decodifica como [BlockedSlotDTO] directamente.
    // Ver CalendarViewModel.loadBlockedSlots()
    let blockedSlots: [BlockedSlotDTO]
}

struct CreateBlockedSlotRequest: Codable {
    let artistId: String
    let startTime: String    // ISO8601 datetime — inicio del bloqueo (00:00:00 del día)
    let endTime: String      // ISO8601 datetime — fin del bloqueo (23:59:59 del día)
    let reason: String?
    let isRecurring: Bool?
}

// MARK: - Create / Update Service Request
struct CreateServiceRequest: Codable {
    let artistId: String     // ID del perfil de artista en el backend
    let name: String
    let slug: String         // slug único generado del nombre (minúsculas, sin espacios)
    let description: String  // mínimo 10 caracteres — requerido por el backend
    let categoryId: String   // UUID de la categoría seleccionada
    let pricingType: String  // FIXED | HOURLY | PER_SESSION | CUSTOM
    let basePrice: Int       // centavos
    let currency: String?
    let durationMin: Int?
}

struct UpdateServiceRequest: Codable {
    let artistId: String
    let name: String
    let slug: String
    let description: String
    let categoryId: String
    let pricingType: String
    let basePrice: Int
    let currency: String?
    let durationMin: Int?
}

// MARK: - Service Categories DTOs
struct ServiceCategoryItemDTO: Codable {
    let id: String
    let name: String
    let slug: String?
    let description: String?
    let icon: String?
    let isActive: Bool?
    let subcategories: [ServiceCategoryItemDTO]?
}

typealias ServiceCategoriesResponseDTO = [ServiceCategoryItemDTO]

// MARK: - Conversations wrapper (backend puede envolver en objeto)
struct ConversationsResponseDTO: Codable {
    let conversations: [ConversationDTO]
}

// MARK: - Reviews DTOs
struct ReviewDetailedDTO: Codable {
    let id: String
    let bookingId: String?
    let artistId: String?
    let clientId: String?
    let rating: Int            // 1-5
    let comment: String?
    let status: String?        // PUBLISHED, PENDING, HIDDEN
    let response: ReviewResponseDTO?
    let photos: [ReviewPhotoDTO]?
    let createdAt: String
    let updatedAt: String?
}

struct ReviewResponseDTO: Codable {
    let id: String?
    let message: String
    let createdAt: String
}

struct ReviewPhotoDTO: Codable {
    let id: String
    let url: String
    let caption: String?
}

struct ReviewsListPaginationDTO: Codable {
    let page: Int
    let limit: Int?
    let total: Int
    let totalPages: Int
}

struct ReviewsListResponseDTO: Codable {
    let reviews: [ReviewDetailedDTO]
    let pagination: ReviewsListPaginationDTO?
    // Legacy flat fields (in case backend shape changes)
    private let _total: Int?
    private let _page: Int?
    private let _totalPages: Int?

    var total: Int { pagination?.total ?? _total ?? 0 }
    var page: Int { pagination?.page ?? _page ?? 1 }
    var totalPages: Int { pagination?.totalPages ?? _totalPages ?? 1 }

    enum CodingKeys: String, CodingKey {
        case reviews, pagination
        case _total = "total"
        case _page = "page"
        case _totalPages = "totalPages"
    }
}

struct RespondToReviewRequest: Codable {
    let message: String
}

struct ReportReviewRequest: Codable {
    let reason: String
    let description: String
}

// MARK: - Disputes DTOs
struct DisputeDTO: Codable {
    let id: String
    let bookingId: String?
    let disputeType: String   // CANCELLATION, QUALITY, REFUND, NO_SHOW, ARTIST_NO_SHOW, PRICING, BEHAVIOR, OTHER
    let status: String        // OPEN, IN_REVIEW, AWAITING_INFO, RESOLVED, CLOSED, ESCALATED
    let subject: String
    let description: String?
    let messages: [DisputeMessageDTO]?
    let createdAt: String
    let updatedAt: String?
}

struct DisputeMessageDTO: Codable {
    let id: String?
    let disputeId: String?
    let senderType: String?   // artist, client, staff
    let message: String
    let isStatusUpdate: Bool?
    let createdAt: String
}

struct MyDisputesResponseDTO: Codable {
    let asReporter: [DisputeDTO]?
    let asReported: [DisputeDTO]?
    let total: Int?
}

struct AddDisputeMessageRequest: Codable {
    let message: String
}

struct CreateDisputeRequest: Codable {
    let bookingId: String
    let disputeType: String
    let subject: String
    let description: String
}
