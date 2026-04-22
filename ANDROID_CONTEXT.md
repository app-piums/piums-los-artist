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

### Paleta Piums (usada en Login/Auth — idéntica a app cliente)

| Token | Dark mode | Light mode | Uso |
|---|---|---|---|
| `piumsBackground` | `#121212` | `#FFFFFF` | Fondo login/auth |
| `piumsBackgroundSecondary` | `#1C1C1E` | `#F2F2F7` | Card del login (sheet) |
| `piumsBackgroundElevated` | `#28282A` | `#FFFFFF` | Campos de texto, botones sociales |
| `piumsLabel` | `#FFFFFF` | `#000000` | Texto primario en login |
| `piumsLabelSecondary` | `#8E8E93` | `#6E6E73` | Texto secundario en login |
| `piumsSeparator` | `#383840` | `#C7C7CC` | Divisores |

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
- Precio en naranja (formato `$ 0.00` — moneda USD)
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
- Botón "Bloquear día" (naranja, full width) → POST `/blocked-slots`
- Pill izquierdo: dinámico — muestra "Desbloquear" (verde, `lock.open`) si el día está bloqueado, o "Disponible" (gris, `checkmark.circle`) si no. Tap en "Desbloquear" → DELETE `/blocked-slots/{id}`
- Pill "Horarios" (naranja) → sheet con grid de slots del día

**Estado bloqueado:** guardar un `Map<Date, slotId>` al cargar blocked-slots para poder identificar el ID a eliminar cuando el artista quiere desbloquear un día.

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

**Cambiar foto de perfil:**
- Botón cámara sobre el avatar → abre el selector de imágenes nativo (MediaPicker / PhotoPicker Android)
- Comprimir imagen a JPEG 75% antes de enviar
- `POST /users/avatar/upload` — multipart/form-data, campo `file`
- Response esperado: `{ url: "https://..." }` — actualizar avatar en UI
- Mostrar spinner/indicador de carga mientras sube; deshabilitar el botón durante el upload
- Si la respuesta no contiene `url`, intentar `imageUrl` como fallback

**Sección "Configuración" (menú inferior del perfil):**
- **Notificaciones** → abre Configuración del sistema (Settings de Android para la app), no un toggle in-app. Usar `Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)` con `EXTRA_APP_PACKAGE`.
- **Privacidad** → bottom sheet con texto legal de política de privacidad + link a `https://piums.com`
- **Ayuda / Soporte** → bottom sheet con email de contacto y centro de ayuda

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
- `DELETE /catalog/services/{id}?artistId={artistId}` — pasar `artistId` como **query param** (el gateway hace HTTP 308 redirect que descarta el body)
- `PATCH /catalog/services/{id}/toggle-status` body: `{ artistId }` — requerido para autorización
- `GET /catalog/categories`

**Nota precios:** el backend usa **centavos** (`basePrice: Int`). Dividir entre 100 para mostrar. Multiplicar por 100 al enviar.

---

### 4.8 Configuración (`SettingsScreen`)
- Toggle Modo Oscuro / Claro
- Notificaciones push
- Editar perfil (nombre, teléfono, bio) → `PUT /users/me/profile`
- Cambiar contraseña → `PATCH /users/me/password`
- Cerrar sesión
- Versión de app

**ThemeManager:** persistir preferencia en SharedPreferences / DataStore.

**Botón "Editar Perfil"** en ProfileScreen debe abrir directamente el formulario de edición (no navegar a Settings). SettingsScreen se accede desde el ícono de engranaje en las top bars.

---

### 4.9 Reseñas (`ReviewsScreen`)
- Lista de reseñas recibidas con rating (1-5 estrellas)
- Opción de responder a reseña
- Rating promedio en header

**API:**
- `GET /reviews?artistId={id}&page=1` → `{ reviews: [], pagination: { page, limit, total, totalPages } }`
- `POST /reviews/{id}/respond` body: `{ message }`
- `POST /reviews/{id}/report` body: `{ reason, description }`

