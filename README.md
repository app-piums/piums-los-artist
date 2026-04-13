# Piums Artista - iOS App

Aplicación móvil iOS nativa para artistas de la plataforma Piums, desarrollada en SwiftUI con arquitectura MVVM.

## 🚀 Características Principales

### ✨ Funcionalidades MVP Implementadas
- **Dashboard**: Métricas del día, próximas reservas y resumen de rendimiento
- **Gestión de Reservas**: Lista filtrable con acciones de aceptar/rechazar/completar
- **Calendario**: Vista mensual con gestión de disponibilidad y horarios
- **Mensajería**: Chat integrado con clientes y búsqueda de conversaciones
- **Perfil**: Información del artista, estadísticas y configuración

### 🏗️ Arquitectura
- **Framework**: SwiftUI
- **Patrón**: MVVM (Model-View-ViewModel)
- **Persistencia**: SwiftData
- **Navegación**: TabView nativa de iOS
- **Componentes**: Sistema de design consistente

## 📱 Pantallas

### 1. Dashboard
- Resumen diario de reservas
- Métricas de rendimiento (reservas confirmadas, pendientes, ingresos)
- Próximas citas del día

### 2. Reservas
- Lista completa de todas las reservas
- Filtros por estado (Todas, Pendientes, Confirmadas, Completadas, Canceladas)
- Acciones directas para cada reserva
- Detalles del cliente y servicio

### 3. Calendario
- Vista mensual interactiva
- Gestión de disponibilidad por día
- Slots de tiempo configurables
- Indicadores visuales de reservas y disponibilidad

### 4. Mensajes
- Lista de conversaciones con clientes
- Búsqueda de conversaciones
- Chat en tiempo real con interfaz nativa
- Indicadores de mensajes no leídos

### 5. Perfil
- Información personal del artista
- Estadísticas de rendimiento
- Lista de servicios ofrecidos
- Configuración de la aplicación

## 🛠️ Tecnologías

- **SwiftUI**: Framework de interfaz de usuario declarativa
- **SwiftData**: Persistencia local de datos
- **Combine**: Programación reactiva
- **SF Symbols**: Iconografía consistente
- **iOS 17.0+**: Versión mínima soportada

## 📂 Estructura del Proyecto

```
PiumsArtist/
├── App/
│   ├── PiumsArtistApp.swift
│   └── ContentView.swift
├── Views/
│   ├── MainTabView.swift
│   ├── DashboardView.swift
│   ├── BookingsView.swift
│   ├── CalendarView.swift
│   ├── MessagesView.swift
│   └── ProfileView.swift
├── ViewModels/
│   └── ViewModels.swift
├── Models/
│   └── Models.swift
├── Components/
│   └── PiumsComponents.swift
└── Assets.xcassets/
```

## 🎨 Sistema de Design

### Componentes Reutilizables
- `PiumsButton`: Botones con múltiples estilos
- `PiumsCard`: Tarjetas con sombras consistentes
- `PiumsTextField`: Campos de entrada estilizados
- `PiumsStatusBadge`: Indicadores de estado coloridos
- `PiumsLoadingView`: Estados de carga
- `PiumsEmptyState`: Estados vacíos

### Paleta de Colores
- **Primario**: Azul (#007AFF)
- **Secundario**: Gris sistema
- **Éxito**: Verde
- **Advertencia**: Naranja
- **Error**: Rojo

## 💾 Modelos de Datos

### Artist
- Información personal y profesional
- Estadísticas y valoraciones
- Relaciones con servicios y reservas

### Service
- Servicios ofrecidos por el artista
- Precios, duración y categorías
- Estado activo/inactivo

### Booking
- Reservas de clientes
- Estados: Pendiente, Confirmada, En Progreso, Completada, Cancelada
- Información del cliente y servicio

### Message
- Sistema de mensajería integrado
- Conversaciones por reserva
- Mensajes de artista y cliente

## 🔄 Estados de Reserva

1. **Pendiente**: Nueva reserva esperando confirmación
2. **Confirmada**: Reserva aceptada por el artista
3. **En Progreso**: Servicio siendo realizado
4. **Completada**: Servicio finalizado exitosamente
5. **Cancelada**: Reserva cancelada por cualquier parte
6. **No Show**: Cliente no se presentó

## 🚧 Próximas Funcionalidades

### Fase 2
- [ ] Integración con APIs del backend
- [ ] Sistema de autenticación
- [ ] Notificaciones push
- [ ] Carga de imágenes (portfolio)
- [ ] Geolocalización para servicios a domicilio

### Fase 3
- [ ] Integración de pagos
- [ ] Sistema de reseñas
- [ ] Analytics avanzados
- [ ] Promociones y descuentos
- [ ] Modo offline

## 📋 Requisitos

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**

## 🛠️ Instalación y Desarrollo

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/app-piums/piums-ios-artist.git
   ```

2. **Abrir en Xcode**
   ```bash
   open PiumsArtist.xcodeproj
   ```

3. **Compilar y ejecutar**
   - Seleccionar un simulador o dispositivo iOS
   - Presionar ⌘+R para compilar y ejecutar

## 🤝 Contribución

1. Fork el repositorio
2. Crear una rama para tu feature (`git checkout -b feature/nueva-funcionalidad`)
3. Commit tus cambios (`git commit -am 'Añadir nueva funcionalidad'`)
4. Push a la rama (`git push origin feature/nueva-funcionalidad`)
5. Crear un Pull Request

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 📞 Contacto

Para preguntas o soporte, contacta al equipo de desarrollo de Piums.

---

**Piums Artista v1.0.0** - Versión Base MVP  
Desarrollado con ❤️ por el equipo de Piums