//
//  ErrorHandling.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI
import Combine
import Network

// MARK: - Global Error Handler
@MainActor
final class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var showingError = false
    
    private init() {}
    
    func handle(_ error: Error) {
        let appError = AppError(from: error)
        currentError = appError
        showingError = true
        
        // Log error for debugging
        print("🚨 Error handled: \(appError.localizedDescription)")
        print("   Details: \(appError.debugDescription)")
    }
    
    func clearError() {
        currentError = nil
        showingError = false
    }
}

// MARK: - App Error Types
struct AppError: LocalizedError, Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let debugDescription: String
    let actionButton: ErrorAction?
    
    init(
        title: String,
        message: String,
        debugDescription: String = "",
        actionButton: ErrorAction? = nil
    ) {
        self.title = title
        self.message = message
        self.debugDescription = debugDescription
        self.actionButton = actionButton
    }
    
    init(from error: Error) {
        if let apiError = error as? APIError {
            switch apiError {
            case .unauthorized:
                self.title = "Sesión Expirada"
                self.message = "Tu sesión ha expirado. Por favor, inicia sesión nuevamente."
                self.debugDescription = apiError.localizedDescription
                self.actionButton = ErrorAction(
                    title: "Iniciar Sesión",
                    action: {
                        Task {
                            await AuthService.shared.logout()
                        }
                    }
                )
                
            case .networkError(let underlyingError):
                self.title = "Sin Conexión"
                self.message = "Verifica tu conexión a internet e intenta nuevamente."
                self.debugDescription = underlyingError.localizedDescription
                self.actionButton = ErrorAction(
                    title: "Reintentar",
                    action: {
                        // This would trigger a retry mechanism
                        NotificationCenter.default.post(name: .retryLastAction, object: nil)
                    }
                )
                
            case .serverError:
                self.title = "Error del Servidor"
                self.message = "Estamos experimentando problemas técnicos. Intenta más tarde."
                self.debugDescription = apiError.localizedDescription
                self.actionButton = nil
                
            case .httpError(let code, let message):
                self.title = "Error HTTP \(code)"
                self.message = message.isEmpty ? "Ha ocurrido un error inesperado." : message
                self.debugDescription = apiError.localizedDescription
                self.actionButton = nil
                
            default:
                self.title = "Error de Red"
                self.message = apiError.localizedDescription
                self.debugDescription = apiError.localizedDescription
                self.actionButton = nil
            }
        } else {
            self.title = "Error"
            self.message = error.localizedDescription
            self.debugDescription = "\(error)"
            self.actionButton = nil
        }
    }
    
    var errorDescription: String? {
        return message
    }
}

struct ErrorAction {
    let title: String
    let action: () -> Void
}

// MARK: - Error Banner Component
struct ErrorBanner: View {
    let error: AppError
    let onDismiss: () -> Void
    
    @State private var offset: CGFloat = -100
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(error.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(error.message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            if let actionButton = error.actionButton {
                Button(action: {
                    actionButton.action()
                    onDismiss()
                }) {
                    Text(actionButton.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .roundedCorner(8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
        .offset(y: offset)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                offset = 0
            }
            
            // Auto dismiss after 5 seconds if no action button
            if error.actionButton == nil {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    onDismiss()
                }
            }
        }
    }
}

// MARK: - Error Alert Component
struct ErrorAlert: ViewModifier {
    @ObservedObject private var errorHandler = ErrorHandler.shared
    
    func body(content: Content) -> some View {
        content
            .alert(
                errorHandler.currentError?.title ?? "Error",
                isPresented: $errorHandler.showingError,
                presenting: errorHandler.currentError
            ) { error in
                if let actionButton = error.actionButton {
                    Button(actionButton.title) {
                        actionButton.action()
                        errorHandler.clearError()
                    }
                }
                
                Button("OK") {
                    errorHandler.clearError()
                }
            } message: { error in
                Text(error.message)
            }
    }
}

// MARK: - Loading State Component
struct LoadingOverlay: View {
    let isLoading: Bool
    let message: String
    
    init(isLoading: Bool, message: String = "Cargando...") {
        self.isLoading = isLoading
        self.message = message
    }
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 8)
                )
            }
            .animation(.easeInOut(duration: 0.2), value: isLoading)
        }
    }
}

// MARK: - Network Status Monitor

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi

    enum ConnectionType {
        case wifi, cellular, none
    }

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "io.piums.network", qos: .utility)

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else {
                    self?.connectionType = .none
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }
}

// MARK: - View Extensions
extension View {
    func errorHandling() -> some View {
        self.modifier(ErrorAlert())
    }
    
    func loadingOverlay(isLoading: Bool, message: String = "Cargando...") -> some View {
        self.overlay(LoadingOverlay(isLoading: isLoading, message: message))
    }
    
    func onError(perform action: @escaping (Error) -> Void) -> some View {
        self.onReceive(NotificationCenter.default.publisher(for: .appError)) { notification in
            if let error = notification.object as? Error {
                action(error)
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let appError = Notification.Name("AppError")
    static let retryLastAction = Notification.Name("RetryLastAction")
    static let networkStatusChanged = Notification.Name("NetworkStatusChanged")
}

// MARK: - Async Error Handling Helper
func handleAsyncError<T>(_ operation: @escaping () async throws -> T) {
    Task {
        do {
            _ = try await operation()
        } catch {
            await MainActor.run {
                ErrorHandler.shared.handle(error)
            }
        }
    }
}