> ⚠️ La respuesta usa paginación **anidada** (`pagination.total`, `pagination.totalPages`), no campos planos en el nivel raíz.

---

### 4.10 Quejas / Disputas (`DisputasScreen`)
- Lista de disputas (como reportante y reportado)
- Detalle con hilo de mensajes
- Añadir mensaje
- Botón `+` en toolbar para crear nueva disputa

**Crear disputa — formulario:**
- Selector de tipo (7 opciones): `SERVICE_QUALITY`, `PAYMENT_DISPUTE`, `CANCELLATION`, `NO_SHOW`, `COMMUNICATION`, `FRAUD`, `OTHER`
- Asunto (mínimo 5 caracteres)
- Descripción (mínimo 10 caracteres)
- Booking ID (**obligatorio** — el backend rechaza la petición sin él)
- Botón "Enviar" deshabilitado hasta que todos los campos sean válidos (incluyendo bookingId)

**API:**
- `GET /disputes/me` → `{ asReporter: [], asReported: [], total }`
- `GET /disputes/{id}`
- `POST /disputes/{id}/messages` body: `{ message }`
- `POST /disputes` body: `{ bookingId: String, disputeType: String, subject: String, description: String }`

> ⚠️ `bookingId` es **obligatorio** (no nullable). El backend devuelve error si se omite o se envía null.

---

### 4.11 Verificación (`VerificacionScreen`)
- Upload de documentos de identidad (frente, reverso, selfie)
- Estado de verificación

**API:**
- `GET /auth/me`
- `POST /users/documents/upload?folder={tipo}` (multipart)

---

## 5. Autenticación

### Login — flujo email-first + social (estilo Platzi)

El login tiene **3 estados** en la misma card:

**Paso 1 — Email** (estado inicial)
- Campo de correo electrónico
- Botón "Continuar →" (habilitado solo con email válido → navega a paso 2)
- Separador con punto central
- Botón colapsado "Continúa con Google, Facebook o TikTok" (→ abre panel social)

**Paso 2 — Contraseña** (tras ingresar email válido)
- Cabecera con flecha atrás + email mostrado
- Campo de contraseña con toggle de visibilidad
- Botón "Iniciar sesión" (habilitado solo si hay contraseña)
- Enlace "¿Olvidaste tu contraseña?"

**Panel social** (al tocar el botón colapsado)
- Encabezado "Ingresar o crear cuenta con:"
- 3 botones de proveedor: Google, Facebook, TikTok (cada uno con icono + texto)
- Separador con punto central
- Botón "Continúa con correo y contraseña" (→ regresa al paso 1)
- Texto de términos de servicio

---

#### Login con correo

```
POST /auth/login
Body: { email, password }
Response: { token, refreshToken, user: { id, email, nombre, role }, redirectUrl }
```

- `redirectUrl` es para web — ignorarlo en el app móvil
- El response **NO incluye `expiresIn`** — el access token dura 15 minutos por defecto; decodificar el campo `exp` del JWT para saber cuándo vence
- Guardar `token` y `refreshToken` en `EncryptedSharedPreferences`

---

#### Login con Google — flujo nativo Firebase (recomendado)

**No usar web OAuth para Google.** Usar el SDK nativo de Firebase + Google Sign-In para obtener un ID token y canjearlo por el JWT de Piums.

**Dependencias Android (build.gradle):**
```gradle
implementation 'com.google.firebase:firebase-auth-ktx'
implementation 'com.google.android.gms:play-services-auth:21.x.x'
```

**Flujo completo:**

