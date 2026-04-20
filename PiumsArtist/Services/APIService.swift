//
//  APIService.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import Foundation
import Combine

// MARK: - API Configuration
struct APIConfig {
    static let baseURL = "https://piums.com/api"
    static let stagingURL = "https://staging.piums.com/api"
    static let localURL = "http://localhost:3000/api"
    
    #if DEBUG
    static let currentURL = localURL
    #else
    static let currentURL = baseURL
    #endif
}

// MARK: - API Endpoints
enum APIEndpoint {
    // Authentication
    case register
    case login
    case refreshToken
    case logout
    case forgotPassword
    case resetPassword
    case changePassword
    case verifyEmail
    case resendVerification
    
    // OAuth
    case googleOAuth
    case facebookOAuth
    
    // Users
    case userProfile
    case updateUserProfile
    case deleteUser
    case uploadAvatar
    case deleteAvatar
    case getNotificationSettings
    case updateNotificationSettings
    
    // Artists
    case artists(page: Int? = nil, limit: Int? = nil, category: String? = nil, location: String? = nil)
    case createArtist
    case artistById(String)
    case updateArtist(String)
    case deleteArtist(String)
    case artistDashboard
    case artistStats
    case artistBookings(status: String? = nil, page: Int? = nil, artistId: String? = nil)
    case acceptBooking(String)
    case declineBooking(String)
    case completeBooking(String)
    case artistCancelBooking(String)
    
    // Absences
    case createArtistProfile
    case setArtistAvailability
    case getAvailability
    case getBlockedSlots(artistId: String)
    case createBlockedSlot
    case deleteBlockedSlot(String)
    case artistAbsences
    case createAbsence
    case deleteAbsence(String)
    
    // Catalog
    case catalogServices(artistId: String? = nil, category: String? = nil)
    case createService
    case serviceById(String)
    case updateService(String)
    case deleteService(String, artistId: String)
    case toggleServiceStatus(String)
    case serviceCategories
    
    // Bookings
    case bookings(status: String? = nil, page: Int? = nil)
    case createBooking
    case bookingById(String)
    case cancelBooking(String)
    case rescheduleBooking(String)
    
    // Payments
    case paymentMethods
    case createPaymentMethod
    case deletePaymentMethod(String)
    case setDefaultPaymentMethod(String)
    case payments(page: Int? = nil)
    case processPayment
    case refundPayment(String)
    
    // Reviews
    case reviews(artistId: String? = nil, page: Int? = nil)
    case createReview
    case reviewById(String)
    case updateReview(String)
    case deleteReview(String)
    case respondToReview(String)
    case markReviewHelpful(String)
    
    // Notifications
    case notifications(unread: Bool? = nil, page: Int? = nil)
    case markNotificationRead(String)
    case markAllNotificationsRead
    
    // Search
    case searchArtists(query: String? = nil, category: String? = nil, location: String? = nil, page: Int? = nil)
    case searchServices(query: String? = nil, category: String? = nil)
    
    // Chat
    case conversations
    case createConversation
    case conversationById(String)
    case conversationMessages(String, page: Int? = nil)
    case sendMessage
    case markMessageRead(String)
    case markConversationRead(String)
    
    // Reviews (nuevos)
    case reviewsList(artistId: String, page: Int?)
    case reportReview(String)

    // Disputes
    case myDisputes
    case createDispute
    case disputeById(String)
    case addDisputeMessage(String)

    // Verification / Auth Profile
    case authMe
    case authProfile
    case uploadDocument(folder: String)

    // Health
    case health

