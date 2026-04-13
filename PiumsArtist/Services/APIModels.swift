//
//  APIModels.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import Foundation

// MARK: - Authentication DTOs
struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let refreshToken: String
    let expiresIn: Int
    let artist: ArtistDTO
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
}

// MARK: - Artist DTOs
struct ArtistDTO: Codable {
    let id: String
    let name: String
    let email: String
    let phone: String?
    let profession: String
    let specialty: String
    let bio: String?
    let rating: Double
    let totalReviews: Int
    let yearsOfExperience: Int
    let isVerified: Bool
    let profileImageURL: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, profession, specialty, bio, rating
        case totalReviews = "total_reviews"
        case yearsOfExperience = "years_of_experience"
        case isVerified = "is_verified"
        case profileImageURL = "profile_image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct UpdateArtistProfileRequest: Codable {
    let name: String?
    let phone: String?
    let profession: String?
    let specialty: String?
    let bio: String?
    let yearsOfExperience: Int?
}

struct ArtistStatisticsDTO: Codable {
    let totalClients: Int
    let completedServices: Int
    let monthlyEarnings: Double
    let averageRating: Double
    let totalBookings: Int
    let pendingBookings: Int
    let confirmedBookings: Int
    let completedBookingsThisMonth: Int
    let earningsThisMonth: Double
    let earningsLastMonth: Double
    let growthPercentage: Double
    
    enum CodingKeys: String, CodingKey {
        case totalClients = "total_clients"
        case completedServices = "completed_services"
        case monthlyEarnings = "monthly_earnings"
        case averageRating = "average_rating"
        case totalBookings = "total_bookings"
        case pendingBookings = "pending_bookings"
        case confirmedBookings = "confirmed_bookings"
        case completedBookingsThisMonth = "completed_bookings_this_month"
        case earningsThisMonth = "earnings_this_month"
        case earningsLastMonth = "earnings_last_month"
        case growthPercentage = "growth_percentage"
    }
}

// MARK: - Booking DTOs
struct BookingDTO: Codable {
    let id: String
    let clientName: String
    let clientEmail: String
    let clientPhone: String?
    let scheduledDate: String // ISO8601 format
    let duration: Int // minutes
    let status: String
    let totalPrice: Double
    let notes: String?
    let serviceId: String?
    let serviceName: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientName = "client_name"
        case clientEmail = "client_email"
        case clientPhone = "client_phone"
        case scheduledDate = "scheduled_date"
        case duration, status
        case totalPrice = "total_price"
        case notes
        case serviceId = "service_id"
        case serviceName = "service_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct BookingsListResponse: Codable {
    let bookings: [BookingDTO]
    let pagination: PaginationDTO
}

struct UpdateBookingStatusRequest: Codable {
    let status: String
    let notes: String?
}

struct TodayBookingsResponse: Codable {
    let todayBookings: [BookingDTO]
    let pendingCount: Int
    let confirmedCount: Int
    let completedCount: Int
    let totalEarningsToday: Double
    
    enum CodingKeys: String, CodingKey {
        case todayBookings = "today_bookings"
        case pendingCount = "pending_count"
        case confirmedCount = "confirmed_count"
        case completedCount = "completed_count"
        case totalEarningsToday = "total_earnings_today"
    }
}

// MARK: - Calendar & Availability DTOs
struct AvailabilityDTO: Codable {
    let id: String?
    let date: String // YYYY-MM-DD format
    let timeSlots: [TimeSlotDTO]
    let isAvailable: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, date
        case timeSlots = "time_slots"
        case isAvailable = "is_available"
    }
}

struct TimeSlotDTO: Codable {
    let id: String?
    let time: String // HH:mm format
    let isAvailable: Bool
    let isBooked: Bool
    let bookingId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, time
        case isAvailable = "is_available"
        case isBooked = "is_booked"
        case bookingId = "booking_id"
    }
}

struct UpdateAvailabilityRequest: Codable {
    let date: String
    let timeSlots: [UpdateTimeSlotRequest]
    
    enum CodingKeys: String, CodingKey {
        case date
        case timeSlots = "time_slots"
    }
}

struct UpdateTimeSlotRequest: Codable {
    let time: String
    let isAvailable: Bool
}