```kotlin
// 1. Configurar Google Sign-In
val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
    .requestIdToken("967320828042-up3edqurf8ug00rq5eketosnr4a3u9k0.apps.googleusercontent.com")
    .requestEmail()
    .build()
val googleSignInClient = GoogleSignIn.getClient(context, gso)

// 2. Lanzar intent de Google
val signInIntent = googleSignInClient.signInIntent
startActivityForResult(signInIntent, RC_SIGN_IN)

// 3. En onActivityResult — obtener Google credential
val task = GoogleSignIn.getSignedInAccountFromIntent(data)
val account = task.getResult(ApiException::class.java)
val googleIdToken = account.idToken!!

// 4. Autenticar con Firebase
val firebaseCredential = GoogleAuthProvider.getCredential(googleIdToken, null)
FirebaseAuth.getInstance().signInWithCredential(firebaseCredential).await()

// 5. Obtener Firebase ID token
val firebaseIdToken = FirebaseAuth.getInstance().currentUser!!.getIdToken(false).await().token!!

// 6. Canjear por JWT de Piums
POST /auth/firebase
Body: { "idToken": firebaseIdToken, "role": "artista" }

// 7. Guardar tokens de Piums
// Response: { token, refreshToken, user, isNewUser }
```

**Notas críticas:**
- El `CLIENT_ID` para `requestIdToken` es `967320828042-up3edqurf8ug00rq5eketosnr4a3u9k0.apps.googleusercontent.com` (del `GoogleService-Info.plist` / `google-services.json`)
- El archivo `google-services.json` va en `app/` del módulo Android — equivalente al `GoogleService-Info.plist` de iOS
- `role` es **case-sensitive**: enviar siempre `"artista"` en minúsculas — `"ARTISTA"` devuelve error 400
- Si `isNewUser: true`, el backend ya crea el perfil de artista automáticamente (bootstrap interno) — no es necesario llamar ningún endpoint adicional
- El access token resultante dura **15 minutos**; el refresh token dura **7 días**
- El response **NO incluye `expiresIn`** — programar el refresh a los 14 minutos o decodificar `exp` del JWT

**Inicialización de Firebase en Android (`Application.onCreate`):**
```kotlin
FirebaseApp.initializeApp(this)
```

---

#### Facebook y TikTok

**No implementados.** El backend no tiene habilitados estos proveedores para la app de artista. No agregar estos botones en la UI.

---

#### Endpoint `POST /auth/firebase` — detalles verificados en código

```
POST /auth/firebase
Body: { "idToken": string, "role": "artista" }

Response 200:
{
  "token": "eyJhbGc...",           // Access token Piums (15 min)
  "refreshToken": "eyJhbGc...",    // Refresh token Piums (7 días)
  "user": {
    "id": "uuid",
    "_id": "uuid",                 // Alias para mobile
    "email": "string",
    "nombre": "string",
    "role": "artista",
    "googleId": "string",
    "avatar": "url | null",
    "emailVerified": true,
    "status": "ACTIVE",
    "documentFrontUrl": "url | null",
    "documentBackUrl": "url | null",
    "documentSelfieUrl": "url | null"
  },
  "isNewUser": true | false
}
```

**Comportamiento interno verificado:**
- El backend valida el token con Identity Toolkit REST API (`identitytoolkit.googleapis.com`) usando `FIREBASE_API_KEY`
- Si `isNewUser: true` y `role: "artista"`, llama internamente a `POST /artists/internal/bootstrap` — el perfil se crea automáticamente
- Si el bootstrap falla, el login igual devuelve token (fire-and-forget) — el perfil puede no existir; monitorear logs del servidor
- `emailVerified` siempre se marca como `true` para logins de Google, independientemente del valor de Google

---

#### Iconos de providers (sin SDK externo)
- Google: letra "G" blanca sobre círculo blanco + texto azul `#4285F4`
- Facebook: letra "f" blanca sobre círculo azul `#3B5CA0`
- TikTok: ícono de nota musical blanco sobre círculo negro `#000000`

---

### Registro
- `POST /auth/register` body: `{ email, password, name, nombre: name, role: "ARTIST", phone: null }`
- Enviar **tanto `name` como `nombre`** con el mismo valor — el backend acepta ambos según versión.
- Usar siempre `role: "ARTIST"` — campo obligatorio, no debe omitirse.
- ⚠️ El backend puede ignorar el `role` enviado y asignar `"cliente"` por defecto. **Validar el rol del JWT recibido** tras el registro: si no es `artist/artista`, mostrar mensaje de error claro ("Esta cuenta no tiene permisos de artista. Contacta a soporte@piums.io") y no navegar al panel.