    var path: String {
        switch self {
        // Authentication
        case .register:
            return "/auth/register"
        case .login:
            return "/auth/login"
        case .refreshToken:
            return "/auth/refresh"
        case .logout:
            return "/auth/logout"
        case .forgotPassword:
            return "/auth/forgot-password"
        case .resetPassword:
            return "/auth/reset-password"
        case .changePassword:
            return "/auth/change-password"
        case .verifyEmail:
            return "/auth/verify-email"
        case .resendVerification:
            return "/auth/resend-verification"
            
        // OAuth
        case .googleOAuth:
            return "/auth/oauth/google"
        case .facebookOAuth:
            return "/auth/oauth/facebook"
            
        // Users
        case .userProfile:
            return "/users/me"
        case .updateUserProfile:
            return "/users/me"
        case .deleteUser:
            return "/users/me"
        case .uploadAvatar:
            return "/users/me/avatar"
        case .deleteAvatar:
            return "/users/me/avatar"
        case .getNotificationSettings:
            return "/users/me/notifications-settings"
        case .updateNotificationSettings:
            return "/users/me/notifications-settings"
            
        // Artists — el backend usa /search/artists para listar y por ID
        case .artists(let page, let limit, let category, let location):
            var path = "/search/artists"
            var params: [String] = []
            if let page = page { params.append("page=\(page)") }
            if let limit = limit { params.append("limit=\(limit)") }
            if let category = category { params.append("category=\(category)") }
            if let location = location { params.append("location=\(location)") }
            if !params.isEmpty { path += "?" + params.joined(separator: "&") }
            return path
        case .createArtist:
            return "/search/artists"
        case .artistById(let id):
            return "/search/artists/\(id)"
        case .updateArtist(let id):
            return "/search/artists/\(id)"
        case .deleteArtist(let id):
            return "/search/artists/\(id)"
        case .artistDashboard:
            return "/artists/dashboard/me"
        case .artistStats:
            return "/artists/dashboard/me/stats"
        case .artistBookings(let status, let page, _):
            var path = "/artists/dashboard/me/bookings"
            var params: [String] = []
            if let status = status { params.append("status=\(status.uppercased())") }
            if let page = page { params.append("page=\(page)") }
            if !params.isEmpty { path += "?" + params.joined(separator: "&") }
            return path
        case .acceptBooking(let id):
            return "/artists/dashboard/me/bookings/\(id)/accept"
        case .declineBooking(let id):
            return "/artists/dashboard/me/bookings/\(id)/decline"
        case .completeBooking(let id):
            return "/artists/dashboard/me/bookings/\(id)/complete"
        case .artistCancelBooking(let id):
            return "/artists/dashboard/me/bookings/\(id)/cancel"
            
        case .createArtistProfile:
            return "/artists/dashboard/me/profile"
        case .setArtistAvailability:
            return "/artists/dashboard/me/availability"
        case .getAvailability:
            return "/artists/dashboard/me/availability"
        case .getBlockedSlots(let artistId):
            return "/artists/\(artistId)/blocked-slots"
        case .createBlockedSlot:
            return "/blocked-slots"
        case .deleteBlockedSlot(let id):
            return "/blocked-slots/\(id)"
            
        // Absences
        case .artistAbsences:
            return "/artists/dashboard/me/absences"
        case .createAbsence:
            return "/artists/dashboard/me/absences"
        case .deleteAbsence(let id):
            return "/artists/dashboard/me/absences/\(id)"
            
        // Catalog
        case .catalogServices(let artistId, let category):
            var path = "/catalog/services"
            var params: [String] = []
            if let artistId = artistId { params.append("artistId=\(artistId)") }
            if let category = category { params.append("category=\(category)") }
            if !params.isEmpty { path += "?" + params.joined(separator: "&") }
            return path
        case .createService:
            return "/catalog/services"
        case .serviceById(let id):
            return "/catalog/services/\(id)"
        case .updateService(let id):
            return "/catalog/services/\(id)"
        case .deleteService(let id, let artistId):
            return "/catalog/services/\(id)?artistId=\(artistId)"
        case .toggleServiceStatus(let id):
            return "/catalog/services/\(id)/toggle-status"
        case .serviceCategories:
            return "/catalog/categories"
            
        // Bookings
        case .bookings(let status, let page):
            var path = "/bookings"
            var params: [String] = []
            if let status = status { params.append("status=\(status.uppercased())") }
            if let page = page { params.append("page=\(page)") }
            if !params.isEmpty { path += "?" + params.joined(separator: "&") }
            return path
        case .createBooking:
            return "/bookings"
        case .bookingById(let id):
            return "/bookings/\(id)"
        case .cancelBooking(let id):
            return "/bookings/\(id)"
        case .rescheduleBooking(let id):
            return "/bookings/\(id)/reschedule"
            
        // Payments
        case .paymentMethods:
            return "/payments/methods"
        case .createPaymentMethod:
            return "/payments/methods"
        case .deletePaymentMethod(let id):
            return "/payments/methods/\(id)"
        case .setDefaultPaymentMethod(let id):
            return "/payments/methods/\(id)/default"
        case .payments(let page):
            var path = "/payments"
            if let page = page { path += "?page=\(page)" }
            return path
        case .processPayment:
            return "/payments"
        case .refundPayment(let id):
            return "/payments/refund/\(id)"
            
        // Reviews
        case .reviews(let artistId, let page):
            var path = "/reviews"
            var params: [String] = []
            if let artistId = artistId { params.append("artistId=\(artistId)") }
            if let page = page { params.append("page=\(page)") }
            if !params.isEmpty { path += "?" + params.joined(separator: "&") }
            return path
        case .createReview:
            return "/reviews"
        case .reviewById(let id):
            return "/reviews/\(id)"
        case .updateReview(let id):
            return "/reviews/\(id)"
        case .deleteReview(let id):
            return "/reviews/\(id)"
        case .respondToReview(let id):
            return "/reviews/\(id)/respond"
        case .markReviewHelpful(let id):
            return "/reviews/\(id)/helpful"
            
        // Notifications
        case .notifications(let unread, let page):
            var path = "/notifications"
            var params: [String] = []
            if let unread = unread { params.append("unread=\(unread)") }
            if let page = page { params.append("page=\(page)") }
            if !params.isEmpty { path += "?" + params.joined(separator: "&") }
            return path
        case .markNotificationRead(let id):
            return "/notifications/\(id)/read"
        case .markAllNotificationsRead:
            return "/notifications/read-all"
            
        // Search
        case .searchArtists(let query, let category, let location, let page):
            var path = "/search/artists"
            var params: [String] = []
            if let query = query { params.append("q=\(query)") }
            if let category = category { params.append("category=\(category)") }
            if let location = location { params.append("location=\(location)") }
            if let page = page { params.append("page=\(page)") }
            if !params.isEmpty { path += "?" + params.joined(separator: "&") }
            return path
        case .searchServices(let query, let category):
            var path = "/search/services"
            var params: [String] = []
            if let query = query { params.append("q=\(query)") }
            if let category = category { params.append("category=\(category)") }
            if !params.isEmpty { path += "?" + params.joined(separator: "&") }
            return path
            
        // Chat
        case .conversations:
            return "/chat/conversations"
        case .createConversation:
            return "/chat/conversations"
        case .conversationById(let id):
            return "/chat/conversations/\(id)"
        case .conversationMessages(let id, let page):
            var path = "/chat/messages/\(id)"
            if let page = page { path += "?page=\(page)" }
            return path
        case .sendMessage:
            return "/chat/messages"
        case .markMessageRead(let id):
            return "/chat/messages/\(id)/read"
        case .markConversationRead(let id):
            return "/chat/conversations/\(id)/read"
            
        case .reviewsList(let artistId, let page):
            var path = "/reviews"
            var params = ["artistId=\(artistId)"]
            if let page = page { params.append("page=\(page)") }
            return path + "?" + params.joined(separator: "&")
        case .reportReview(let id):
            return "/reviews/\(id)/report"

        // Disputes
        case .myDisputes:
            return "/disputes/me"
        case .createDispute:
            return "/disputes"
        case .disputeById(let id):
            return "/disputes/\(id)"
        case .addDisputeMessage(let id):
            return "/disputes/\(id)/messages"

        // Verification / Auth Profile
        case .authMe:
            return "/auth/me"
        case .authProfile:
            return "/auth/profile"
        case .uploadDocument(let folder):
            return "/users/documents/upload?folder=\(folder)"

        // Health
        case .health:
            return "/health"
        }
    }
}

