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
    static let baseURL = "https://api.piums.com/v1"
    static let artistBaseURL = "\(baseURL)/artists"
}

// MARK: - API Endpoints
enum APIEndpoint {
    // Authentication
    case login
    case refreshToken
    case logout
    
    // Artist Profile
    case artistProfile
    case updateProfile
    case artistStatistics
    
    // Bookings
    case bookings(status: String? = nil)
    case bookingById(String)
    case updateBookingStatus(String, status: String)
    case todayBookings
    case bookingHistory
    
    // Calendar & Availability
    case availability(date: String? = nil)
    case updateAvailability
    case timeSlots(date: String)
    
    // Messages
    case conversations
    case conversationById(String)
    case sendMessage(conversationId: String)
    case markAsRead(messageId: String)
    
    // Services
    case services
    case createService
    case updateService(String)
    case deleteService(String)
    
    var path: String {
        switch self {
        // Authentication
        case .login:
            return "/auth/login"
        case .refreshToken:
            return "/auth/refresh"
        case .logout:
            return "/auth/logout"
            
        // Artist Profile
        case .artistProfile:
            return "/profile"
        case .updateProfile:
            return "/profile"
        case .artistStatistics:
            return "/profile/statistics"
            
        // Bookings
        case .bookings(let status):
            var path = "/bookings"
            if let status = status {
                path += "?status=\(status)"
            }
            return path
        case .bookingById(let id):
            return "/bookings/\(id)"
        case .updateBookingStatus(let id, let status):
            return "/bookings/\(id)/status"
        case .todayBookings:
            return "/bookings/today"
        case .bookingHistory:
            return "/bookings/history"
            
        // Calendar & Availability
        case .availability(let date):
            var path = "/availability"
            if let date = date {
                path += "?date=\(date)"
            }
            return path
        case .updateAvailability:
            return "/availability"
        case .timeSlots(let date):
            return "/availability/slots?date=\(date)"
            
        // Messages
        case .conversations:
            return "/messages/conversations"
        case .conversationById(let id):
            return "/messages/conversations/\(id)"
        case .sendMessage(let conversationId):
            return "/messages/conversations/\(conversationId)/messages"
        case .markAsRead(let messageId):
            return "/messages/\(messageId)/read"
            
        // Services
        case .services:
            return "/services"
        case .createService:
            return "/services"
        case .updateService(let id):
            return "/services/\(id)"
        case .deleteService(let id):
            return "/services/\(id)"
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
        guard let url = URL(string: APIConfig.artistBaseURL + endpoint.path) else {
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