// MARK: - Messages DTOs
struct ConversationDTO: Codable {
    let id: String
    let clientName: String
    let clientEmail: String
    let clientAvatar: String?
    let lastMessage: MessageDTO?
    let unreadCount: Int
    let isOnline: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case clientName = "client_name"
        case clientEmail = "client_email"
        case clientAvatar = "client_avatar"
        case lastMessage = "last_message"
        case unreadCount = "unread_count"
        case isOnline = "is_online"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct MessageDTO: Codable {
    let id: String
    let content: String
    let isFromArtist: Bool
    let isRead: Bool
    let sentAt: String
    let conversationId: String
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case isFromArtist = "is_from_artist"
        case isRead = "is_read"
        case sentAt = "sent_at"
        case conversationId = "conversation_id"
    }
}

struct ConversationDetailResponse: Codable {
    let conversation: ConversationDTO
    let messages: [MessageDTO]
    let pagination: PaginationDTO
}

struct SendMessageRequest: Codable {
    let content: String
}

struct SendMessageResponse: Codable {
    let message: MessageDTO
    let conversation: ConversationDTO
}

// MARK: - Services DTOs
struct ServiceDTO: Codable {
    let id: String
    let name: String
    let description: String
    let duration: Int // minutes
    let price: Double
    let category: String
    let isActive: Bool
    let imageURL: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, duration, price, category
        case isActive = "is_active"
        case imageURL = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateServiceRequest: Codable {
    let name: String
    let description: String
    let duration: Int
    let price: Double
    let category: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, description, duration, price, category
        case isActive = "is_active"
    }
}

struct UpdateServiceRequest: Codable {
    let name: String?
    let description: String?
    let duration: Int?
    let price: Double?
    let category: String?
    let isActive: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name, description, duration, price, category
        case isActive = "is_active"
    }
}

// MARK: - Common DTOs
struct PaginationDTO: Codable {
    let page: Int
    let limit: Int
    let total: Int
    let totalPages: Int
    let hasNext: Bool
    let hasPrevious: Bool
    
    enum CodingKeys: String, CodingKey {
        case page, limit, total
        case totalPages = "total_pages"
        case hasNext = "has_next"
        case hasPrevious = "has_previous"
    }
}

struct ErrorResponse: Codable {
    let success: Bool
    let message: String
    let errors: [String]?
    let code: String?
}

struct SuccessResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Extensions for Conversion to Domain Models

extension ArtistDTO {
    func toDomainModel() -> Artist {
        return Artist(
            name: name,
            email: email,
            phone: phone ?? "",
            profession: profession,
            specialty: specialty,
            bio: bio ?? "",
            rating: rating,
            totalReviews: totalReviews,
            yearsOfExperience: yearsOfExperience,
            isVerified: isVerified
        )
    }
}

extension BookingDTO {
    func toDomainModel() -> Booking {
        let dateFormatter = ISO8601DateFormatter()
        let date = dateFormatter.date(from: scheduledDate) ?? Date()
        
        let bookingStatus: BookingStatus = {
            switch status.lowercased() {
            case "pending": return .pending
            case "confirmed": return .confirmed
            case "in_progress": return .inProgress
            case "completed": return .completed
            case "cancelled": return .cancelled
            case "no_show": return .noShow
            default: return .pending
            }
        }()
        
        return Booking(
            clientName: clientName,
            clientEmail: clientEmail,
            clientPhone: clientPhone ?? "",
            scheduledDate: date,
            duration: duration,
            totalPrice: totalPrice,
            notes: notes ?? "",
            status: bookingStatus
        )
    }
}

extension ServiceDTO {
    func toDomainModel() -> Service {
        return Service(
            name: name,
            description: description,
            duration: duration,
            price: price,
            category: category,
            isActive: isActive
        )
    }
}

extension TimeSlotDTO {
    func toDomainModel() -> CalendarViewModel.TimeSlot {
        return CalendarViewModel.TimeSlot(
            time: time,
            isAvailable: isAvailable,
            isBooked: isBooked
        )
    }
}

extension ConversationDTO {
    func toDomainModel() -> MessagesViewModel.ConversationItem {
        let lastMessageText = lastMessage?.content ?? ""
        let timestamp = ISO8601DateFormatter().date(from: updatedAt) ?? Date()
        
        return MessagesViewModel.ConversationItem(
            clientName: clientName,
            clientEmail: clientEmail,
            lastMessage: lastMessageText,
            timestamp: timestamp,
            unreadCount: unreadCount,
            isOnline: isOnline,
            messages: []
        )
    }
}

extension MessageDTO {
    func toDomainModel() -> MessagesViewModel.MessageItem {
        let timestamp = ISO8601DateFormatter().date(from: sentAt) ?? Date()
        
        return MessagesViewModel.MessageItem(
            content: content,
            isFromArtist: isFromArtist,
            timestamp: timestamp,
            isRead: isRead
        )
    }
}