---

### Olvidé mi contraseña (flujo 2 pasos)

**Paso 1 — Solicitar código:**
- `POST /auth/forgot-password` body: `{ email }`

**Paso 2 — Restablecer contraseña:**
- `POST /auth/reset-password` body: `{ token, newPassword }`
- Validaciones: contraseña mínimo 6 chars, ambas contraseñas deben coincidir
- Botón "Ya tengo un código →" permite saltar directamente al paso 2
- Auto-dismiss / navegación automática tras 1.8s en éxito

**UI:** Flujo de 2 steps en la misma pantalla. Feedback de error en rojo, éxito en verde.

---

### Refresh de token

```
POST /auth/refresh
Body: { "refreshToken": string }

Response: { "token": string, "refreshToken": string }
```

- El response **NO incluye `user`** — no actualizar datos del usuario aquí
- Ambos tokens se renuevan (token rotation activo)
- Guardar el nuevo `refreshToken` en `EncryptedSharedPreferences` — el anterior queda invalidado
- Programar el refresh 1 minuto antes de que expire el access token (o al recibir 401)

---

### Auto-login

1. Al iniciar app, leer token guardado de `EncryptedSharedPreferences`
2. Decodificar el JWT localmente para verificar `exp` — si ya expiró, intentar refresh
3. Si el refresh falla, borrar tokens y mostrar Login
4. Llamar `GET /auth/me` para confirmar sesión activa y obtener estado de verificación

---

### Endpoint `GET /auth/me` — estructura verificada

```
GET /auth/me
Headers: Authorization: Bearer {token}

Response: {
  "user": {                          // ⚠️ SIEMPRE envuelto en "user", NO plano
    "id": "uuid",
    "email": "string",
    "nombre": "string",
    "role": "artista",
    "avatar": "url | null",
    "documentFrontUrl": "url | null",  // null si no ha subido documentos
    "documentBackUrl": "url | null",
    "documentSelfieUrl": "url | null"
  }
}
```

⚠️ Si al deserializar este response se trata como objeto plano (sin el wrapper `user`), `documentFrontUrl` siempre será `null` y la verificación nunca se activará. Usar siempre un DTO con `data class AuthMeResponse(val user: AuthMeUser)`.

---

### Logout

```
POST /auth/logout
Headers: Authorization: Bearer {token}
Body: { "refreshToken": string }   // Opcional pero recomendado — revoca el refresh token

Response: { "message": "Logout exitoso" }
```

- Borrar **todos** los datos locales: `auth_token`, `refresh_token`, `artist_backend_id`, caché de perfil
- Tokens en Android en `EncryptedSharedPreferences` (nunca en SharedPreferences planas)

---

### Onboarding completado

Llamar este endpoint al terminar el onboarding de artista (tanto si completa todos los pasos como si omite):

```
PATCH /auth/complete-onboarding
Headers: Authorization: Bearer {token}
Body: vacío

Response: { "user": { "id": "...", "onboardingCompletedAt": "..." } }
```

Guardar también `hasSeenArtistOnboarding = true` en `SharedPreferences` para no mostrar el onboarding al reiniciar la app.

---

### Headers requeridos
```
Authorization: Bearer {token}
Content-Type: application/json
```

---

## 6. Configuración de red

```kotlin
// Base URLs
const val BASE_URL = "https://piums.com/api"          // Producción (gateway Cloudflare)
const val STAGING_URL = "https://staging.piums.com/api"
const val LOCAL_URL = "http://10.0.2.2:3000/api"      // Emulador Android → localhost Mac

// Selección por entorno (equivalente al #if DEBUG / targetEnvironment de iOS):
// Emulador DEBUG          → LOCAL_URL
// Dispositivo físico DEBUG → STAGING_URL  ← CRÍTICO: el dispositivo no puede alcanzar localhost
// Release                 → BASE_URL
```

