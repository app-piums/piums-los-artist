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
                    
                    // Intentar parsear como JSON para mejor formato
                    if let jsonData = responseText.data(using: .utf8),
                       let jsonObject = try? JSONSerialization.jsonObject(with: jsonData, options: []),
                       let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
                       let prettyJSON = String(data: prettyData, encoding: .utf8) {
                        responseMessage += prettyJSON
                    } else {
                        responseMessage += responseText
                    }
                }
                
                // Determinar estado según respuesta
                switch httpResponse.statusCode {
                case 200:
                    connectionStatus = .connected
                    responseMessage += "\n\n✅ LOGIN EXITOSO"
                case 401:
                    connectionStatus = .failed
                    responseMessage += "\n\n❌ CREDENCIALES INVÁLIDAS"
                    responseMessage += "\nVerifica que el email y password sean correctos"
                case 422:
                    connectionStatus = .failed
                    responseMessage += "\n\n❌ ERROR DE VALIDACIÓN"
                    responseMessage += "\nRevisa el formato del email o los datos enviados"
                case 429:
                    connectionStatus = .failed
                    responseMessage += "\n\n❌ DEMASIADOS INTENTOS"
                    responseMessage += "\nEspera un momento antes de intentar de nuevo"
                case 500...599:
                    connectionStatus = .failed
                    responseMessage += "\n\n❌ ERROR DEL SERVIDOR"
                    responseMessage += "\nEl backend tiene problemas internos"
                default:
                    connectionStatus = .failed
                    responseMessage += "\n\n❓ ESTADO DESCONOCIDO: \(httpResponse.statusCode)"
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
}
