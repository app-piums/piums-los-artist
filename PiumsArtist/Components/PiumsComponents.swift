//
//  PiumsComponents.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI

// MARK: - Modern Color System
extension Color {
    // Primary Brand Colors — alineados con Piums naranja (igual que app cliente)
    static let piumsPrimary   = Color(hex: "#FF6B35") // Brand Orange  ← mismo que piumsOrange
    static let piumsSecondary = Color(hex: "#E85D2F") // Orange oscuro (hover/pressed)
    static let piumsAccent    = Color(hex: "#F59E0B") // Amber accent
    static let piumsOrange    = Color(hex: "#FF6B35") // Brand Orange (alias)

    // Colores del sistema Piums (light: blanco/gris · dark: #121212/#1C1C1E/#28282A)
    static let piumsBackground          = Color("PiumsBackground")
    static let piumsBackgroundSecondary = Color("PiumsBackgroundSecondary")
    static let piumsBackgroundElevated  = Color("PiumsBackgroundElevated")
    static let piumsLabel               = Color("PiumsLabel")
    static let piumsLabelSecondary      = Color("PiumsLabelSecondary")
    static let piumsSeparator           = Color("PiumsSeparator")

    // UI Colors
    static let piumsCardBackground = Color(.secondarySystemBackground)
    static let piumsSurface = Color(.tertiarySystemBackground)
    
    // Semantic Colors
    static let piumsSuccess = Color(hex: "#10B981") // Emerald
    static let piumsWarning = Color(hex: "#F59E0B") // Amber
    static let piumsError = Color(hex: "#EF4444") // Red
    static let piumsInfo = Color(hex: "#3B82F6") // Blue
    
    // Neutral Grays
    static let piumsGrayLight = Color(.systemGray6)
    static let piumsGrayMedium = Color(.systemGray4)
    static let piumsGrayDark = Color(.systemGray2)
    
    // Text Colors
    static let piumsTextPrimary = Color.primary
    static let piumsTextSecondary = Color.secondary
    static let piumsTextTertiary = Color(.tertiaryLabel)
    
    // Helper for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Enhanced Button Component
struct PiumsButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let size: ButtonSize
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    enum ButtonStyle {
        case primary, secondary, outline, ghost, destructive, success
        
        var colors: (background: Color, foreground: Color, border: Color) {
            switch self {
            case .primary:
                return (.piumsPrimary, .white, .clear)
            case .secondary:
                return (.piumsCardBackground, .piumsTextPrimary, .piumsGrayMedium)
            case .outline:
                return (.clear, .piumsPrimary, .piumsPrimary)
            case .ghost:
                return (.clear, .piumsPrimary, .clear)
            case .destructive:
                return (.piumsError, .white, .clear)
            case .success:
                return (.piumsSuccess, .white, .clear)
            }
        }
    }
    
    enum ButtonSize {
        case small, medium, large, extraLarge
        
        var metrics: (padding: EdgeInsets, font: Font, height: CGFloat) {
            switch self {
            case .small:
                return (EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16), .caption.weight(.medium), 32)
            case .medium:
                return (EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20), .subheadline.weight(.semibold), 44)
            case .large:
                return (EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24), .body.weight(.semibold), 52)
            case .extraLarge:
                return (EdgeInsets(top: 20, leading: 32, bottom: 20, trailing: 32), .title3.weight(.bold), 60)
            }
        }
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .primary,
        size: ButtonSize = .medium,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: isDisabled ? {} : action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: style.colors.foreground))
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(size.metrics.font)
                }
                
                Text(title)
                    .font(size.metrics.font)
            }
            .foregroundColor(isDisabled ? .piumsGrayMedium : style.colors.foreground)
            .padding(size.metrics.padding)
            .frame(minHeight: size.metrics.height)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isDisabled ? Color.piumsGrayLight : style.colors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style.colors.border, lineWidth: style.colors.border == .clear ? 0 : 1.5)
                    )
            )
            .scaleEffect(isDisabled ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isDisabled)
        }
        .buttonStyle(PiumsButtonStyle())
        .disabled(isDisabled || isLoading)
    }
}

struct PiumsButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Enhanced Card Component
struct PiumsCard<Content: View>: View {
    let content: Content
    let style: CardStyle
    let padding: CGFloat
    
