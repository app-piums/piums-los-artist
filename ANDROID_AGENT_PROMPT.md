# Prompt — Agente IA: Construir PiumsArtist Android

## Tu misión

Construye la app Android **PiumsArtist** — panel de gestión para artistas de la plataforma Piums. Es la versión Android de una app iOS existente en SwiftUI. Tu trabajo es producir una app Android nativa en Kotlin + Jetpack Compose con paridad funcional completa.

---

## Fuentes de verdad (léelas en este orden)

### 1. Documento de contexto — léelo primero y completo
```
/Users/piums/Desktop/PiumsArtistaios/PiumsArtist/ANDROID_CONTEXT.md
```
Contiene: colores, pantallas, APIs con body/response exactos, auth, modelos Kotlin, arquitectura, bugs conocidos con workarounds, flujo de navegación y setup del proyecto.

### 2. Código iOS — referencia de lógica y UI
Cuando necesites entender el comportamiento exacto de una pantalla, lee el archivo Swift correspondiente:

| Pantalla | Archivo iOS |
|---|---|
| Login / Auth | `PiumsArtist/Services/AuthService.swift` |
| Dashboard | `PiumsArtist/Views/DashboardView.swift` |
| Reservas | `PiumsArtist/Views/BookingsView.swift` |
| Agenda/Calendario | `PiumsArtist/Views/CalendarView.swift` |
| Mensajes | `PiumsArtist/Views/MessagesView.swift` |
| Menú Más | `PiumsArtist/Views/MoreMenuView.swift` |
| Perfil | `PiumsArtist/Views/ProfileView.swift` |
| Servicios | `PiumsArtist/Views/ServicesView.swift` |
| Reseñas | `PiumsArtist/Views/ReviewsView.swift` |
| Disputas | `PiumsArtist/Views/DisputasView.swift` |
| Ausencias | `PiumsArtist/Views/AbsencesView.swift` |
| Verificación | `PiumsArtist/Views/VerificacionView.swift` |
| Onboarding | `PiumsArtist/Views/ArtistOnboardingView.swift` |
| Tour interactivo | `PiumsArtist/Views/TourOverlayView.swift` |
| Olvidé contraseña | `PiumsArtist/Views/ForgotPasswordView.swift` |
| Endpoints API | `PiumsArtist/Services/APIService.swift` |
| Modelos de datos | `PiumsArtist/Services/APIModels.swift` |
| Manejo de errores | `PiumsArtist/Services/ErrorHandling.swift` |

Todos los archivos están en:
```
/Users/piums/Desktop/PiumsArtistaios/PiumsArtist/PiumsArtist/
```

---

## Reglas de traducción iOS → Android

| iOS / SwiftUI | Android / Compose |
|---|---|
| `@StateObject` / `@ObservedObject` | `ViewModel` + `StateFlow` / `collectAsState()` |
| `@Published` | `MutableStateFlow` |
| `NavigationStack` | `NavHost` + `NavController` |
| `.sheet()` | `ModalBottomSheet` |
| `.fullScreenCover()` | `Dialog(fullScreen = true)` o nueva pantalla en nav |
| `List` / `ForEach` | `LazyColumn` / `LazyRow` |
| `TabView` | `NavigationBar` + `NavHost` |
| `AsyncImage` | `coil-compose` → `AsyncImage` |
| Keychain | `EncryptedSharedPreferences` |
| `UserDefaults` | `SharedPreferences` o `DataStore` |
| `NWPathMonitor` | `ConnectivityManager` + `NetworkCallback` |
| `URLComponents` | `Uri.Builder` |
| `multipart/form-data` | `MultipartBody` con OkHttp |
| `#if DEBUG` / `targetEnvironment` | `BuildConfig.DEBUG` + detección de emulador |

---

## Stack técnico obligatorio

```kotlin
// UI
Jetpack Compose + Material 3

// Arquitectura
MVVM + Clean Architecture
Hilt para inyección de dependencias

// Red
Retrofit 2 + OkHttp 4 + Gson
Interceptor de autenticación con refresh automático en 401

// Imágenes
Coil Compose

// Seguridad
EncryptedSharedPreferences para auth_token y refresh_token
SharedPreferences planas para artist_backend_id (no es credencial)

// Firebase
firebase-auth-ktx
play-services-auth (Google Sign-In)
```

---

## Configuración de red por entorno

```kotlin
// En emulador Android (DEBUG) → localhost de la Mac
const val LOCAL_URL = "http://10.0.2.2:3000/api"

// En dispositivo físico (DEBUG) → staging
const val STAGING_URL = "https://staging.piums.com/api"

// Release → producción
const val BASE_URL = "https://piums.com/api"

fun getBaseUrl(): String {
    if (!BuildConfig.DEBUG) return BASE_URL
    return if (isEmulator()) LOCAL_URL else STAGING_URL
}

fun isEmulator(): Boolean =
    android.os.Build.FINGERPRINT.contains("generic") ||
    android.os.Build.MODEL.contains("Emulator")
```

