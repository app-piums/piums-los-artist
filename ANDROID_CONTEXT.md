# Piums Artist — Android Context Guide

> Documento de referencia para el desarrollo de la app **PiumsArtist Android**.
> Mantiene paridad de estilo, funcionalidades y API con la versión iOS (SwiftUI).

---

## 1. Identidad de marca

| Token | Valor HEX | Uso |
|---|---|---|
| `piumsOrange` / `piumsPrimary` | `#FF6B35` | Color principal, CTAs, íconos activos |
| `piumsSecondary` | `#E85D2F` | Hover / pressed state |
| `piumsAccent` | `#F59E0B` | Amber accent, gradientes |
| `piumsSuccess` | `#10B981` | Estados positivos, completado |
| `piumsWarning` | `#F59E0B` | Alertas, pendiente |
| `piumsError` | `#EF4444` | Errores, cancelaciones |
| `piumsInfo` | `#3B82F6` | Información, confirmado |

**Logo:** Imagen vectorial `PiumsLogo` (PNG 1x/2x/3x). Siempre usar en topbars y splash. Tamaños según contexto:
- Splash screen: 76 dp
- Inicio / Calendario / Reservas top bar: 52 dp
- Otras top bars: 40 dp

---

## 2. Sistema de colores — Modo oscuro / claro

La app usa colores del sistema iOS mapeados a equivalentes Material 3 en Android:

| Rol | iOS | Android (Material 3) | Dark mode | Light mode |
|---|---|---|---|---|
| Fondo de página | `secondarySystemGroupedBackground` | `Surface` / `surfaceVariant` | `#1C1C1E` | `#FFFFFF` |
| Cards / filas | `tertiarySystemGroupedBackground` | `surfaceContainer` | `#2C2C2E` | `#F2F2F7` |
| Navigation bar | `secondarySystemGroupedBackground` | `surfaceContainer` | `#1C1C1E` | `#FFFFFF` |
| Fondo base (evitar) | `systemGroupedBackground` | `background` | `#000000` | `#F2F2F7` |

**Regla clave:** nunca usar el color base puro (`#000000` dark / `#F2F2F7` light) como fondo de página — usar siempre `surfaceVariant` equivalente para mantener la tonalidad gris consistente en modo oscuro.

---

## 3. Estructura de la app

### Navegación principal — Bottom Navigation Bar (5 tabs)

| Tab | Ícono | Pantalla |
|---|---|---|
| Inicio | `home` | `DashboardScreen` |
| Reservas | `calendar_today` | `BookingsScreen` |
| Agenda | `date_range` | `CalendarScreen` |
| Mensajes | `chat_bubble` | `MessagesScreen` |
| Más | `menu` / `more_horiz` | `MoreMenuScreen` |

Color activo del tab: `piumsOrange` (`#FF6B35`).

---

## 4. Pantallas y funcionalidades

### 4.1 Inicio (`DashboardScreen`)
**Top bar custom** (sin ActionBar nativa):
- Izquierda: Avatar del artista (iniciales + gradiente naranja→amber)
- Centro: Logo `PiumsLogo` (52 dp)
- Derecha: Ícono `bell_filled` con badge rojo si hay pendientes

**Contenido:**
- Saludo personalizado + fecha actual
- Grid 2×2 stats: Reservas hoy, Pendientes, Ingresos del mes, Total ingresos
- Sección "Próximas reservas" (lista compacta)
- Sección "Reservas de hoy" (lista detallada)

**API:** `GET /artists/dashboard/me` + `GET /artists/dashboard/me/stats`

---

### 4.2 Reservas (`BookingsScreen`)
**Top bar custom:**
- Izquierda: Avatar artista
- Centro: Logo PiumsLogo
- Derecha: Campana con badge si hay pendientes

**Filter chips horizontales** (scroll horizontal):
- Todas · Pendientes · Confirmadas · Completadas · Canceladas
- Chip seleccionado: fondo `piumsOrange`, texto blanco
- Badge con conteo por estado

**Stats row** (solo al mostrar "Todas"):
- 3 pills: Pendientes (naranja) / Confirmadas (azul) / Completadas (verde)

**Booking Card:**
- Ícono de estado (rounded square con color)
- Nombre del servicio + código de reserva (monospace)
- Precio en naranja (formato `Q 0.00`)
- Badge de estado + hora + duración en fila
- Fondo: `surfaceContainer` (`#2C2C2E` dark)

**Estados vacíos:** Círculos concéntricos naranjas con ícono según filtro + botón "Actualizar"

**Detalle de reserva (Bottom Sheet / Screen):**
- Hero con ícono de estado
- Código de reserva prominente
- Grid info: fecha, duración, estado, servicio
- Resumen de pago
- Notas del cliente
- Acciones según estado: Aceptar/Rechazar (pending) · Completar (confirmed)

