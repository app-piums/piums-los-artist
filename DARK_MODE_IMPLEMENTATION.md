# Implementación de Modo Oscuro en Piums iOS

> Guía para replicar el sistema de tema (claro/oscuro) en la app de cliente **PiumsCliente**.

---

## Resumen

El sistema usa un `ThemeManager` singleton (`ObservableObject`) que persiste la preferencia en `UserDefaults` y la aplica tanto a nivel SwiftUI (`.preferredColorScheme`) como a nivel UIKit (`overrideUserInterfaceStyle`) para cubrir todos los casos, incluyendo sheets y teclados.

---

## Paso 1 — Crear `ThemeManager`

Añadir al archivo `PiumsClienteApp.swift` (o en un archivo separado `ThemeManager.swift`):

```swift
import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var storedScheme: String {
        didSet {
            UserDefaults.standard.set(storedScheme, forKey: "piums_color_scheme")
            // Se aplica inmediatamente a todas las ventanas UIKit
            DispatchQueue.main.async { self.applyToWindows() }
        }
    }

    private init() {
        self.storedScheme = UserDefaults.standard.string(forKey: "piums_color_scheme") ?? "light"
    }

    /// Devuelve el ColorScheme para SwiftUI (.preferredColorScheme)
    var colorScheme: ColorScheme? {
        switch storedScheme {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    /// Aplica el estilo a TODAS las ventanas UIKit (incluyendo sheets)
    func applyToWindows() {
        let style: UIUserInterfaceStyle
        switch storedScheme {
        case "light": style = .light
        case "dark":  style = .dark
        default:      style = .unspecified
        }
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for window in ws.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}
```

**Notas clave:**
- `static let shared` → singleton, siempre la misma instancia en toda la app
- `didSet` llama `applyToWindows()` automáticamente al cambiar el valor
- `DispatchQueue.main.async` evita modificar UI fuera del hilo principal
- El default es `"light"` para que el toggle empiece en OFF

---

## Paso 2 — Conectar al `App` entry point

En `PiumsClienteApp.swift`, reemplazar el `.environment(\.colorScheme, .light)` actual:

```swift
// ANTES (cliente actual fuerza modo claro siempre):
RootView()
    .environment(\.colorScheme, .light)

// DESPUÉS (respeta la preferencia del usuario):
@main
struct PiumsClienteApp: App {
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(themeManager.colorScheme)   // ← SwiftUI
                .environmentObject(themeManager)                   // ← propaga a toda la app
                .onAppear { themeManager.applyToWindows() }        // ← UIKit al iniciar
                .onChange(of: themeManager.storedScheme) { _, _ in
                    themeManager.applyToWindows()                  // ← UIKit en cambios
                }
                // ... resto de modificadores existentes
        }
    }
}
```

> ⚠️ **Importante:** Eliminar o comentar la línea `UIApplication.shared.connectedScenes...forEach { $0.overrideUserInterfaceStyle = .light }` que hay en el `onAppear` actual del cliente, ya que `ThemeManager.applyToWindows()` reemplaza esa lógica.

---

## Paso 3 — Añadir el Toggle en `SettingsView`

En la vista de configuración del cliente, añadir una sección de apariencia:

```swift
struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    // ...existing code...

    var body: some View {
        NavigationView {
            List {
                // ...existing sections...

                // ── Apariencia ──
                Section("Apariencia") {
                    Toggle(isOn: Binding(
                        get: { themeManager.storedScheme == "dark" },
                        set: { themeManager.storedScheme = $0 ? "dark" : "light" }
                    )) {
                        Label("Modo oscuro", systemImage: "moon.fill")
                    }
                    .tint(Color.piumsOrange) // o el color primario del cliente
                }

                // ...existing sections...
            }
            // ...existing code...
        }
        // ← CRÍTICO: aplicar aquí para que el sheet reaccione en tiempo real
        .preferredColorScheme(themeManager.colorScheme)
    }
}
```

> ⚠️ El `.preferredColorScheme(themeManager.colorScheme)` al final del `NavigationView` es **obligatorio** para que el cambio se refleje inmediatamente dentro del sheet sin necesidad de cerrarlo.

---

## Paso 4 — Pasar `ThemeManager` a todos los sheets

Cualquier `.sheet` que presente `SettingsView` **debe** pasar el environmentObject explícitamente, porque los sheets en SwiftUI no heredan automáticamente el environment del padre:

```swift
// En cualquier vista que presente SettingsView:
.sheet(isPresented: $showSettings) {
    SettingsView()
        .environmentObject(ThemeManager.shared)  // ← obligatorio en sheets
}
```

> **¿Por qué?** Los sheets crean una nueva ventana UIKit (`UIWindow`) separada. Sin pasar el `environmentObject`, el toggle modifica una instancia diferente de `ThemeManager` que no está conectada a la ventana principal.

---

## Diagrama del flujo

```
Usuario activa toggle (ON)
        │
        ▼
themeManager.storedScheme = "dark"
        │
        ├─► UserDefaults.set("dark")          — persiste entre sesiones
        │
        ├─► applyToWindows()                  — UIKit: teclado, status bar, etc.
        │       └─► window.overrideUserInterfaceStyle = .dark
        │
        └─► @Published dispara objectWillChange
                │
                ▼
        SwiftUI re-renderiza vistas que observan themeManager
                │
                ▼
        .preferredColorScheme(.dark)          — toda la jerarquía SwiftUI
```

---

## Problemas comunes y soluciones

| Problema | Causa | Solución |
|---|---|---|
| El toggle cambia pero la UI no actualiza | `.preferredColorScheme` no está en el `NavigationView` de `SettingsView` | Añadir `.preferredColorScheme(themeManager.colorScheme)` dentro de `SettingsView.body` |
| Al desactivar el toggle no vuelve a claro | El sheet usa una instancia diferente de `ThemeManager` | Pasar `.environmentObject(ThemeManager.shared)` al sheet |
| El teclado o status bar no cambia de color | `overrideUserInterfaceStyle` no se aplica a todos los windows | Usar `for-in` explícito sobre todas las `UIWindowScene` |
| Al relanzar la app no recuerda el tema | `storedScheme` no se persiste | Usar `UserDefaults.standard.set(...)` en `didSet` |
| Toggle empieza en estado incorrecto | Default no definido | Inicializar con `?? "light"` en `private init()` |

---

## Archivos modificados en PiumsArtist (referencia)

```
PiumsArtist/
├── PiumsArtistApp.swift          ← ThemeManager + integración en App
├── Views/
│   └── ProfileView.swift         ← Toggle en SettingsView + .preferredColorScheme
└── Views/
    └── MoreMenuView.swift        ← .environmentObject(ThemeManager.shared) al sheet
```

---

*Implementado en PiumsArtist — Abril 2026*