> **Crítico para dispositivos físicos:** En emulador, `localhost` de la Mac es `10.0.2.2`. En un **dispositivo físico** real, `localhost` no es alcanzable — usar siempre `STAGING_URL` para builds de debug en hardware real.

**Dominios de producción verificados (Cloudflare):**
| Servicio | URL |
|---|---|
| Gateway / API | `https://piums.com/api` |
| Web cliente | `https://client.piums.io` |
| Web artista | `https://artist.piums.io` |
| Web admin | `https://admin.piums.io` |
| Backend directo | `https://backend.piums.io/api` |

> El app móvil **siempre** usa el gateway (`piums.com/api`), nunca `backend.piums.io` directamente. El gateway maneja CORS permitiendo requests sin header `Origin` — las peticiones de `URLSession` (iOS) y `OkHttp` (Android) funcionan sin configuración adicional de CORS.

### URLSession / OkHttp recomendado
- Timeout de request: **30 segundos**
- Timeout de resource: **5 minutos** (para subida de archivos)
- `waitsForConnectivity = true` (iOS) / `retryOnConnectionFailure = true` (OkHttp)

### Almacenamiento de tokens (seguridad)
- `auth_token` y `refresh_token` → **EncryptedSharedPreferences** en Android / **Keychain** en iOS
- **NO** usar SharedPreferences planas ni UserDefaults — los tokens JWT son credenciales sensibles
- `artist_backend_id` → SharedPreferences planas es aceptable (no es credencial)

### Query parameters — encoding obligatorio
- Usar `Uri.Builder` (Android) / `URLComponents` (iOS) para construir URLs con parámetros de búsqueda
- **Nunca** interpolar strings directamente en la URL (`"q=$query"`) — rompe con espacios y caracteres especiales

### Monitor de conectividad
- Android: `ConnectivityManager` + `NetworkCallback`
- iOS: `NWPathMonitor` (framework `Network`)
- Mostrar banner de "Sin conexión" cuando `isConnected = false`

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
- **Sin mock data:** si la API falla, mostrar estado vacío con mensaje de error + botón "Reintentar". NO mostrar datos falsos en Dashboard ni Perfil. En Bookings/Mensajes también mostrar vacío con error visible.
- **Logging de red:** en DEBUG, loggear HTTP status + primeros 800 chars del JSON para diagnóstico

---

## 10. Onboarding de artista (wizard de configuración)

El onboarding es un wizard de **7 pasos** que se muestra al artista la primera vez que inicia sesión. Equivale al onboarding web en `PIUMS-FRONTEND/apps/web-artist`.

| Paso | Nombre | Descripción |
|---|---|---|
| 1 | **Bienvenida** | Pantalla de entrada con call-to-action |
| 2 | **Disciplina creativa** | Selección de categoría (Músico, DJ, Fotógrafo, etc.) |
| 3 | **Equipo** | Selección multi-opción del equipo por disciplina (NUEVO - igual que web) |
| 4 | **Portfolio y perfil** | Foto de perfil, bio, Instagram, link de portfolio |
| 5 | **Primer servicio** | Nombre, descripción, precio del servicio |
| 6 | **Tarifa base** | Rango de precio por hora (mín/máx), moneda USD, depósito |
| 7 | **Disponibilidad semanal** | Días y horarios activos por día |

**Paso 3 — Equipo (detalle):**
- Las opciones de equipo cambian según la disciplina elegida en el paso 2
- Multi-select con chips/tags agrupados por sección (ej: "Audio", "Instrumentos", "Iluminación" para músico)
- Se puede omitir — no es obligatorio
- El equipo seleccionado se envía al backend como `equipment: [String]` al crear el perfil

**APIs que se llaman al completar:**
1. `POST /catalog/services` — crear perfil de artista con disciplina, equipo, bio, links
2. `POST /artists/availability` — guardar disponibilidad semanal (solo si hay días activos)
3. `GET /artists/dashboard/me` — obtener el `artistId` del backend para crear el servicio
4. `POST /catalog/services` — crear el primer servicio si el artista lo completó
5. `PATCH /auth/complete-onboarding` — marcar onboarding como completado en el backend

