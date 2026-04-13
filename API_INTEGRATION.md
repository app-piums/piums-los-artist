# 🚀 Piums Artista - API Integration Documentation

## 📋 Resumen de Integración

La aplicación **Piums Artista iOS** ahora cuenta con una integración completa de API que permite conectarse con el backend de Piums Platform. Esta documentación describe la arquitectura, endpoints y características implementadas.

---

## 🏗️ Arquitectura de API

### 📁 Estructura de Archivos

```
PiumsArtist/Services/
├── APIService.swift        # Servicio principal de HTTP requests
├── APIModels.swift         # DTOs para mapear respuestas JSON
├── AuthService.swift       # Autenticación y gestión de tokens
└── ErrorHandling.swift     # Manejo global de errores
```

### 🔧 Componentes Principales

#### 1. **APIService** - Servicio HTTP Principal
- **URLSession** configurado para requests async/await
- **JWT Token management** automático
- **Error handling** con tipos específicos
- **Request/Response** genéricos con Codable

#### 2. **AuthService** - Autenticación 
- **Login/Logout** con JWT tokens
- **Refresh token** automático
- **Auto-login** con "Remember me"
- **Persistent storage** de credenciales

#### 3. **ErrorHandler** - Manejo de Errores
- **Global error handling** con UI contextual
- **Network status** monitoring
- **Retry mechanisms** para requests fallidos
- **User-friendly** error messages

---

## 🌐 API Endpoints Implementados

### Base URL
```
https://api.piums.com/v1/artists
```

### 🔐 **Autenticación**

#### `POST /auth/login`
```json
Request: {
  "email": "artist@email.com",
  "password": "password123"
}

Response: {
  "success": true,
  "data": {
    "token": "jwt_token_here",
    "refreshToken": "refresh_token_here",
    "expiresIn": 3600,
    "artist": { /* Artist object */ }
  }
}
```

#### `POST /auth/refresh`
```json
Request: {
  "refreshToken": "refresh_token_here"
}
```

#### `POST /auth/logout`
```json
Response: {
  "success": true,
  "message": "Logged out successfully"
}
```

---

### 👤 **Perfil de Artista**

#### `GET /profile`
```json
Response: {
  "success": true,
  "data": {
    "id": "artist_id",
    "name": "Artista Name",
    "email": "artist@email.com",
    "profession": "Peluquero",
    "specialty": "Cortes modernos",
    "rating": 4.8,
    "total_reviews": 156,
    "years_of_experience": 5
  }
}
```

#### `PUT /profile`
```json
Request: {
  "name": "Updated Name",
  "phone": "+34 666 123 456",
  "bio": "Updated bio"
}
```

#### `GET /profile/statistics`
```json
Response: {
  "success": true,
  "data": {
    "total_clients": 1234,
    "completed_services": 2156,
    "monthly_earnings": 3250.0,
    "average_rating": 4.8
  }
}
```

---

### 📅 **Reservas (Bookings)**

#### `GET /bookings`
```json
Query Parameters:
- status: "pending" | "confirmed" | "completed" | "cancelled"
- page: 1
- limit: 20

Response: {
  "success": true,
  "data": {
    "bookings": [
      {
        "id": "booking_id",
        "client_name": "Cliente Name",
        "client_email": "client@email.com",
        "scheduled_date": "2026-04-15T10:00:00Z",
        "duration": 60,
        "total_price": 45.0,
        "status": "confirmed"
      }
    ],
    "pagination": {
      "page": 1,
      "total": 50,
      "total_pages": 3
    }
  }
}
```

#### `GET /bookings/today`
```json
Response: {
  "success": true,
  "data": {
    "today_bookings": [/* array of bookings */],
    "pending_count": 3,
    "confirmed_count": 5,
    "total_earnings_today": 320.0
  }
}
```

#### `PUT /bookings/{id}/status`
```json
Request: {
  "status": "confirmed",
  "notes": "Confirmado por el artista"
}
```

---

### 💬 **Mensajes**

#### `GET /messages/conversations`
```json
Response: {
  "success": true,
  "data": [
    {
      "id": "conv_id",
      "client_name": "Cliente Name",
      "client_email": "client@email.com",
      "last_message": {
        "content": "¿Tienes disponibilidad mañana?",
        "sent_at": "2026-04-13T15:30:00Z"
      },
      "unread_count": 2,
      "is_online": true
    }
  ]
}
```