// MARK: - HTTP Methods
enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
}

// MARK: - API Error Types
enum APIError: Error, LocalizedError {
    case networkError(Error)
    case invalidURL
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case httpError(Int, String)
    case unauthorized
    case forbidden
    case notFound
    case serverError
    case rateLimited(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        case .invalidURL:
            return "URL inválida"
        case .noData:
            return "No se recibieron datos"
        case .decodingError(let error):
            return "Error al procesar datos: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Error al codificar datos: \(error.localizedDescription)"
        case .httpError(let code, let message):
            return "Error HTTP \(code): \(message)"
        case .unauthorized:
            return "No autorizado. Por favor inicia sesión nuevamente."
        case .forbidden:
            return "Acceso prohibido"
        case .notFound:
            return "Recurso no encontrado"
        case .serverError:
            return "Error del servidor. Intenta más tarde."
        case .rateLimited(let message):
            return "Demasiados intentos: \(message)"
        case .unknown:
            return "Error desconocido"
        }
    }
}

// MARK: - API Service
@MainActor
final class APIService: ObservableObject {
    static let shared = APIService()
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // Authentication token
    @Published var authToken: String? {
        didSet {
            if let token = authToken {
                UserDefaults.standard.set(token, forKey: "auth_token")
            } else {
                UserDefaults.standard.removeObject(forKey: "auth_token")
            }
        }
    }
    