**Al completar (o al omitir):**
- Guardar `hasSeenArtistOnboarding = true` en `SharedPreferences`
- Llamar `PATCH /auth/complete-onboarding`
- Navegar al dashboard principal

---

## 11. Tour interactivo (`TutorialManager`)

El tour es una **superposición sobre la app real** — no pantallas separadas. Se activa desde Más → Tutorial.

**Flujo:**
1. Sheet de introducción con grid 2×4 de 8 puntos de interés + estimado "~2 minutos"
2. Al pulsar "Iniciar tour interactivo" → cerrar sheet → activar overlay con 450ms de delay
3. El overlay navega automáticamente al tab correcto en cada paso

**Estructura del overlay (BottomSheet fijo):**
- Fondo oscuro semitransparente sobre el contenido (pero con la tab bar visible)
- Flecha apuntando al tab activo del paso actual
- Card con: número de paso, ícono circular de color, título, descripción, tip con borde
- Dots de progreso + botones Atrás / Siguiente / ¡Listo!

**Pasos y tabs (7 pasos):**
| Paso | Tab | Título | Color sugerido |
|---|---|---|---|
| 1 | Inicio (0) | Dashboard | naranja |
| 2 | Reservas (1) | Gestión de reservas | azul |
| 3 | Agenda (2) | Tu disponibilidad | verde |
| 4 | Mensajes (3) | Chat en tiempo real | índigo |
| 5 | Más (4) | Tus servicios | purple |
| 6 | Más (4) | Ausencias y viajes | cyan |
| 7 | Más (4) | Verificación y perfil | naranja |

**Posición de la flecha:** `(screenWidth / 5) * tabIndex + (screenWidth / 10)` desde la izquierda.

**Guardado de estado:** usar `SharedPreferences` para `hasCompletedTour` (no mostrar badge de "nuevo" tras completarlo).

---

## 12. Bugs conocidos del backend (workarounds activos)

| # | Endpoint | Problema | Workaround |
|---|----------|----------|------------|
| 1 | `POST /auth/register` | Asigna `role: "cliente"` ignorando el campo enviado | Validar rol en JWT de respuesta; si no es `artist/artista`, mostrar error y bloquear acceso |
| 2 | `DELETE /catalog/services/{id}` | Gateway HTTP 308 redirect descarta el body | Enviar `artistId` como query param en la URL |
| 3 | `PATCH /catalog/services/{id}/toggle-status` | Requiere `artistId` en body para autorización | Incluir siempre `{ artistId }` en el body |
| 4 | `GET /reviews` | Paginación anidada en `pagination{}`, no en campos raíz | Leer `response.pagination.total` y `response.pagination.totalPages` |
| 5 | `POST /disputes` | `bookingId` requerido aunque la UI lo trate como opcional | Hacer el campo obligatorio en el formulario |
| 6 | `GET /auth/me` | Response envuelto en `{ user: {...} }` — no es objeto plano | Deserializar con wrapper: `data class AuthMeResponse(val user: AuthMeUser)` |
| 7 | `POST /auth/refresh` | Response solo devuelve `{ token, refreshToken }` — sin `user` ni `expiresIn` | No actualizar datos del usuario al refrescar; usar solo los nuevos tokens |
| 8 | `POST /auth/firebase` | `role` es case-sensitive — solo `"artista"` y `"cliente"` en minúsculas | Enviar siempre en minúsculas; `"ARTISTA"` devuelve error 400 |
| 9 | `POST /auth/firebase` | No devuelve `expiresIn` en el response | El access token dura 15 min por defecto; decodificar `exp` del JWT o asumir 15 min |

---

## 11. Splash Screen

- Fondo: `piumsOrange` (`#FF6B35`)
- Logo blanco centrado (76 dp)
- Texto "Panel de Artistas" blanco/75% opacidad
- ProgressIndicator circular blanco
- Duración mínima: 1.5 segundos + auto-login en paralelo