    enum CardStyle {
        case `default`, elevated, bordered, highlighted
        
        var background: Color {
            switch self {
            case .default, .bordered: return .piumsCardBackground
            case .elevated: return .piumsBackground
            case .highlighted: return .piumsPrimary.opacity(0.05)
            }
        }
        
        var shadowConfig: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            switch self {
            case .default: return (.black.opacity(0.05), 2, 0, 1)
            case .elevated: return (.black.opacity(0.1), 8, 0, 4)
            case .bordered: return (.clear, 0, 0, 0)
            case .highlighted: return (.piumsPrimary.opacity(0.1), 4, 0, 2)
            }
        }
        
        var borderColor: Color {
            switch self {
            case .bordered: return .piumsGrayMedium
            case .highlighted: return .piumsPrimary.opacity(0.2)
            default: return .clear
            }
        }
    }
    
    init(
        style: CardStyle = .default,
        padding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.padding = padding
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(style.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style.borderColor, lineWidth: style.borderColor == .clear ? 0 : 1)
                    )
                    .shadow(
                        color: style.shadowConfig.color,
                        radius: style.shadowConfig.radius,
                        x: style.shadowConfig.x,
                        y: style.shadowConfig.y
                    )
            )
    }
}

// MARK: - Modern Text Field
struct PiumsTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool
    let icon: String?
    let errorMessage: String?
    @State private var isFieldFocused = false
    
    init(
        _ title: String,
        placeholder: String = "",
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false,
        icon: String? = nil,
        errorMessage: String? = nil
    ) {
        self.title = title
        self.placeholder = placeholder.isEmpty ? title : placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isSecure = isSecure
        self.icon = icon
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.piumsTextSecondary)
            
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.piumsGrayDark)
                        .frame(width: 20)
                }
                
                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text, onEditingChanged: { focused in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isFieldFocused = focused
                            }
                        })
                    }
                }
                .keyboardType(keyboardType)
                .font(.body)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.piumsSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                errorMessage != nil ? Color.piumsError :
                                isFieldFocused ? Color.piumsPrimary : Color.piumsGrayMedium,
                                lineWidth: isFieldFocused ? 2 : 1
                            )
                    )
            )
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.piumsError)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Enhanced Status Badge
struct PiumsStatusBadge: View {
    let text: String
    let status: BadgeStatus
    let size: BadgeSize
    
    enum BadgeStatus {
        case success, warning, error, info, neutral, premium
        
        var colors: (background: Color, foreground: Color, border: Color) {
            switch self {
            case .success:
                return (.piumsSuccess.opacity(0.1), .piumsSuccess, .piumsSuccess.opacity(0.3))
            case .warning:
                return (.piumsWarning.opacity(0.1), .piumsWarning, .piumsWarning.opacity(0.3))
            case .error:
                return (.piumsError.opacity(0.1), .piumsError, .piumsError.opacity(0.3))
            case .info:
                return (.piumsInfo.opacity(0.1), .piumsInfo, .piumsInfo.opacity(0.3))
            case .neutral:
                return (.piumsGrayLight, .piumsTextSecondary, .piumsGrayMedium)
            case .premium:
                return (.piumsSecondary.opacity(0.1), .piumsSecondary, .piumsSecondary.opacity(0.3))
            }
        }
    }
    
    enum BadgeSize {
        case small, medium, large
        
        var metrics: (padding: EdgeInsets, font: Font, cornerRadius: CGFloat) {
            switch self {
            case .small:
                return (EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8), .caption2.weight(.semibold), 6)
            case .medium:
                return (EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10), .caption.weight(.semibold), 8)
            case .large:
                return (EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12), .subheadline.weight(.semibold), 10)
            }
        }
    }
    
    init(_ text: String, status: BadgeStatus, size: BadgeSize = .medium) {
        self.text = text
        self.status = status
        self.size = size
    }
    
    var body: some View {
        Text(text)
            .font(size.metrics.font)
            .foregroundColor(status.colors.foreground)
            .padding(size.metrics.padding)
            .background(
                RoundedRectangle(cornerRadius: size.metrics.cornerRadius)
                    .fill(status.colors.background)
                    .overlay(
                        RoundedRectangle(cornerRadius: size.metrics.cornerRadius)
                            .stroke(status.colors.border, lineWidth: 0.5)
                    )
            )
    }
}

