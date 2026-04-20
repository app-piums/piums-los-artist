# Plan de QA — PiumsArtist iOS
**Versión:** 1.0  
**Fecha:** 2026-04-20  
**App:** PiumsArtist (panel de artistas)  
**Plataforma:** iOS 17+ (iPhone físico requerido)  
**Entorno objetivo:** Producción real (`https://piums.com/api`)

---

## Objetivo

Encontrar fallos reales antes de que los encuentren los usuarios. Cada caso está diseñado para **romperse intencionalmente**. El resultado de cada prueba es PASS, FAIL o BLOCK (no se pudo ejecutar).

---

## Configuración previa

### Dispositivos requeridos
- [ ] iPhone físico con iOS 17+ (no solo simulador)
- [ ] Conexión WiFi estable para pruebas base
- [ ] Plan de datos 4G/5G para pruebas de red

### Cuentas de prueba
| Cuenta | Uso |
|--------|-----|
| `qa_artista_1@piums.io` | Cuenta principal con datos reales |
| `qa_artista_nuevo@piums.io` | Cuenta vacía (sin servicios, sin reservas) |
| Cuenta con token expirado | Pruebas de refresh |

### Herramientas
| Herramienta | Para qué | Instalación |
|---|---|---|
| **Proxyman** (Mac) | Interceptar y modificar respuestas HTTP | proxyman.io |
| **Xcode Instruments** | Memory leaks, CPU | Incluido en Xcode |
| **TestFlight** | Distribución interna | App Store Connect |

---

## Fase 1 — Autenticación

### 1.1 Login

| ID | Caso | Pasos | Resultado esperado |
|----|------|-------|--------------------|
| AUTH-01 | Login válido | Email y password correctos → "Iniciar sesión" | Entra al dashboard |
| AUTH-02 | Password incorrecto | Email válido + password wrong → login | Error visible "credenciales inválidas", no crash |
| AUTH-03 | Email no registrado | Email inventado → login | Error visible, no spinner infinito |
| AUTH-04 | Login sin internet | Modo avión → login | Banner "sin conexión", no queda cargando |
| AUTH-05 | Campos vacíos | Toca "Iniciar sesión" con campos vacíos | Botón deshabilitado o error de validación |
| AUTH-06 | Auto-login al reabrir | Login → cerrar app → reabrir | Entra directo sin re-login |
| AUTH-07 | Auto-login token expirado | Token expirado en UserDefaults → abrir app | Refresh automático o login limpio, no crash |

### 1.2 Registro

| ID | Caso | Pasos | Resultado esperado |
|----|------|-------|--------------------|
| AUTH-08 | Registro completo válido | Nombre + email + password → registrar | Entra al dashboard, inicia verificación |
| AUTH-09 | Email ya registrado | Registrar con email existente | Error "email ya en uso" visible |
| AUTH-10 | Password corta (`12345`) | Password de 5 chars → registrar | Error "mínimo 6 caracteres" |
| AUTH-11 | Passwords no coinciden | Nueva password ≠ confirmación | Error visible antes de enviar |
| AUTH-12 | Nombre vacío | Dejar nombre en blanco | Botón deshabilitado o error |

### 1.3 Recuperar contraseña *(nuevo)*

| ID | Caso | Pasos | Resultado esperado |
|----|------|-------|--------------------|
| AUTH-13 | Botón "¿Olvidaste tu contraseña?" | Toca el botón en login | Abre ForgotPasswordView |
| AUTH-14 | Enviar código — email válido | Email registrado → "Enviar código" | Mensaje "código enviado", avanza al paso 2 |
| AUTH-15 | Enviar código — email inválido | Email sin @ → botón | Botón deshabilitado |
| AUTH-16 | Enviar código — email no registrado | Email inventado → enviar | Error del backend visible |
| AUTH-17 | Reset con código correcto | Código válido + nueva password | "Contraseña cambiada", cierra la vista |
| AUTH-18 | Reset con código incorrecto | Código equivocado → cambiar | Error "código inválido" del backend |
| AUTH-19 | Passwords no coinciden en reset | Passwords distintas → cambiar | Botón deshabilitado + mensaje |
| AUTH-20 | Reset sin internet | Modo avión → enviar código | Error visible, no crash |

### 1.4 Sesión y tokens

| ID | Caso | Pasos | Resultado esperado |
|----|------|-------|--------------------|
| AUTH-21 | App en background 20 min | Login → minimizar 20 min → abrir | Sigue autenticado (refresh automático) |
| AUTH-22 | Logout limpio | Perfil → "Cerrar sesión" | Vuelve a login, datos locales borrados |
| AUTH-23 | Re-login cuenta diferente | Logout → login con otra cuenta | Dashboard de la nueva cuenta, sin residuos de la anterior |