**API:**
- `GET /artists/dashboard/me/bookings?page=1` → `{ bookings: [], total, page, totalPages, artistId }`
- `PATCH /artists/dashboard/me/bookings/{id}/accept`
- `PATCH /artists/dashboard/me/bookings/{id}/decline` body: `{ reason, artistId }`
- `PATCH /artists/dashboard/me/bookings/{id}/complete`

**Nota:** el backend devuelve TODOS los estados incluyendo canceladas. El total en app incluye canceladas (diferencia intencional con web).

---

### 4.3 Agenda / Calendario (`CalendarScreen`)
**Top bar custom** (sin ActionBar).

**Calendario mensual:**
- Días de la semana: DOM LUN MAR MIÉ JUE VIE SÁB
- Celda seleccionada: círculo `piumsOrange`
- Hoy: círculo `piumsOrange` con opacidad 12%
- Dots de estado por día: 🔴 Bloqueado · 🔵 Con reserva · 🟠 Bloq+reserva

**Leyenda:** fila horizontal debajo del calendario

**Agenda del día:**
- Fecha formateada en español
- Tiles: "RESERVAS — X Sesiones" + "ESTADO — Disponible"

**Acciones:**
- Botón "Bloquear día" (naranja, full width)
- Pills: "Disponible" (verde) + "Horarios" (naranja)

**Próximas reservas:** lista de slots con hora

**API:**
- `GET /artists/{artistId}/blocked-slots`
- `POST /blocked-slots` body: `{ artistId, startTime, endTime, reason, isRecurring }`
- `DELETE /blocked-slots/{id}`

---

### 4.4 Mensajes (`MessagesScreen`)
**Search bar** en top.

**Conversation Row:**
- Avatar circular con inicial del cliente + color por estado
- Nombre + badge de estado (Activa/Pendiente/Cerrada)
- Badge naranja con conteo de no leídos
- Timestamp relativo

**Chat Detail:**
- Burbujas: artista = derecha naranja, cliente = izquierda gris
- Input bar con TextField + botón send (`paperplane`)
- Marca conversación como leída al abrir

**API:**
- `GET /chat/conversations` → `{ conversations: [] }` o array directo
- `GET /chat/messages/{conversationId}`
- `POST /chat/messages` body: `{ conversationId, content, type: "TEXT" }`
- `PATCH /chat/conversations/{id}/read`

**Mapeo conversación:** El backend devuelve `userId` (cliente) — mostrar "Cliente ···XXXXXX" si no hay nombre.

---

### 4.5 Más (`MoreMenuScreen`)
**Lista agrupada** (equivale a `List.insetGrouped`):

**Sección perfil:**
- Avatar 50dp + nombre + email + badge "Artista Pro" naranja

**Sección MAIN:**
- Servicios (naranja) · Ausencias/Viajes (purple) · Tutorial (amber)

**Sección FINANCE:**
- Billetera (verde) · Facturas (indigo)

**Sección CUENTA:**
- Reseñas (amarillo) · Quejas (warning) · Configuración (gris)

**Cerrar sesión** (destructivo, centrado)

**Sheets:**
- Perfil, Servicios, Ausencias, Reseñas, Quejas, Configuración

---

### 4.6 Perfil (`ProfileScreen`)
- Foto/avatar + nombre + profesión + badge verificado
- Stats: clientes, servicios completados, ingresos mes, rating
- Sección "Mis Servicios"
- Sección "Información"

**API:** `GET /artists/dashboard/me`

---

### 4.7 Servicios (`ServicesScreen`)
- Lista de servicios activos/inactivos
- Crear / editar / eliminar / toggle activo
- Selección de categoría (dropdown)

**API:**
- `GET /catalog/services?artistId={id}`
- `POST /catalog/services` body: `{ artistId, name, slug, description, categoryId, pricingType, basePrice (centavos), durationMin }`
- `PUT /catalog/services/{id}`
- `DELETE /catalog/services/{id}`
- `PATCH /catalog/services/{id}/toggle-status`
- `GET /catalog/categories`

**Nota precios:** el backend usa **centavos** (`basePrice: Int`). Dividir entre 100 para mostrar. Multiplicar por 100 al enviar.

---

### 4.8 Configuración (`SettingsScreen`)
- Toggle Modo Oscuro / Claro
- Notificaciones push
- Cerrar sesión
- Versión de app

**ThemeManager:** persistir preferencia en SharedPreferences / DataStore.

---

### 4.9 Reseñas (`ReviewsScreen`)
- Lista de reseñas recibidas con rating (1-5 estrellas)
- Opción de responder a reseña
- Rating promedio en header

**API:**
- `GET /reviews/reviews?artistId={id}&page=1`
- `POST /reviews/reviews/{id}/respond` body: `{ message }`

---

### 4.10 Quejas / Disputas (`DisputasScreen`)
- Lista de disputas (como reportante y reportado)
- Detalle con hilo de mensajes
- Añadir mensaje

**API:**
- `GET /disputes/me` → `{ asReporter: [], asReported: [], total }`
- `GET /disputes/{id}`
- `POST /disputes/{id}/messages` body: `{ message }`