// MARK: - Modern Stats Card
struct PiumsStatsCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let trend: TrendDirection?
    let trendValue: String?
    let color: Color
    
    enum TrendDirection {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .piumsSuccess
            case .down: return .piumsError
            case .neutral: return .piumsGrayDark
            }
        }
    }
    
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        trend: TrendDirection? = nil,
        trendValue: String? = nil,
        color: Color = .piumsPrimary
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.trend = trend
        self.trendValue = trendValue
        self.color = color
    }
    
    var body: some View {
        PiumsCard(style: .elevated) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                        .frame(width: 40, height: 40)
                        .background(color.opacity(0.1))
                        .clipShape(Circle())
                    
                    Spacer()
                    
                    if let trend = trend, let trendValue = trendValue {
                        HStack(spacing: 4) {
                            Image(systemName: trend.icon)
                                .font(.caption.weight(.bold))
                            Text(trendValue)
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(trend.color)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.title2.weight(.bold))
                        .foregroundColor(.piumsTextPrimary)
                    
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.piumsTextSecondary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.piumsTextTertiary)
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Loading View
struct PiumsLoadingView: View {
    let message: String
    let style: LoadingStyle
    
    enum LoadingStyle {
        case fullScreen, card, inline
    }
    
    init(_ message: String = "Cargando...", style: LoadingStyle = .fullScreen) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .piumsPrimary))
            
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.piumsTextSecondary)
        }
        .padding(style == .inline ? 20 : 40)
        .frame(maxWidth: style == .fullScreen ? .infinity : nil)
        .frame(maxHeight: style == .fullScreen ? .infinity : nil)
        .background(style == .card ? Color.piumsCardBackground : Color.clear)
        .cornerRadius(style == .card ? 16 : 0)
    }
}

