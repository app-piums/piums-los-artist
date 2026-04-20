//
//  ForgotPasswordView.swift
//  PiumsArtist
//

import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var step = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(.secondarySystemGroupedBackground).ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        ZStack {
                            Circle().fill(Color.piumsOrange.opacity(0.1)).frame(width: 80, height: 80)
                            Circle().fill(Color.piumsOrange.opacity(0.18)).frame(width: 56, height: 56)
                            Image(systemName: step == 0 ? "envelope.fill" : "lock.rotation")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(.piumsOrange)
                        }
                        .padding(.top, 24)

                        VStack(spacing: 8) {
                            Text(step == 0 ? "¿Olvidaste tu contraseña?" : "Nueva contraseña")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.piumsTextPrimary)
                            Text(step == 0
                                 ? "Escribe tu correo y te enviaremos un código de recuperación."
                                 : "Ingresa el código que recibiste y elige una nueva contraseña.")
                                .font(.subheadline)
                                .foregroundColor(.piumsTextSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }

                        if step == 0 { emailStep } else { resetStep }

                        if let err = errorMessage {
                            feedbackRow(err, isError: true)
                        }
                        if let ok = successMessage {
                            feedbackRow(ok, isError: false)
                        }

                        Spacer(minLength: 40)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Recuperar contraseña")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }.foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: Step 1 — email
    private var emailStep: some View {
        VStack(spacing: 14) {
            inputField("correo@ejemplo.com", text: $email, keyboard: .emailAddress)

            actionButton("Enviar código", enabled: email.contains("@") && email.contains(".")) {
                Task { await sendCode() }
            }

            Button("Ya tengo un código →") { step = 1 }
                .font(.subheadline)
                .foregroundColor(.piumsOrange)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Step 2 — reset
    private var resetStep: some View {
        VStack(spacing: 12) {
            inputField("Código de verificación", text: $code, keyboard: .numberPad)
            secureInputField("Nueva contraseña (mín. 6)", text: $newPassword)
            secureInputField("Confirmar contraseña", text: $confirmPassword)

            if !newPassword.isEmpty && !confirmPassword.isEmpty && newPassword != confirmPassword {
                Text("Las contraseñas no coinciden")
                    .font(.caption)
                    .foregroundColor(.piumsError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            actionButton("Cambiar contraseña", enabled: canReset) {
                Task { await resetPassword() }
            }

            Button("← Volver a enviar código") { step = 0 }
                .font(.subheadline)
                .foregroundColor(.piumsOrange)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Helpers
    private var canReset: Bool {
        !code.isEmpty && newPassword.count >= 6 && newPassword == confirmPassword
    }

    private func inputField(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(14)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private func secureInputField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .padding(14)
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }

    private func actionButton(_ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(label)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(enabled && !isLoading ? Color.piumsOrange : Color.gray.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!enabled || isLoading)
    }

    private func feedbackRow(_ msg: String, isError: Bool) -> some View {
        let color: Color = isError ? .piumsError : .piumsSuccess
        return HStack(spacing: 8) {
            Image(systemName: isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(color)
            Text(msg).font(.caption).foregroundColor(color)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
    }

    // MARK: API calls
    private func sendCode() async {
        isLoading = true; errorMessage = nil; successMessage = nil
        do {
            struct Body: Codable { let email: String }
            let _ = try await APIService.shared.post(
                endpoint: .forgotPassword,
                body: Body(email: email),
                responseType: EmptyResponseDTO.self
            )
            successMessage = "Código enviado a \(email). Revisa tu bandeja de entrada."
            withAnimation { step = 1 }
        } catch {
            if let e = error as? APIError { errorMessage = e.errorDescription }
            else { errorMessage = error.localizedDescription }
        }
        isLoading = false
    }

    private func resetPassword() async {
        isLoading = true; errorMessage = nil
        do {
            struct Body: Codable { let token: String; let newPassword: String }
            let _ = try await APIService.shared.post(
                endpoint: .resetPassword,
                body: Body(token: code, newPassword: newPassword),
                responseType: EmptyResponseDTO.self
            )
            successMessage = "Contraseña cambiada exitosamente. Ya puedes iniciar sesión."
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { dismiss() }
        } catch {
            if let e = error as? APIError { errorMessage = e.errorDescription }
            else { errorMessage = error.localizedDescription }
        }
        isLoading = false
    }
}

#Preview { ForgotPasswordView() }