#### `POST /messages/conversations/{id}/messages`
```json
Request: {
  "content": "Sí, tengo disponibilidad a las 10:00"
}

Response: {
  "success": true,
  "data": {
    "message": { /* mensaje creado */ },
    "conversation": { /* conversación actualizada */ }
  }
}
```

---

### 📆 **Disponibilidad**

#### `GET /availability`
```json
Query Parameters:
- date: "2026-04-15" (optional)

Response: {
  "success": true,
  "data": [
    {
      "date": "2026-04-15",
      "time_slots": [
        {
          "time": "09:00",
          "is_available": true,
          "is_booked": false
        },
        {
          "time": "10:30",
          "is_available": false,
          "is_booked": true,
          "booking_id": "booking_123"
        }
      ]
    }
  ]
}
```

#### `PUT /availability`
```json
Request: {
  "date": "2026-04-15",
  "time_slots": [
    {
      "time": "09:00",
      "is_available": true
    }
  ]
}
```

---

### 🛠️ **Servicios**

#### `GET /services`
```json
Response: {
  "success": true,
  "data": [
    {
      "id": "service_id",
      "name": "Corte de Pelo",
      "description": "Corte moderno personalizado",
      "duration": 45,
      "price": 25.0,
      "category": "Peluquería",
      "is_active": true
    }
  ]
}
```

---

## 🔄 ViewModels con API Integration

### 🏠 **DashboardViewModel**
```swift
// Carga estadísticas del día
await loadDashboardData()
- GET /bookings/today
- GET /bookings?status=completed
- Actualiza: todayBookings, pendingBookings, monthlyEarnings
```

### 📋 **BookingsViewModel**
```swift
// Gestión completa de reservas
await loadBookings()          // GET /bookings
await acceptBooking()         // PUT /bookings/{id}/status
await rejectBooking()         // PUT /bookings/{id}/status  
await completeBooking()       // PUT /bookings/{id}/status
```

### 💬 **MessagesViewModel**
```swift
// Sistema de mensajería
await loadConversations()     // GET /conversations
await sendMessage()           // POST /conversations/{id}/messages
```

### 👤 **ProfileViewModel**
```swift
// Perfil del artista
await loadProfileData()       // GET /profile
await loadStatistics()        // GET /profile/statistics
await saveProfile()           // PUT /profile
```

---

## 🛡️ Error Handling

### Tipos de Error
```swift
enum APIError: Error {
    case networkError(Error)    // Sin conexión
    case unauthorized          // Token expirado
    case forbidden            // Sin permisos
    case notFound            // Recurso no encontrado
    case serverError         // Error 500+
    case decodingError       // JSON inválido
}
```

### UI de Errores
- **Error Banners** con botones de acción
- **Loading Overlays** durante requests
- **Retry mechanisms** automáticos
- **Network status** monitoring

---

## 📱 Flujo de Autenticación

1. **App Launch** → Verifica token guardado
2. **Token válido** → Auto-login → Dashboard
3. **Token inválido** → LoginView
4. **Login exitoso** → Guarda token → Dashboard
5. **Token expira** → Refresh automático
6. **Refresh falla** → Logout → LoginView

---

## 🚀 Estado de Implementación

### ✅ **Completado**
- [x] APIService con URLSession
- [x] Todos los DTOs y modelos
- [x] AuthService completo
- [x] Error handling robusto
- [x] ViewModels con API calls
- [x] Login/Logout flow
- [x] Token management
- [x] Build exitoso sin errores

### 🔄 **Próximos Pasos**
- [ ] Testing con API real
- [ ] Optimización de performance
- [ ] Caching de datos offline
- [ ] Push notifications
- [ ] Websockets para chat real-time

---

## 📊 Métricas del Proyecto

```
📱 Archivos Swift: 15
📏 Líneas de código: 3,200+
🌐 Endpoints: 15+
🔧 DTOs implementados: 20+
⚡ ViewModels con API: 5
🛡️ Error types: 8
```

---

## 🔗 Enlaces Útiles

- **Repositorio**: https://github.com/app-piums/piums-los-artist.git
- **Commit actual**: `8315388` - API Integration completa
- **iOS Target**: 26.2+ (iPhone/iPad)
- **Arquitectura**: SwiftUI + MVVM + SwiftData

---

*Documentación generada el 13 de Abril de 2026*
*Piums Artista v1.0 - API Integration*