---

## Google Sign-In — flujo exacto

```kotlin
// 1. Configurar con el CLIENT_ID del google-services.json
val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
    .requestIdToken("967320828042-up3edqurf8ug00rq5eketosnr4a3u9k0.apps.googleusercontent.com")
    .requestEmail()
    .build()

// 2. Lanzar Google Sign-In → obtener googleIdToken
// 3. Crear Firebase credential con ese token
// 4. signInWithCredential(firebaseCredential)
// 5. currentUser.getIdToken(false) → firebaseIdToken

// 6. POST https://piums.com/api/auth/firebase
//    Body: { "idToken": firebaseIdToken, "role": "artista" }
//    ⚠️ "artista" en minúsculas — "ARTISTA" devuelve error 400

// 7. Response: { token, refreshToken, user, isNewUser }
//    Guardar token en EncryptedSharedPreferences
//    Guardar refreshToken en EncryptedSharedPreferences
```

---

## Archivo `google-services.json`

Pedir al equipo el archivo `google-services.json` del proyecto Firebase `piums-artista` y colocarlo en `app/`. Sin este archivo, Google Sign-In no funciona.

---

## Orden de construcción recomendado

Construye en este orden para poder probar desde el primer día:

1. **Setup del proyecto** — estructura de módulos, Hilt, Retrofit, OkHttp con interceptor, EncryptedSharedPreferences
2. **AuthService + LoginScreen** — email/password + Google Sign-In, guardado de tokens, auto-login
3. **MainScreen** — Bottom Navigation con 5 tabs vacíos
4. **DashboardScreen** — top bar, stats 2×2, listas de reservas
5. **BookingsScreen** — filter chips, cards, detalle con acciones
6. **CalendarScreen** — calendario mensual, bloqueo de días (Map<Date, slotId>)
7. **MessagesScreen** — lista conversaciones, chat con burbujas por dirección
8. **MoreMenuScreen** — menú agrupado con sheets
9. **ProfileScreen** — stats, cambio de foto (multipart)
10. **ServicesScreen** — CRUD completo
11. **ReviewsScreen** — lista con respuesta
12. **DisputasScreen** — lista + detalle + nueva disputa
13. **AbsencesScreen** — VACATION / ABROAD_WORK
14. **NotificationsPanel** — panel desde campana del top bar
15. **VerificacionScreen** — upload de 3 documentos en secuencia
16. **OnboardingScreen** — wizard 7 pasos
17. **TourOverlay** — superposición interactiva sobre la app real

---

## Comportamientos críticos que no deben omitirse

- **Sin mock data nunca** — si la API falla, mostrar estado vacío + "Reintentar"
- **Modo oscuro por defecto** — guardar preferencia en DataStore
- **Pull to refresh** en todas las listas
- **`artistBackendId`** — obtenerlo de `GET /artists/dashboard/me` al iniciar sesión, guardarlo en SharedPreferences, borrarlo en logout. Sin él fallan Servicios, Calendario y Reservas
- **`currentUserId` del JWT** — decodificar campo `id` del payload para determinar dirección de burbujas en chat
- **Precios en centavos** — dividir entre 100 para mostrar, multiplicar por 100 al enviar
- **`bookingId` en disputas** — obligatorio, hacer el campo requerido en el formulario
- **`role` en Firebase auth** — enviar siempre `"artista"` en minúsculas
- **`GET /auth/me`** — el response tiene wrapper `{ user: {...} }`, NO es plano
- **`POST /auth/refresh`** — el response solo devuelve `{ token, refreshToken }`, sin `user`
- **`DELETE /catalog/services/{id}`** — enviar `artistId` como query param, no en body
- **Formato dual de `/reviews`** — manejar paginación anidada (`pagination.total`) y plana (`total`) como fallback

---

## Definición de "terminado"

La app está lista cuando:
- [ ] Google Sign-In funciona en dispositivo físico real
- [ ] Todas las pantallas consumen datos reales del backend (sin mock data)
- [ ] El token se refresca automáticamente en 401 sin cerrar sesión
- [ ] Logout limpia todos los datos locales
- [ ] El onboarding se muestra solo la primera vez y llama a `PATCH /auth/complete-onboarding`
- [ ] Modo oscuro y claro funcionan correctamente
- [ ] Pull to refresh funciona en todas las listas
- [ ] La app funciona tanto en emulador (→ localhost) como en dispositivo físico (→ staging)
