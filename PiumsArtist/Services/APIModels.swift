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
    let role: String // CLIENT, ARTIST, ADMIN
    let phone: String?
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

// MARK: - Booking DTOs (estructura OpenAPI)
struct BookingDTO: Codable {
    let id: String
    let clientId: String?
    let artistId: String?
    let serviceId: String?
    let date: String?
    let time: String?
    let duration: Int?
    let location: BookingLocationDTO?
    let price: Double?
    let status: String?
    let paymentStatus: String?
    let confirmationCode: String?
    let notes: String?
    let rescheduledAt: String?
    let rescheduleReason: String?
    let rescheduleCount: Int?
    let createdAt: String?
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

struct RespondToReviewRequest: Codable {
    let response: String
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
struct ConversationDTO: Codable {
    let id: String
    let participants: [String]
    let lastMessage: MessageDTO?
    let unreadCount: Int
    let createdAt: String
    let updatedAt: String
}

struct MessageDTO: Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let type: String // TEXT, IMAGE, FILE
    let read: Bool
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

// MARK: - Health Check DTO
struct HealthCheckDTO: Codable {
    let status: String
    let timestamp: String
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
        let scheduledAt: Date = {
            guard let date = date, let time = time else { return Date() }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.current
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            return formatter.date(from: "\(date) \(time)") ?? Date()
        }()
        let statusValue = (status ?? "").uppercased()
        let bookingStatus: BookingStatus = {
            switch statusValue {
            case "PENDING": return .pending
            case "CONFIRMED": return .confirmed
            case "COMPLETED": return .completed
            case "CANCELLED": return .cancelled
            case "RESCHEDULED": return .pending
            default: return .pending
            }
        }()

        let total = price ?? 0

        return Booking(
            remoteId: id,
            clientName: "Cliente",
            clientEmail: "",
            clientPhone: "",
            scheduledDate: scheduledAt,
            duration: duration ?? 60,
            totalPrice: total,
            notes: notes ?? "",
            status: bookingStatus
        )
    }
}

extension ServiceDTO {
    func toDomainModel() -> Service {
        return Service(
            name: name,
            description: description ?? "",
            duration: durationMin ?? 60,
            price: priceDecimal,
            category: category?.name ?? categoryId ?? "General",
            isActive: status == "ACTIVE" || isAvailable == true
        )
    }
}

extension ConversationDTO {
    func toDomainModel() -> MessagesViewModel.ConversationItem {
        let lastMessageText = lastMessage?.content ?? ""
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.date(from: updatedAt) ?? Date()
        
        return MessagesViewModel.ConversationItem(
            clientName: "Client", // Would need separate API call to get client details
            clientEmail: "",
            lastMessage: lastMessageText,
            timestamp: timestamp,
            unreadCount: unreadCount,
            isOnline: false, // Not available in new API
            messages: []
        )
    }
}

extension MessageDTO {
    func toDomainModel() -> MessagesViewModel.MessageItem {
        let dateFormatter = ISO8601DateFormatter()
        let timestamp = dateFormatter.date(from: createdAt) ?? Date()
        
        return MessagesViewModel.MessageItem(
            content: content,
            isFromArtist: false, // Would need to check against current user ID
            timestamp: timestamp,
            isRead: read
        )
    }
}

extension ArtistDashboardDTO {
    func toDashboardStats() -> (BookingStatsDTO, RevenueStatsDTO, RatingStatsDTO) {
        return (bookings, revenue, rating)
    }
}