// MARK: - Enhanced Empty State
struct PiumsEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let primaryAction: ActionConfig?
    let secondaryAction: ActionConfig?
    
    struct ActionConfig {
        let title: String
        let icon: String?
        let action: () -> Void
        
        init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.action = action
        }
    }
    
    init(
        icon: String,
        title: String,
        message: String,
        primaryAction: ActionConfig? = nil,
        secondaryAction: ActionConfig? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 20) {
                Image(systemName: icon)
                    .font(.system(size: 64, weight: .light))
                    .foregroundColor(.piumsGrayDark)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(.piumsTextPrimary)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.piumsTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            
            if primaryAction != nil || secondaryAction != nil {
                VStack(spacing: 12) {
                    if let primaryAction = primaryAction {
                        PiumsButton(
                            primaryAction.title,
                            icon: primaryAction.icon,
                            style: .primary,
                            size: .large,
                            action: primaryAction.action
                        )
                        .frame(maxWidth: 280)
                    }
                    
                    if let secondaryAction = secondaryAction {
                        PiumsButton(
                            secondaryAction.title,
                            icon: secondaryAction.icon,
                            style: .outline,
                            size: .medium,
                            action: secondaryAction.action
                        )
                        .frame(maxWidth: 280)
                    }
                }
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Modern Navigation Bar
struct PiumsNavigationBar: View {
    let title: String
    let subtitle: String?
    let leftButton: BarButton?
    let rightButtons: [BarButton]
    
    struct BarButton: Identifiable {
        let id = UUID()
        let icon: String?
        let text: String?
        let style: ButtonStyle
        let action: () -> Void
        
        enum ButtonStyle {
            case primary, secondary, text
        }
        
        init(icon: String, style: ButtonStyle = .secondary, action: @escaping () -> Void) {
            self.icon = icon
            self.text = nil
            self.style = style
            self.action = action
        }
        
        init(text: String, style: ButtonStyle = .text, action: @escaping () -> Void) {
            self.icon = nil
            self.text = text
            self.style = style
            self.action = action
        }
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        leftButton: BarButton? = nil,
        rightButtons: [BarButton] = []
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leftButton = leftButton
        self.rightButtons = rightButtons
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Left Button
                if let leftButton = leftButton {
                    navigationButton(leftButton)
                } else {
                    Spacer()
                        .frame(width: 44, height: 44)
                }
                
                // Title Section
                VStack(spacing: 2) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.piumsTextPrimary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.piumsTextSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Right Buttons
                HStack(spacing: 8) {
                    ForEach(rightButtons) { button in
                        navigationButton(button)
                    }
                    
                    if rightButtons.isEmpty {
                        Spacer()
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            Divider()
                .background(Color.piumsGrayLight)
        }
        .background(Color.piumsBackground)
    }
    
    @ViewBuilder
    private func navigationButton(_ button: BarButton) -> some View {
        Button(action: button.action) {
            Group {
                if let icon = button.icon {
                    Image(systemName: icon)
                        .font(.title3.weight(.medium))
                } else if let text = button.text {
                    Text(text)
                        .font(.body.weight(.medium))
                }
            }
            .foregroundColor(colorForButtonStyle(button.style))
            .frame(width: 44, height: 44)
            .background(
                backgroundForButtonStyle(button.style)
            )
            .clipShape(Circle())
        }
        .buttonStyle(PiumsButtonStyle())
    }
    
    private func colorForButtonStyle(_ style: BarButton.ButtonStyle) -> Color {
        switch style {
        case .primary: return .white
        case .secondary: return .piumsPrimary
        case .text: return .piumsPrimary
        }
    }
    
    private func backgroundForButtonStyle(_ style: BarButton.ButtonStyle) -> Color {
        switch style {
        case .primary: return .piumsPrimary
        case .secondary: return .piumsPrimary.opacity(0.1)
        case .text: return .clear
        }
    }
}

// MARK: - Availability Badge (inspirado en cliente)
struct PiumsAvailabilityBadge: View {
    let isAvailable: Bool
    let size: BadgeSize
    
    enum BadgeSize {
        case small, medium, large
        
        var metrics: (font: Font, padding: EdgeInsets) {
            switch self {
            case .small:
                return (.caption2.weight(.bold), EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
            case .medium:
                return (.caption.weight(.bold), EdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10))
            case .large:
                return (.subheadline.weight(.bold), EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            }
        }
    }
    
    init(isAvailable: Bool, size: BadgeSize = .medium) {
        self.isAvailable = isAvailable
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isAvailable ? Color.piumsSuccess : Color.piumsError)
                .frame(width: 6, height: 6)
            
            Text(isAvailable ? "Disponible" : "Ocupado")
                .font(size.metrics.font)
        }
        .foregroundColor(.white)
        .padding(size.metrics.padding)
        .background(isAvailable ? Color.piumsSuccess : Color.piumsError)
        .clipShape(Capsule())
    }
}

// MARK: - Artist Avatar with Initials (inspirado en cliente)
struct PiumsAvatarView: View {
    let name: String
    let imageURL: String?
    let size: CGFloat
    let gradientColors: [Color]
    
    private var initials: String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0) } }
            .joined()
            .uppercased()
    }
    
    init(name: String, imageURL: String? = nil, size: CGFloat = 60, gradientColors: [Color] = [.piumsPrimary, .piumsSecondary]) {
        self.name = name
        self.imageURL = imageURL
        self.size = size
        self.gradientColors = gradientColors
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: size, height: size)
            .clipShape(Circle())
            
            // Profile image or initials
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                } placeholder: {
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(.white)
                }
            } else {
                Text(initials)
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - Success/Error Banners (del cliente)
struct PiumsSuccessBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.piumsSuccess)
            
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.piumsSuccess)
            
            Spacer()
        }
        .padding(16)
        .background(Color.piumsSuccess.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.piumsSuccess.opacity(0.3), lineWidth: 1)
        )
    }
}

struct PiumsErrorBanner: View {
    let message: String
    let onDismiss: (() -> Void)?
    
    init(message: String, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundColor(.piumsError)
            
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.piumsError)
            
            Spacer()
            