---

### 4.11 Verificación (`VerificacionScreen`)
- Upload de documentos de identidad (frente, reverso, selfie)
- Estado de verificación

**API:**
- `GET /auth/me`
- `POST /users/documents/upload?folder={tipo}` (multipart)

---

## 5. Autenticación

### Login
- `POST /auth/login` body: `{ email, password }`
- Response: `{ token, refreshToken, user: { id, email, nombre/name, role } }`
- Guardar token en `EncryptedSharedPreferences` / `Keystore`

### Auto-login
- Al iniciar app, leer token guardado
- Llamar `GET /auth/profile` para validar sesión activa
- Si 401: borrar token y mostrar Login

### Headers requeridos
```
Authorization: Bearer {token}
Content-Type: application/json
```

### Logout
- `POST /auth/logout`
- Borrar token local

---

## 6. Configuración de red

```kotlin
// Base URLs
const val BASE_URL = "https://piums.com/api"
const val STAGING_URL = "https://staging.piums.com/api"
const val LOCAL_URL = "http://10.0.2.2:3000/api"  // Emulador Android → localhost Mac

// En desarrollo usar LOCAL_URL o STAGING_URL
// En release usar BASE_URL
```

> **Importante Android:** En emulador, `localhost` de la Mac se accede como `10.0.2.2`. En dispositivo físico, usar la IP local de la Mac (ej. `192.168.1.X`).

---

## 7. Modelos de datos principales

### Booking
```kotlin
data class Booking(
    val id: String,           // remoteId del backend
    val code: String?,        // ej. "PIU-2026-000013"
    val serviceName: String?,
    val clientId: String?,
    val scheduledDate: Date,  // startAt ?? scheduledDate (ISO8601)
    val duration: Int,        // minutos
    val totalPrice: Double,   // backend en centavos → dividir /100
    val status: BookingStatus,
    val clientNotes: String?,
    val artistNotes: String?
)

enum class BookingStatus { PENDING, CONFIRMED, IN_PROGRESS, COMPLETED, CANCELLED, NO_SHOW }
```

### Service
```kotlin
data class Service(
    val id: String,
    val artistId: String,
    val name: String,
    val description: String?,
    val basePrice: Int,       // centavos
    val pricingType: String,  // FIXED, HOURLY, PER_SESSION
    val durationMin: Int?,
    val status: String,       // ACTIVE, INACTIVE, DRAFT
    val categoryId: String,
    val category: ServiceCategory?
)
```

### ArtistProfile
```kotlin
data class ArtistProfile(
    val id: String,
    val artistName: String?,
    val nombre: String?,
    val email: String?,
    val bio: String?,
    val category: String?,
    val rating: Double?,
    val reviewsCount: Int?,
    val isVerified: Boolean?,
    val yearsExperience: Int?
)
// displayName = artistName ?: nombre ?: "Artista"
```

---

## 8. Componentes UI reutilizables

### PiumsAvatarView
- Círculo con gradiente naranja → amber
- Iniciales en blanco (máx 2 letras)
- Si hay `imageURL`: cargar con Coil/Glide

### StatusBadge (Capsule)
- Fondo = color con 12% opacidad
- Texto = color sólido
- Colores: pending=orange, confirmed=blue, completed=green, cancelled/noShow=red

### FilterChip
- Seleccionado: fondo `piumsOrange`, texto blanco
- No seleccionado: fondo `surfaceContainer`, texto primario
- Con badge numérico opcional

### TopBar custom
```
[Avatar 38dp] ←→ [PiumsLogo 40-52dp] ←→ [Acción icon 38dp]
```
Fondo: `surfaceVariant` (`#1C1C1E` dark). Sin elevation/shadow visible.

---

## 9. Patrones de diseño

- **Modo oscuro por defecto** — ThemeManager guarda preferencia
- **Estados vacíos:** ilustración con círculos concéntricos naranjas + ícono + texto + botón acción
- **Pull to refresh** en todas las listas
- **Feedback optimista:** al enviar mensaje, añadir al hilo localmente antes de confirmar API
- **Fallback mock data:** si la API falla en bookings/dashboard, mostrar datos de ejemplo con banner de error
- **Logging de red:** en DEBUG, loggear HTTP status + primeros 800 chars del JSON para diagnóstico

---

## 10. Onboarding (primera vez)

3 pantallas con logo, ilustración y descripción:
1. "Gestiona tus reservas" 
2. "Conecta con tus clientes"
3. "Controla tus ingresos"

Guardar `hasSeenArtistOnboarding = true` en SharedPreferences al completar.

---

## 11. Splash Screen

- Fondo: `piumsOrange` (`#FF6B35`)
- Logo blanco centrado (76 dp)
- Texto "Panel de Artistas" blanco/75% opacidad
- ProgressIndicator circular blanco
- Duración mínima: 1.5 segundos + auto-login en paralelo