---

## Fase 2 — Dashboard

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| DASH-01 | Carga inicial con datos | Stats reales del backend visibles |
| DASH-02 | Pull-to-refresh | Spinner aparece, datos se actualizan |
| DASH-03 | Sin reservas hoy | Empty state con botón "Promocionar Perfil" |
| DASH-04 | Stats en Q0 y 0 reservas | Muestra "Q0" y "0", no null ni crash |
| DASH-05 | Fortaleza del perfil 0% | Muestra checklist con todos en rojo |
| DASH-06 | Fecha en español | Muestra "lunes, 20 de abril" (no "Monday, April") |
| DASH-07 | Abrir notificaciones vacías | Empty state "Sin notificaciones" |
| DASH-08 | Notificaciones con datos | Lista carga, badge desaparece al marcar leído |
| DASH-09 | "Leer todo" en notificaciones | Todas marcadas leídas, badges desaparecen |
| DASH-10 | Sin internet al cargar | Mensaje de error visible, no datos falsos |

---

## Fase 3 — Reservas *(flujo más crítico)*

| ID | Caso | Pasos | Resultado esperado |
|----|------|-------|--------------------|
| RES-01 | Carga lista de reservas | Abrir tab Reservas | Lista real del backend |
| RES-02 | Filtro "Pendientes" | Seleccionar filtro | Solo muestra pendientes |
| RES-03 | Filtro con 0 resultados | Filtrar por estado sin resultados | Empty state, no crash |
| RES-04 | Aceptar reserva | Reserva pendiente → "Aceptar" | Estado cambia a Confirmada, persiste al refrescar |
| RES-05 | Rechazar reserva | Reserva pendiente → "Rechazar" | Estado cambia a Cancelada |
| RES-06 | Rechazar sin razón | Dejar campo razón vacío → rechazar | Envía vacío o pide razón (definir comportamiento) |
| RES-07 | Completar reserva | Reserva confirmada → "Completar" | Estado cambia a Completada |
| RES-08 | Doble tap en "Aceptar" | Toca "Aceptar" dos veces rápido | Solo hace 1 PATCH, no duplicado |
| RES-09 | Acción sin internet | Modo avión → aceptar reserva | Error visible, estado NO cambia localmente |
| RES-10 | Pull-to-refresh | Tirar hacia abajo | Lista actualizada sin duplicados |
| RES-11 | Ver detalle de reserva | Tocar una reserva | Detalle completo: cliente, fecha, precio, servicio |

---

## Fase 4 — Agenda / Calendario

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| CAL-01 | Carga bloques reales | Puntos rojos en días bloqueados desde backend |
| CAL-02 | Bloquear un día libre | Toca día → "Bloquear" | Punto rojo aparece, persiste al reabrir app |
| CAL-03 | Desbloquear día bloqueado | Toca día bloqueado → "Desbloquear" | Punto desaparece, disponible en backend |
| CAL-04 | Bloquear día ya bloqueado | Intentar bloquear de nuevo | Muestra opción "Desbloquear", no crea duplicado |
| CAL-05 | Cambiar de mes | Navegar mes siguiente/anterior | Carga disponibilidad del nuevo mes |
| CAL-06 | Sin artistBackendId | Primera vez sin cargar perfil | Error visible o flujo gracioso, no crash |
| CAL-07 | Bloquear sin internet | Modo avión → bloquear día | Error visible, día no queda marcado como bloqueado |
| CAL-08 | Slots limpios | Verificar que no hay reservas falsas | Todos los slots en "disponible", sin patrones mock |

---

## Fase 5 — Mensajes / Chat

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| MSG-01 | Lista de conversaciones | Carga conversaciones reales del backend |
| MSG-02 | Sin conversaciones | Empty state visible |
| MSG-03 | Abrir conversación | Mensajes cargan, badge de no leído desaparece |
| MSG-04 | Enviar mensaje | Mensaje aparece en burbuja naranja inmediatamente |
| MSG-05 | Enviar mensaje sin internet | Error visible, burbuja NO aparece como enviada |
| MSG-06 | Mensaje largo (500+ chars) | Se envía o muestra error de límite |
| MSG-07 | Enviar 5 mensajes rápido | Orden correcto, sin duplicados |
| MSG-08 | Buscar cliente existente | Resultados filtrados en tiempo real |
| MSG-09 | Buscar cliente inexistente | "Sin resultados", no crash |
| MSG-10 | Sin internet al abrir | Error visible, no datos falsos de mock |

