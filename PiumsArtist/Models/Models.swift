//
//  Models.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import Foundation
import SwiftData

// MARK: - Enums First (to avoid forward declaration issues)

enum BookingStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case noShow = "no_show"
    
    var displayName: String {
        switch self {
        case .pending: return "Pendiente"
        case .confirmed: return "Confirmada"
        case .inProgress: return "En Progreso"
        case .completed: return "Completada"
        case .cancelled: return "Cancelada"
        case .noShow: return "No se presentó"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .confirmed: return "blue"
        case .inProgress: return "purple"
        case .completed: return "green"
        case .cancelled, .noShow: return "red"
        }
    }
}

// MARK: - Models

@Model
final class Artist {
    var id: UUID
    var name: String
    var email: String
    var phone: String
    var profession: String
    var specialty: String
    var bio: String
    var rating: Double
    var totalReviews: Int
    var yearsOfExperience: Int
    var isVerified: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        email: String,
        phone: String = "",
        profession: String,
        specialty: String = "",
        bio: String = "",
        rating: Double = 0.0,
        totalReviews: Int = 0,
        yearsOfExperience: Int = 0,
        isVerified: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.phone = phone
        self.profession = profession
        self.specialty = specialty
        self.bio = bio
        self.rating = rating
        self.totalReviews = totalReviews
        self.yearsOfExperience = yearsOfExperience
        self.isVerified = isVerified
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class Service {
    var id: UUID
    var name: String
    var serviceDescription: String
    var duration: Int
    var price: Double
    var isActive: Bool
    var category: String
    var pricingType: String
    var createdAt: Date
    var updatedAt: Date
    
    init(
        name: String,
        description: String,
        duration: Int,
        price: Double,
        category: String = "General",
        isActive: Bool = true,
        pricingType: String = "FIXED"
    ) {
        self.id = UUID()
        self.name = name
        self.serviceDescription = description
        self.duration = duration
        self.price = price
        self.category = category
        self.pricingType = pricingType
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class Booking: Identifiable, Hashable {
    var id: UUID
    var remoteId: String
    var clientName: String
    var clientEmail: String
    var clientPhone: String
    var scheduledDate: Date
    var duration: Int
    var status: BookingStatus
    var totalPrice: Double
    var notes: String
    var serviceName: String?
    var bookingCode: String?
    var createdAt: Date
    var updatedAt: Date

    static func == (lhs: Booking, rhs: Booking) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    
    init(
        remoteId: String = UUID().uuidString,
        clientName: String,
        clientEmail: String,
        clientPhone: String = "",
        scheduledDate: Date,
        duration: Int,
        totalPrice: Double,
        notes: String = "",
        status: BookingStatus = .pending,
        serviceName: String? = nil,
        bookingCode: String? = nil
    ) {
        self.id = UUID()
        self.remoteId = remoteId
        self.clientName = clientName
        self.clientEmail = clientEmail
        self.clientPhone = clientPhone
        self.scheduledDate = scheduledDate
        self.duration = duration
        self.status = status
        self.totalPrice = totalPrice
        self.notes = notes
        self.serviceName = serviceName
        self.bookingCode = bookingCode
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

@Model
final class Message {
    var id: UUID
    var content: String
    var isFromArtist: Bool
    var isRead: Bool
    var sentAt: Date
    
    init(
        content: String,
        isFromArtist: Bool,
        isRead: Bool = false
    ) {
        self.id = UUID()
        self.content = content
        self.isFromArtist = isFromArtist
        self.isRead = isRead
        self.sentAt = Date()
    }
}

// MARK: - Preview Extensions

extension Artist {
    static let preview = Artist(
        name: "María González",
        email: "maria.gonzalez@piums.com",
        phone: "+34 666 777 888",
        profession: "Estilista Profesional",
        specialty: "Coloración y Peinados",
        bio: "Especialista en coloración y peinados con más de 5 años de experiencia.",
        rating: 4.8,
        totalReviews: 156,
        yearsOfExperience: 5,
        isVerified: true
    )
}

extension Service {
    static let previewServices = [
        Service(name: "Corte de cabello", description: "Corte y peinado personalizado", duration: 45, price: 35.0, category: "Cabello"),
        Service(name: "Coloración", description: "Tinte y mechas profesionales", duration: 120, price: 80.0, category: "Cabello"),
        Service(name: "Peinado", description: "Peinado para eventos especiales", duration: 60, price: 45.0, category: "Cabello"),
        Service(name: "Barba y bigote", description: "Arreglo de barba y bigote", duration: 30, price: 25.0, category: "Facial")
    ]
}

extension Booking {
    static let previewBookings = [
        Booking(
            remoteId: "mock-1",
            clientName: "Ana López",
            clientEmail: "ana.lopez@email.com",
            clientPhone: "+34 666 111 222",
            scheduledDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()) ?? Date(),
            duration: 45,
            totalPrice: 35.0,
            notes: "Prefiere corte bob",
            status: .confirmed
        ),
        Booking(
            remoteId: "mock-2",
            clientName: "Carlos Martín",
            clientEmail: "carlos.martin@email.com",
            scheduledDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            duration: 120,
            totalPrice: 80.0,
            status: .pending
        )
    ]
}
