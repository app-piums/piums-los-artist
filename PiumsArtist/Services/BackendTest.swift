//
//  BackendTest.swift
//  PiumsArtist
//
//  Test de conectividad con el backend
//

import Foundation
import Combine

class BackendTest: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .unknown
    @Published var responseMessage: String = ""
    @Published var responseTime: TimeInterval = 0
    @Published var lastTestedAt: Date?
    
    enum ConnectionStatus {
        case unknown
        case connecting
        case connected
        case failed
        
        var emoji: String {
            switch self {
            case .unknown: return "⚪"
            case .connecting: return "🟡"  
            case .connected: return "🟢"
            case .failed: return "🔴"
            }
        }
        
        var description: String {
            switch self {
            case .unknown: return "No probado"
            case .connecting: return "Conectando..."
            case .connected: return "Conectado"
            case .failed: return "Error de conexión"
            }
        }
    }
    
    private let apiService = APIService.shared
    
    // Test básico de conectividad
    @MainActor
    func testConnection() async {
        connectionStatus = .connecting
        responseMessage = ""
        let startTime = Date()
        
        do {
            // Intentar hacer un ping básico al servidor
            let url = URL(string: APIConfig.currentURL + "/health")!
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            responseTime = Date().timeIntervalSince(startTime)
            lastTestedAt = Date()
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    connectionStatus = .connected
                    responseMessage = "Backend disponible en \(APIConfig.currentURL)"
                    
                    // Si hay datos, intentar parsearlos
                    if let responseText = String(data: data, encoding: .utf8) {
                        responseMessage += "\nRespuesta: \(responseText)"
                    }
                } else {
                    connectionStatus = .failed
                    responseMessage = "HTTP \(httpResponse.statusCode): Servidor respondió pero con error"
                }
            }
            
        } catch {
            connectionStatus = .failed  
            responseMessage = "Error: \(error.localizedDescription)"
            responseTime = Date().timeIntervalSince(startTime)
            lastTestedAt = Date()
        }
    }
    
    // Test de endpoints específicos de artista
    @MainActor 
    func testArtistEndpoints() async {
        connectionStatus = .connecting
        responseMessage = "Probando endpoints de artista...\n"
        
        // Test 1: Verificar endpoint de health/status
        await testEndpoint("/health", name: "Health Check")
        
        // Test 2: Verificar endpoint de auth
        await testEndpoint("/auth/status", name: "Auth Status")
        
        // Test 3: Verificar endpoint de artistas (sin auth)
        await testEndpoint("/artists", name: "Artists Endpoint")
        
        // Test 4: Verificar estructura de respuesta
        await testEndpoint("/catalog/services", name: "Catalog Services")
        
        lastTestedAt = Date()
    }
    
    private func testEndpoint(_ path: String, name: String) async {
        let startTime = Date()
        
        do {
            let url = URL(string: APIConfig.currentURL + path)!
            let (data, response) = try await URLSession.shared.data(from: url)
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                let status = httpResponse.statusCode
                var message = "\n✓ \(name): HTTP \(status) (\(Int(responseTime * 1000))ms)"
                
                // Intentar parsear JSON para ver estructura
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if !json.keys.isEmpty {
                        message += " - Keys: \(Array(json.keys).prefix(3).joined(separator: ", "))"
                    }
                }
                
                responseMessage += message
                
                if status == 200 || status == 401 { // 401 es esperado sin auth
                    connectionStatus = .connected
                } else if status >= 500 {
                    connectionStatus = .failed
                }
            }
            
        } catch {
            responseMessage += "\n✗ \(name): \(error.localizedDescription)"
            connectionStatus = .failed
        }
    }
    
    // Test de autenticación completa
    @MainActor
    func testFullAuth() async {
        connectionStatus = .connecting
        responseMessage = "Iniciando test de autenticación completa...\n"
        
        // Nota: Para este test necesitaríamos credenciales válidas
        // Por ahora solo probamos el endpoint de login
        do {
            let loginData: [String: Any] = [
                "email": "test@piums.com",
                "password": "test123"
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: loginData)
            
            var request = URLRequest(url: URL(string: APIConfig.currentURL + "/auth/login")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                responseMessage += "\nLogin endpoint response: HTTP \(httpResponse.statusCode)"
                
                if let responseText = String(data: data, encoding: .utf8) {
                    responseMessage += "\nResponse body: \(responseText.prefix(200))..."
                }
                
                connectionStatus = (httpResponse.statusCode == 200 || httpResponse.statusCode == 401) ? .connected : .failed
            }
            
        } catch {
            responseMessage += "\nError en test de auth: \(error.localizedDescription)"
            connectionStatus = .failed
        }
        
        lastTestedAt = Date()
    }
    
    // Test específico para login de artistas
    @MainActor
    func testArtistLogin(email: String, password: String) async {
        connectionStatus = .connecting
        responseMessage = "🎨 Probando login de artista...\n"
        responseMessage += "📧 Email: \(email)\n"
        responseMessage += "🔑 Password: [HIDDEN]\n\n"
        
        let startTime = Date()
        
        do {
            let loginData: [String: Any] = [
                "email": email,
                "password": password
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: loginData)
            
            var request = URLRequest(url: URL(string: APIConfig.currentURL + "/auth/login")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("PiumsArtist/1.0", forHTTPHeaderField: "User-Agent")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                responseMessage += "⏱️ Tiempo de respuesta: \(Int(responseTime * 1000))ms\n"
                responseMessage += "🌐 Status HTTP: \(httpResponse.statusCode)\n"
                
                // Headers importantes
                if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") {
                    responseMessage += "📄 Content-Type: \(contentType)\n"
                }
                
                if let authHeader = httpResponse.value(forHTTPHeaderField: "Authorization") {
                    responseMessage += "🔐 Auth Header presente: Sí\n"
                } else {
                    responseMessage += "🔐 Auth Header presente: No\n"
                }
                
                // Parsear respuesta
                if let responseText = String(data: data, encoding: .utf8) {
                    responseMessage += "\n📝 Response body:\n"
                    responseMessage += "Raw data size: \(data.count) bytes\n"
                    responseMessage += "Encoding: UTF-8\n\n"
                    
                    // Verificar si hay contenido
                    if responseText.isEmpty {
                        responseMessage += "⚠️ RESPUESTA VACÍA\n"
                        responseMessage += "El servidor no devolvió contenido\n"
                    } else {
                        responseMessage += "Raw response:\n\(responseText)\n\n"
                        
                        // Intentar parsear como JSON para mejor formato
                        do {
                            if let jsonData = responseText.data(using: .utf8) {
                                let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: [])
                                let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
                                if let prettyJSON = String(data: prettyData, encoding: .utf8) {
                                    responseMessage += "📋 JSON Formateado:\n\(prettyJSON)\n"
                                } else {
                                    responseMessage += "⚠️ Error al formatear JSON\n"
                                }
                            }
                        } catch {
                            responseMessage += "❌ JSON INVÁLIDO\n"
                            responseMessage += "Error de parsing: \(error.localizedDescription)\n"
                            responseMessage += "Posible causa: Respuesta no es JSON válido\n"
                            
                            // Verificar si es HTML o texto plano
                            if responseText.contains("<html") || responseText.contains("<!DOCTYPE") {
                                responseMessage += "💡 Parece ser una respuesta HTML (posible error 500)\n"
                            } else if responseText.contains("text/plain") {
                                responseMessage += "💡 Parece ser texto plano\n"
                            }
                        }
                    }
                } else {
                    responseMessage += "\n❌ NO SE PUDO LEER LA RESPUESTA\n"
                    responseMessage += "Error de codificación o datos corruptos\n"
                    responseMessage += "Data size: \(data.count) bytes\n"
                    
                    // Intentar otros encodings
                    if let latin1Text = String(data: data, encoding: .isoLatin1) {
                        responseMessage += "Contenido (ISO-Latin1): \(latin1Text.prefix(200))\n"
                    } else if let asciiText = String(data: data, encoding: .ascii) {
                        responseMessage += "Contenido (ASCII): \(asciiText.prefix(200))\n"
                    } else {
                        responseMessage += "Datos binarios no legibles\n"
                    }
                }
                
                // Determinar estado según respuesta
                switch httpResponse.statusCode {
                case 200:
                    connectionStatus = .connected
                    responseMessage += "\n\n✅ LOGIN EXITOSO"
                    responseMessage += "\n🎉 Usuario autenticado correctamente"
                case 401:
                    connectionStatus = .failed
                    responseMessage += "\n\n❌ CREDENCIALES INVÁLIDAS"
                    responseMessage += "\n💡 Verifica que el email y password sean correctos"
                    responseMessage += "\n💡 Asegúrate de que el usuario esté registrado en el sistema"
                case 403:
                    connectionStatus = .failed
                    responseMessage += "\n\n🔒 ACCESO PROHIBIDO"
                    responseMessage += "\n⚠️ La cuenta está bloqueada temporalmente por seguridad"
                    
                    // Intentar extraer el tiempo de espera del mensaje
                    if let responseText = String(data: data, encoding: .utf8),
                       let jsonData = responseText.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let message = jsonObject["message"] as? String {
                        
                        if message.contains("minutos") {
                            responseMessage += "\n⏱️ Esto sucede después de múltiples intentos fallidos"
                            responseMessage += "\n💡 SOLUCIONES:"
                            responseMessage += "\n   • Esperar el tiempo indicado en el mensaje"
                            responseMessage += "\n   • Verificar que las credenciales sean correctas"
                            responseMessage += "\n   • Contactar administrador si persiste"
                        } else if message.contains("bloqueada") || message.contains("suspended") {
                            responseMessage += "\n⚠️ La cuenta puede estar suspendida permanentemente"
                            responseMessage += "\n💡 Contacta al administrador del sistema"
                        }
                    }
                case 422:
                    connectionStatus = .failed
                    responseMessage += "\n\n❌ ERROR DE VALIDACIÓN"
                    responseMessage += "\n📋 Revisa el formato del email o los datos enviados"
                    responseMessage += "\n💡 Asegúrate de que el email tenga formato válido"
                case 429:
                    connectionStatus = .failed
                    responseMessage += "\n\n⏱️ DEMASIADOS INTENTOS"
                    responseMessage += "\n🚫 Rate limiting activado - el servidor está limitando las peticiones"
                    responseMessage += "\n⚠️ Esto es diferente al bloqueo de cuenta individual"
                    
                    // Intentar extraer el tiempo de espera del mensaje
                    if let responseText = String(data: data, encoding: .utf8),
                       let jsonData = responseText.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let message = jsonObject["message"] as? String {
                        
                        responseMessage += "\n📝 Mensaje del servidor: \"\(message)\"\n"
                        
                        if message.contains("minutos") {
                            // Extraer tiempo si es posible
                            let numbers = message.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
                            if let waitTime = numbers.first {
                                responseMessage += "⏰ Tiempo de espera: \(waitTime) minutos\n"
                                responseMessage += "🕐 Hora estimada de liberación: \(Date().addingTimeInterval(TimeInterval(waitTime * 60)).formatted(date: .omitted, time: .shortened))\n"
                            }
                        }
                        
                        responseMessage += "\n💡 DIFERENCIA CON BLOQUEO DE CUENTA:\n"
                        responseMessage += "• HTTP 429: Rate limiting del servidor (afecta a todas las IPs)\n"
                        responseMessage += "• HTTP 403: Bloqueo de cuenta específica\n"
                        responseMessage += "• Espera el tiempo indicado antes de cualquier intento\n"
                        responseMessage += "• Evita usar múltiples herramientas de test seguidas\n"
                    }
                case 500...599:
                    connectionStatus = .failed
                    responseMessage += "\n\n💥 ERROR DEL SERVIDOR"
                    responseMessage += "\n🔧 El backend tiene problemas internos"
                    responseMessage += "\n💡 Verifica los logs del servidor"
                default:
                    connectionStatus = .failed
                    responseMessage += "\n\n❓ ESTADO DESCONOCIDO: \(httpResponse.statusCode)"
                    responseMessage += "\n📖 Consulta la documentación de la API"
                }
            }
            
        } catch {
            connectionStatus = .failed
            responseMessage += "\n❌ Error de conexión: \(error.localizedDescription)"
            
            if error.localizedDescription.contains("refused") {
                responseMessage += "\n💡 El servidor no está disponible en localhost:3000"
            } else if error.localizedDescription.contains("timeout") {
                responseMessage += "\n💡 El servidor tardó demasiado en responder"
            }
        }
        
        lastTestedAt = Date()
        self.responseTime = Date().timeIntervalSince(startTime)
    }
    
    // Test para verificar estado de cuenta (bloqueos, etc.)
    @MainActor
    func checkAccountStatus(email: String) async {
        connectionStatus = .connecting
        responseMessage = "🔍 Verificando estado de cuenta...\n"
        responseMessage += "📧 Email: \(email)\n\n"
        
        let startTime = Date()
        
        do {
            // Intentamos un endpoint que nos dé información sobre el estado de la cuenta
            // Como no tenemos un endpoint específico, usamos el login con un password obviamente incorrecto
            // para obtener información del estado de la cuenta
            let testData: [String: Any] = [
                "email": email,
                "password": "invalid_password_for_status_check_only"
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: testData)
            
            var request = URLRequest(url: URL(string: APIConfig.currentURL + "/auth/login")!)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("PiumsArtist/1.0 StatusCheck", forHTTPHeaderField: "User-Agent")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            let responseTime = Date().timeIntervalSince(startTime)
            
            if let httpResponse = response as? HTTPURLResponse {
                responseMessage += "⏱️ Tiempo de respuesta: \(Int(responseTime * 1000))ms\n"
                responseMessage += "🌐 Status HTTP: \(httpResponse.statusCode)\n\n"
                
                if let responseText = String(data: data, encoding: .utf8) {
                    // Intentar parsear respuesta JSON
                    if let jsonData = responseText.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let message = jsonObject["message"] as? String {
                        
                        responseMessage += "📝 Mensaje del servidor:\n"
                        responseMessage += "\"\(message)\"\n\n"
                        
                        // Analizar el mensaje para detectar diferentes estados
                        switch httpResponse.statusCode {
                        case 401:
                            if message.contains("Credenciales inválidas") {
                                connectionStatus = .connected
                                responseMessage += "✅ CUENTA ACTIVA\n"
                                responseMessage += "👤 El usuario existe en el sistema\n"
                                responseMessage += "🔑 No hay bloqueos temporales\n"
                                responseMessage += "💡 El problema probablemente sea la contraseña incorrecta"
                            } else {
                                responseMessage += "❓ Mensaje inesperado de credenciales inválidas"
                            }
                            
                        case 403:
                            connectionStatus = .failed
                            responseMessage += "🔒 CUENTA BLOQUEADA\n"
                            
                            if message.contains("minutos") {
                                responseMessage += "⏰ Bloqueo temporal por múltiples intentos fallidos\n"
                                
                                // Extraer tiempo si es posible
                                let numbers = message.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
                                if let waitTime = numbers.first {
                                    responseMessage += "⌛ Tiempo de espera: \(waitTime) minutos\n"
                                    responseMessage += "🕐 Hora estimada de desbloqueo: \(Date().addingTimeInterval(TimeInterval(waitTime * 60)).formatted(date: .omitted, time: .shortened))\n"
                                }
                                
                                responseMessage += "\n💡 RECOMENDACIONES:\n"
                                responseMessage += "• Esperar el tiempo indicado\n"
                                responseMessage += "• Verificar la contraseña antes del próximo intento\n"
                                responseMessage += "• Evitar múltiples intentos seguidos\n"
                            } else {
                                responseMessage += "⚠️ Bloqueo permanente o suspensión\n"
                                responseMessage += "💡 Contactar al administrador del sistema\n"
                            }
                            
                        case 404:
                            connectionStatus = .failed
                            responseMessage += "❌ USUARIO NO ENCONTRADO\n"
                            responseMessage += "📧 El email no está registrado en el sistema\n"
                            responseMessage += "💡 Verificar que el email sea correcto o registrarse\n"
                            
                        default:
                            responseMessage += "❓ Estado desconocido: HTTP \(httpResponse.statusCode)\n"
                        }
                    } else {
                        responseMessage += "📄 Respuesta sin formato JSON:\n\(responseText)"
                    }
                }
            }
            
        } catch {
            connectionStatus = .failed
            responseMessage += "\n❌ Error al verificar estado: \(error.localizedDescription)"
        }
        
        lastTestedAt = Date()
        self.responseTime = Date().timeIntervalSince(startTime)
    }
}