---

## Fase 6 — Servicios

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| SVC-01 | Lista de servicios | Servicios reales del backend cargados |
| SVC-02 | Crear servicio completo | Todos los campos → guardar | Aparece en lista, persiste |
| SVC-03 | Crear sin categoría | Dejar categoría vacía → guardar | Error visible, no crash |
| SVC-04 | Crear con precio 0 | Precio = 0 → guardar | Error de validación o el backend lo rechaza |
| SVC-05 | Crear nombre duplicado | Mismo nombre → guardar | Error del backend visible |
| SVC-06 | Desactivar servicio | Toggle → desactivar | Cambia a inactivo, persiste |
| SVC-07 | Activar servicio inactivo | Toggle → activar | Cambia a activo, persiste |
| SVC-08 | Editar precio | Editar precio existente → guardar | Nuevo precio en lista |
| SVC-09 | Eliminar servicio | Servicio sin reservas → eliminar | Desaparece de lista |
| SVC-10 | Eliminar con confirmación | Toca eliminar | Pide confirmación antes |

---

## Fase 7 — Perfil

### 7.1 Foto de perfil *(nueva)*

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| PROF-01 | Seleccionar foto de galería | Icono cámara → galería → foto | Spinner durante upload, foto actualizada |
| PROF-02 | Foto de 10MB+ | Foto muy pesada | Comprime o rechaza con mensaje claro |
| PROF-03 | Upload sin internet | Modo avión → seleccionar foto | Error visible, no queda en estado cargando |
| PROF-04 | Cancela selección | Abre galería → cancela | Sin cambios, sin crash |

### 7.2 Editar perfil

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| PROF-05 | Editar nombre | Nombre nuevo → guardar | Nombre actualizado en header |
| PROF-06 | Editar bio | Bio nueva → guardar | Refleja en "Fortaleza del Perfil" |
| PROF-07 | Guardar sin internet | Modo avión → guardar | Error visible, cambios no guardados |

### 7.3 Botones de configuración *(nuevos)*

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| PROF-08 | Notificaciones | Toca "Notificaciones" | Abre configuración de notificaciones de iOS |
| PROF-09 | Privacidad | Toca "Privacidad" | Abre sheet con política y link a piums.com |
| PROF-10 | Ayuda y Soporte | Toca "Ayuda y Soporte" | Abre sheet con email y centro de ayuda |

---

## Fase 8 — Verificación de Identidad

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| VER-01 | Flujo completo | DPI + datos + 3 fotos → enviar | "En revisión", no vuelve a pedir verificación |
| VER-02 | Sin foto selfie | Intentar enviar sin selfie | Botón "Enviar" deshabilitado |
| VER-03 | Foto muy grande (10MB+) | Seleccionar foto pesada | Timeout visible o compresión automática |
| VER-04 | Perder internet durante upload | Modo avión en mitad del upload | Error visible, puede reintentar |
| VER-05 | Menor de edad | DatePicker — fecha < 18 años | No permite continuar |

---

## Fase 9 — Disputas

### 9.1 Ver disputas

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| DIS-01 | Sin disputas | Empty state "Sin quejas registradas" |
| DIS-02 | Con disputas | Lista con tipo, estado y último mensaje |
| DIS-03 | Disputa cerrada | Abre detalle | Input de mensaje deshabilitado, "Esta queja está cerrada" |
| DIS-04 | Enviar mensaje en disputa activa | Escribe mensaje → enviar | Aparece como burbuja naranja |

### 9.2 Crear disputa *(nueva)*

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| DIS-05 | Botón "+" en Mis Quejas | Toca el + | Abre NewDisputaSheet |
| DIS-06 | Crear con todos los campos | Tipo + asunto + descripción → enviar | Nueva disputa aparece en lista |
| DIS-07 | Asunto muy corto (< 5 chars) | Texto corto → botón Enviar | Botón deshabilitado |
| DIS-08 | Descripción muy corta (< 10 chars) | Texto corto | Botón deshabilitado |
| DIS-09 | Crear sin internet | Modo avión → enviar | Error visible, disputa no creada |

---

## Fase 10 — Ausencias

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| AUS-01 | Crear ausencia vacaciones | Tipo vacaciones + fechas → guardar | Aparece en timeline |
| AUS-02 | Crear ausencia extranjero | Tipo extranjero + país destino + fechas | Aparece con badge de país |
| AUS-03 | Fechas solapadas | Crear ausencia con fechas que se cruzan | Error del backend visible |
| AUS-04 | Eliminar ausencia | Ausencia existente → eliminar | Desaparece de timeline |
| AUS-05 | Sin internet al crear | Modo avión → guardar ausencia | Error visible |

