//
//  PiumsComponents.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI

// MARK: - Colors Extension
extension Color {
    static let piumsPrimary = Color.blue
    static let piumsSecondary = Color(.systemBlue)
    static let piumsAccent = Color.orange
    static let piumsBackground = Color(.systemBackground)
    static let piumsCardBackground = Color(.systemBackground)
    static let piumsGrayLight = Color(.systemGray6)
    static let piumsGrayMedium = Color(.systemGray4)
    static let piumsSuccess = Color.green
    static let piumsWarning = Color.orange
    static let piumsError = Color.red
}

// MARK: - Piums Button
struct PiumsButton: View {
    let title: String
    let style: ButtonStyle
    let size: ButtonSize
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, outline, destructive
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .piumsPrimary
            case .secondary: return .piumsGrayLight
            case .outline: return .clear
            case .destructive: return .piumsError
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .white
            case .secondary: return .primary
            case .outline: return .piumsPrimary
            case .destructive: return .white
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline: return .piumsPrimary
            default: return .clear
            }
        }
    }
    
    enum ButtonSize {
        case small, medium, large
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            case .medium: return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            case .large: return EdgeInsets(top: 14, leading: 24, bottom: 14, trailing: 24)
            }
        }
        
        var font: Font {
            switch self {
            case .small: return .caption
            case .medium: return .subheadline
            case .large: return .body
            }
        }
    }
    
    init(
        _ title: String,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(size.font)
                .fontWeight(.medium)
                .foregroundColor(style.foregroundColor)
                .padding(size.padding)
                .frame(maxWidth: .infinity)
                .background(style.backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style.borderColor, lineWidth: 1)
                )
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Piums Card
struct PiumsCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 12,
        shadowRadius: CGFloat = 2,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Color.piumsCardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: shadowRadius, x: 0, y: 1)
    }
}

// MARK: - Piums Input Field
struct PiumsTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    
    init(
        _ title: String,
        placeholder: String = "",
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder.isEmpty ? title : placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .keyboardType(keyboardType)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.piumsGrayLight)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.piumsGrayMedium, lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Piums Status Badge
struct PiumsStatusBadge: View {
    let text: String
    let status: BadgeStatus
    
    enum BadgeStatus {
        case success, warning, error, info, neutral
        
        var backgroundColor: Color {
            switch self {
            case .success: return .piumsSuccess.opacity(0.1)
            case .warning: return .piumsWarning.opacity(0.1)
            case .error: return .piumsError.opacity(0.1)
            case .info: return .piumsPrimary.opacity(0.1)
            case .neutral: return .piumsGrayLight
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .success: return .piumsSuccess
            case .warning: return .piumsWarning
            case .error: return .piumsError
            case .info: return .piumsPrimary
            case .neutral: return .secondary
            }
        }
    }
    
    var body: some View {
        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.backgroundColor)
            .foregroundColor(status.foregroundColor)
            .cornerRadius(6)
    }
}

// MARK: - Piums Loading View
struct PiumsLoadingView: View {
    let message: String
    
    init(_ message: String = "Cargando...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .piumsPrimary))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.piumsBackground)
    }
}

// MARK: - Piums Empty State
struct PiumsEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.piumsGrayMedium)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if let buttonTitle = buttonTitle,
               let buttonAction = buttonAction {
                PiumsButton(buttonTitle, style: .primary, action: buttonAction)
                    .frame(maxWidth: 200)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Piums Navigation Bar
struct PiumsNavigationBar: View {
    let title: String
    let leftButton: BarButton?
    let rightButton: BarButton?
    
    struct BarButton {
        let icon: String?
        let text: String?
        let action: () -> Void
        
        init(icon: String, action: @escaping () -> Void) {
            self.icon = icon
            self.text = nil
            self.action = action
        }
        
        init(text: String, action: @escaping () -> Void) {
            self.icon = nil
            self.text = text
            self.action = action
        }
    }
    
    var body: some View {
        HStack {
            if let leftButton = leftButton {
                Button(action: leftButton.action) {
                    if let icon = leftButton.icon {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.piumsPrimary)
                    } else if let text = leftButton.text {
                        Text(text)
                            .foregroundColor(.piumsPrimary)
                    }
                }
            } else {
                Spacer()
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            if let rightButton = rightButton {
                Button(action: rightButton.action) {
                    if let icon = rightButton.icon {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(.piumsPrimary)
                    } else if let text = rightButton.text {
                        Text(text)
                            .foregroundColor(.piumsPrimary)
                    }
                }
            } else {
                Spacer()
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.piumsBackground)
    }
}

// MARK: - Preview
#Preview("Piums Components") {
    ScrollView {
        VStack(spacing: 20) {
            // Buttons
            VStack(spacing: 12) {
                PiumsButton("Botón Primario", style: .primary) { }
                PiumsButton("Botón Secundario", style: .secondary) { }
                PiumsButton("Botón Outline", style: .outline) { }
                PiumsButton("Botón Destructivo", style: .destructive) { }
            }
            
            // Card
            PiumsCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tarjeta de Ejemplo")
                        .font(.headline)
                    Text("Este es el contenido de una tarjeta de Piums con el estilo predefinido.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status Badges
            HStack(spacing: 8) {
                PiumsStatusBadge(text: "Confirmado", status: .success)
                PiumsStatusBadge(text: "Pendiente", status: .warning)
                PiumsStatusBadge(text: "Cancelado", status: .error)
                PiumsStatusBadge(text: "Info", status: .info)
            }
            
            // Text Fields
            VStack(spacing: 16) {
                PiumsTextField("Nombre", text: .constant(""))
                PiumsTextField("Email", placeholder: "tu@email.com", text: .constant(""), keyboardType: .emailAddress)
                PiumsTextField("Contraseña", text: .constant(""), isSecure: true)
            }
        }
        .padding()
    }
}