            if let onDismiss = onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.piumsError)
                }
            }
        }
        .padding(16)
        .background(Color.piumsError.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.piumsError.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Preview
#Preview("Modern Piums Components") {
    NavigationView {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Navigation Bar
                PiumsNavigationBar(
                    title: "Dashboard",
                    subtitle: "Bienvenido de vuelta",
                    leftButton: PiumsNavigationBar.BarButton(icon: "line.horizontal.3") {},
                    rightButtons: [
                        PiumsNavigationBar.BarButton(icon: "bell", style: .secondary) {},
                        PiumsNavigationBar.BarButton(icon: "person.circle", style: .primary) {}
                    ]
                )
                
                VStack(spacing: 20) {
                    // Avatars and Badges (inspirado en cliente)
                    PiumsCard(style: .bordered) {
                        VStack(spacing: 16) {
                            Text("Avatares y Badges (Cliente Style)")
                                .font(.headline.weight(.semibold))
                            
                            HStack(spacing: 16) {
                                PiumsAvatarView(name: "María García", size: 60, gradientColors: [.piumsOrange, .piumsAccent])
                                PiumsAvatarView(name: "Carlos Ruiz", size: 60, gradientColors: [.piumsPrimary, .piumsSecondary])
                                PiumsAvatarView(name: "Ana López", size: 60, gradientColors: [.piumsSuccess, .piumsInfo])
                            }
                            
                            HStack(spacing: 12) {
                                PiumsAvailabilityBadge(isAvailable: true)
                                PiumsAvailabilityBadge(isAvailable: false)
                            }
                        }
                    }
                    
                    // Banners (del cliente)
                    VStack(spacing: 12) {
                        PiumsSuccessBanner(message: "¡Reserva confirmada exitosamente!")
                        PiumsErrorBanner(message: "Error al conectar con el servidor") {}
                    }
                    
                    // Stats Cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        PiumsStatsCard(
                            title: "Reservas Hoy",
                            value: "12",
                            subtitle: "3 pendientes",
                            icon: "calendar.day.timeline.leading",
                            trend: .up,
                            trendValue: "+15%",
                            color: .piumsPrimary
                        )
                        
                        PiumsStatsCard(
                            title: "Ingresos",
                            value: "€2,340",
                            subtitle: "Este mes",
                            icon: "dollarsign.circle.fill",
                            trend: .up,
                            trendValue: "+8%",
                            color: .piumsSuccess
                        )
                    }
                    
                    // Buttons Showcase
                    PiumsCard(style: .bordered) {
                        VStack(spacing: 16) {
                            Text("Botones Modernos")
                                .font(.headline.weight(.semibold))
                            
                            VStack(spacing: 12) {
                                PiumsButton("Confirmar Reserva", icon: "checkmark", style: .primary) {}
                                PiumsButton("Ver Detalles", icon: "eye", style: .secondary) {}
                                PiumsButton("Cancelar", style: .outline) {}
                                PiumsButton("Eliminar", icon: "trash", style: .destructive) {}
                            }
                        }
                    }
                    
                    // Status Badges
                    PiumsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Estados")
                                .font(.headline.weight(.semibold))
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                                PiumsStatusBadge("Confirmado", status: .success)
                                PiumsStatusBadge("Pendiente", status: .warning)
                                PiumsStatusBadge("Cancelado", status: .error)
                                PiumsStatusBadge("Premium", status: .premium)
                                PiumsStatusBadge("Información", status: .info)
                                PiumsStatusBadge("Normal", status: .neutral)
                            }
                        }
                    }
                    
                    // Text Fields
                    PiumsCard(style: .elevated) {
                        VStack(spacing: 20) {
                            Text("Campos de Texto")
                                .font(.headline.weight(.semibold))
                            
                            VStack(spacing: 16) {
                                PiumsTextField(
                                    "Nombre Completo",
                                    placeholder: "Escribe tu nombre",
                                    text: .constant(""),
                                    icon: "person"
                                )
                                
                                PiumsTextField(
                                    "Email",
                                    placeholder: "tu@email.com",
                                    text: .constant(""),
                                    keyboardType: .emailAddress,
                                    icon: "envelope"
                                )
                                
                                PiumsTextField(
                                    "Teléfono",
                                    placeholder: "+34 600 000 000",
                                    text: .constant(""),
                                    keyboardType: .phonePad,
                                    icon: "phone"
                                )
                            }
                        }
                    }
                    
                    // Loading States
                    HStack(spacing: 16) {
                        PiumsLoadingView("Cargando datos...", style: .card)
                            .frame(height: 120)
                        
                        PiumsLoadingView("Procesando...", style: .card)
                            .frame(height: 120)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
    }
}