---

## Fase 11 — Reseñas

| ID | Caso | Resultado esperado |
|----|------|--------------------|
| REV-01 | Lista de reseñas | Reseñas reales del backend |
| REV-02 | Sin reseñas | Empty state visible |
| REV-03 | Responder reseña | Escribe respuesta → enviar | Respuesta guardada |
| REV-04 | Responder con texto vacío | Botón enviar vacío | Botón deshabilitado |
| REV-05 | Paginación | Más de 10 reseñas → botón "Siguiente" | Carga la página 2 |

---

## Fase 12 — Red y conectividad *(crítica)*

> Usar Proxyman para simular respuestas del servidor o activar/desactivar WiFi manualmente.

| ID | Escenario | Cómo provocarlo | Resultado esperado |
|----|-----------|-----------------|-------------------|
| NET-01 | Sin internet al abrir app | Modo avión → abrir app | Mensaje de error, no datos falsos |
| NET-02 | Internet se corta durante acción | Aceptar reserva → modo avión a mitad | Error visible, estado NO cambia |
| NET-03 | Red lenta (3G simulado) | Throttle en router o Proxyman | Spinners visibles, sin timeouts invisibles |
| NET-04 | Servidor 500 | Proxyman intercepta y devuelve 500 | Error visible "error del servidor" |
| NET-05 | Respuesta 401 | Proxyman devuelve 401 | Logout automático o refresh de token |
| NET-06 | Rate limiting 429 | 20 requests en 5 segundos | Error "demasiadas solicitudes" visible |
| NET-07 | JSON malformado | Proxyman devuelve JSON roto | Error de decodificación visible, no crash |
| NET-08 | Timeout | Request que tarda > 30s | Mensaje de timeout, puede reintentar |

---

## Fase 13 — Rendimiento y memoria

| ID | Prueba | Herramienta | Umbral aceptable |
|----|--------|-------------|-----------------|
| PERF-01 | Memoria al navegar 10 min | Instruments → Leaks | Sin leaks, < 150MB |
| PERF-02 | CPU en scroll de 100 reservas | Instruments → Time Profiler | < 30% CPU sostenido |
| PERF-03 | Abrir/cerrar chat 20 veces | Instruments → Memory Graph | Sin retain cycles |
| PERF-04 | Background/foreground 10 veces | Crash Organizer | Sin crashes |
| PERF-05 | Tiempo de arranque en frío | Medir manualmente | < 3 segundos al splash |

---

## Fase 14 — Seguridad básica

| ID | Prueba | Resultado esperado |
|----|--------|--------------------|
| SEC-01 | Token en UserDefaults visible | Ver con Xcode Device → Files | Los tokens son legibles (riesgo conocido — migrar a Keychain) |
| SEC-02 | Tráfico HTTPS | Proxyman captura requests | Toda comunicación en HTTPS, sin HTTP en prod |
| SEC-03 | Logout borra todo | Logout → revisar UserDefaults | `auth_token`, `refresh_token`, `artist_backend_id`, `user_email` borrados |
| SEC-04 | Datos sensibles en logs | Xcode console tras login | No se imprime token ni password en consola |

---

## Hoja de registro de resultados

Copiar esta tabla por cada sesión de pruebas:

```
Sesión: _______________
Tester: _______________
Dispositivo: _______________
iOS: _______________
Build: _______________
Entorno: _______________

| ID       | Estado | Notas |
|----------|--------|-------|
| AUTH-01  |        |       |
| AUTH-02  |        |       |
| ...      |        |       |
```

**Estados:**
- ✅ PASS — funciona como se espera
- ❌ FAIL — no funciona, documentar comportamiento real
- ⚠️ PARTIAL — funciona parcialmente
- 🚫 BLOCK — no se pudo ejecutar (explicar por qué)

---

## Prioridad de corrección de fallos

```
P0 — CRÍTICO    Auth, pagos, pérdida de datos
P1 — ALTO       Reservas, mensajes, calendario
P2 — MEDIO      Perfil, servicios, disputas
P3 — BAJO       UI cosmética, rendimiento, seguridad
```

---

## Criterio de aprobación para producción

- [ ] 0 fallos P0
- [ ] 0 fallos P1
- [ ] Fallos P2 documentados y con fecha de fix
- [ ] Fases 1–9 con 90%+ casos en PASS
- [ ] Sin crashes en Fase 13
- [ ] Fase 12 NET-01 a NET-05 en PASS

---

*Documento generado el 2026-04-20 para el ciclo de QA previo al lanzamiento de PiumsArtist.*