    private init() {
        // Configure JSON decoder for dates
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        
        // Load saved auth token
        authToken = UserDefaults.standard.string(forKey: "auth_token")
    }
    
    // MARK: - Generic Request Method
    func request<T: Codable>(
        endpoint: APIEndpoint,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        
        isLoading = true
        errorMessage = nil
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        // Construct URL
        guard let url = URL(string: APIConfig.currentURL + endpoint.path) else {
            throw APIError.invalidURL
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication header if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body if provided
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP status
            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    break
                case 401:
                    await MainActor.run {
                        self.authToken = nil
                    }
                    throw APIError.unauthorized
                case 403:
                    throw APIError.forbidden
                case 404:
                    throw APIError.notFound
                case 429:
                    // Rate limiting - extract message if possible
                    if let errorMessage = try? decoder.decode([String: String].self, from: data)["message"] {
                        throw APIError.rateLimited(errorMessage)
                    } else {
                        throw APIError.rateLimited("Too many requests")
                    }
                case 500...599:
                    throw APIError.serverError
                default:
                    throw APIError.httpError(httpResponse.statusCode, "Request failed")
                }
            }
            
            // Decode response
            do {
                let result = try decoder.decode(responseType, from: data)
                return result
            } catch {
                throw APIError.decodingError(error)
            }
            
        } catch {
            if error is APIError {
                throw error
            } else {
                throw APIError.networkError(error)
            }
        }
    }
    
    // MARK: - Convenience Methods
    
    func get<T: Codable>(
        endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .GET,
            responseType: responseType
        )
    }
    
    func post<T: Codable, U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        responseType: T.Type
    ) async throws -> T {
        let bodyData = try encoder.encode(body)
        return try await request(
            endpoint: endpoint,
            method: .POST,
            body: bodyData,
            responseType: responseType
        )
    }
    
    func put<T: Codable, U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        responseType: T.Type
    ) async throws -> T {
        let bodyData = try encoder.encode(body)
        return try await request(
            endpoint: endpoint,
            method: .PUT,
            body: bodyData,
            responseType: responseType
        )
    }
    
    func patch<T: Codable, U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        responseType: T.Type
    ) async throws -> T {
        let bodyData = try encoder.encode(body)
        return try await request(
            endpoint: endpoint,
            method: .PATCH,
            body: bodyData,
            responseType: responseType
        )
    }

    func delete<T: Codable>(
        endpoint: APIEndpoint,
        responseType: T.Type
    ) async throws -> T {
        return try await request(
            endpoint: endpoint,
            method: .DELETE,
            responseType: responseType
        )
    }
}

// MARK: - Response Wrapper
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let errors: [String]?
}
