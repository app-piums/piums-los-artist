//
//  RegisterView.swift
//  PiumsArtist
//

import SwiftUI

struct RegisterView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Field?

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirm = false
    @State private var animateIn = false
    @State private var glowPulse = false
    @State private var localError: String?

    enum Field { case name, email, password, confirm }

    private var validationError: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return "El nombre es requerido." }
        if !email.contains("@") || !email.contains(".") { return "Ingresa un correo válido." }
        if password.count < 6 { return "La contraseña debe tener al menos 6 caracteres." }
        if password != confirmPassword { return "Las contraseñas no coinciden." }
        return nil
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                backgroundLayer(geo: geo)
                registerCard
                    .frame(maxHeight: geo.size.height * 0.62)
                    .offset(y: animateIn ? 0 : geo.size.height * 0.8)
            }
            .ignoresSafeArea(.container)
        }
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .onAppear {
            withAnimation(.spring(response: 0.75, dampingFraction: 0.88).delay(0.05)) { animateIn = true }
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true).delay(0.3)) { glowPulse = true }
        }
        .alert("Error", isPresented: .constant(authService.errorMessage != nil)) {
            Button("Aceptar") { authService.errorMessage = nil }
        } message: { Text(authService.errorMessage ?? "") }
    }

    // MARK: - Background

    @ViewBuilder
    private func backgroundLayer(geo: GeometryProxy) -> some View {
        ZStack(alignment: .top) {
            Color.piumsBackground.ignoresSafeArea()

            Circle()
                .fill(Color.piumsOrange.opacity(glowPulse ? 0.30 : 0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 55)
                .offset(y: geo.safeAreaInsets.top + 60)

            VStack(spacing: 0) {
                Spacer().frame(height: geo.safeAreaInsets.top + 16)

                Image("PiumsLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                    .opacity(animateIn ? 1 : 0)
                    .animation(.easeOut(duration: 0.4), value: animateIn)

                Spacer().frame(height: 20)

                ZStack {
                    Circle()
                        .fill(Color.piumsOrange.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .blur(radius: 12)
                    Circle()
                        .fill(Color.piumsBackgroundElevated)
                        .frame(width: 80, height: 80)
                        .overlay(Circle().fill(Color.piumsOrange.opacity(0.22)))
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 30, weight: .regular))
                        .foregroundStyle(Color.piumsOrange)
                }
                .scaleEffect(animateIn ? 1 : 0.6)
                .opacity(animateIn ? 1 : 0)
                .animation(.spring(response: 0.55, dampingFraction: 0.7).delay(0.08), value: animateIn)

                Spacer().frame(height: 12)

                VStack(spacing: 4) {
                    Text("Crea tu cuenta")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Únete a la comunidad de artistas")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .opacity(animateIn ? 1 : 0)
                .animation(.easeOut(duration: 0.45).delay(0.15), value: animateIn)

                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Card

    private var registerCard: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.18))
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, 22)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {

                        VStack(alignment: .leading, spacing: 5) {
                            Text("Registro de Artista")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.piumsLabel)
                            Text("Completa tu información para comenzar.")
                                .font(.subheadline)
                                .foregroundStyle(Color.piumsLabelSecondary)
                        }

                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(Color.piumsOrange)
                                .font(.subheadline)
                                .padding(.top, 1)
                            Text("Tu cuenta requiere activación por el equipo de Piums. Una vez registrado recibirás confirmación a tu correo en 24-48 h.")
                                .font(.caption)
                                .foregroundStyle(Color.piumsLabelSecondary)
                        }
                        .padding(12)
                        .background(Color.piumsOrange.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(spacing: 12) {
                            inputField(label: "NOMBRE", placeholder: "Tu nombre completo",
                                       text: $name, field: .name, next: .email,
                                       keyboard: .default, content: .name)
                                .id(Field.name)

                            inputField(label: "CORREO", placeholder: "nombre@ejemplo.com",
                                       text: $email, field: .email, next: .password,
                                       keyboard: .emailAddress, content: .emailAddress)
                                .id(Field.email)

                            passwordField(label: "CONTRASEÑA", placeholder: "Mínimo 6 caracteres",
                                          text: $password, show: $showPassword, field: .password, next: .confirm)
                                .id(Field.password)

                            passwordField(label: "CONFIRMAR CONTRASEÑA", placeholder: "Repite la contraseña",
                                          text: $confirmPassword, show: $showConfirm, field: .confirm, next: nil)
                                .id(Field.confirm)
                        }

                        // Error
                        let errorMsg = localError ?? (authService.errorMessage ?? "")
                        if !errorMsg.isEmpty {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(Color.piumsError)
                                Text(errorMsg)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.piumsError)
                                Spacer()
                            }
                            .padding(14)
                            .background(Color.piumsError.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }

                        // Botón registrar
                        registerButton

                        // Ya tengo cuenta
                        HStack(spacing: 4) {
                            Text("¿Ya tienes cuenta?")
                                .font(.subheadline)
                                .foregroundStyle(Color.piumsLabelSecondary)
                            Button("Iniciar sesión") { dismiss() }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.piumsOrange)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 26)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: focused) { _, newFocus in
                    guard let field = newFocus else { return }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            proxy.scrollTo(field, anchor: .center)
                        }
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.piumsBackgroundSecondary)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Fields

    private func inputField(label: String, placeholder: String, text: Binding<String>,
                            field: Field, next: Field?, keyboard: UIKeyboardType,
                            content: UITextContentType) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .tracking(1.2)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .textContentType(content)
                .autocorrectionDisabled()
                .textInputAutocapitalization(field == .name ? .words : .never)
                .focused($focused, equals: field)
                .submitLabel(next != nil ? .next : .done)
                .onSubmit { focused = next }
                .padding(.horizontal, 16).padding(.vertical, 15)
                .background(Color.piumsBackgroundElevated)
                .clipShape(RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13)
                    .strokeBorder(focused == field ? Color.piumsOrange.opacity(0.7) : .clear, lineWidth: 1.5))
                .animation(.easeInOut(duration: 0.2), value: focused == field)
        }
    }

    private func passwordField(label: String, placeholder: String, text: Binding<String>,
                               show: Binding<Bool>, field: Field, next: Field?) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(label)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .tracking(1.2)
            HStack(spacing: 0) {
                Group {
                    if show.wrappedValue {
                        TextField(placeholder, text: text)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                }
                .textContentType(.password)
                .focused($focused, equals: field)
                .submitLabel(next != nil ? .next : .done)
                .onSubmit { focused = next }

                Button { show.wrappedValue.toggle() } label: {
                    Image(systemName: show.wrappedValue ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(focused == field ? Color.piumsOrange.opacity(0.8) : .secondary)
                        .padding(.trailing, 2)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 15)
            .background(Color.piumsBackgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13)
                .strokeBorder(focused == field ? Color.piumsOrange.opacity(0.7) : .clear, lineWidth: 1.5))
            .animation(.easeInOut(duration: 0.2), value: focused == field)
        }
    }

    // MARK: - Register Button

    private var registerButton: some View {
        let empty = name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty
        return Button {
            localError = validationError
            guard localError == nil else { return }
            Task { await authService.register(name: name.trimmingCharacters(in: .whitespaces),
                                              email: email, password: password) }
        } label: {
            ZStack {
                if authService.isLoading {
                    HStack(spacing: 8) {
                        ProgressView().tint(.white).scaleEffect(0.85)
                        Text("Creando cuenta…").font(.body.bold())
                    }
                } else {
                    Text("Crear cuenta").font(.body.bold())
                }
            }
            .frame(maxWidth: .infinity).frame(height: 54)
            .background(LinearGradient(
                colors: empty
                    ? [Color.piumsOrange.opacity(0.4), Color.piumsOrange.opacity(0.4)]
                    : [Color(red: 0.85, green: 0.38, blue: 0.12), Color(red: 0.72, green: 0.28, blue: 0.07)],
                startPoint: .topLeading, endPoint: .bottomTrailing))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(authService.isLoading || empty)
        .animation(.easeInOut(duration: 0.2), value: empty)
    }
}

#Preview { RegisterView() }
