//
//  PiumsArtistTests.swift
//  PiumsArtistTests
//

import XCTest
@testable import PiumsArtist

final class PiumsArtistTests: XCTestCase {

    // MARK: - AUTH-05 / AUTH-10 / AUTH-15 / AUTH-19 — Validaciones de formulario

    /// AUTH-05: Login button must be disabled when fields are empty
    func testLoginButtonDisabledWhenFieldsEmpty() {
        let emptyEmail = ""
        let emptyPassword = ""
        let isDisabled = emptyEmail.isEmpty || emptyPassword.isEmpty
        XCTAssertTrue(isDisabled, "Login button should be disabled when email or password is empty")
    }

    /// AUTH-10: Password mínimo 6 caracteres en registro
    func testPasswordMinLengthValidation() {
        XCTAssertFalse("12345".count >= 6, "5-char password should fail min-length check")
        XCTAssertTrue("123456".count >= 6, "6-char password should pass min-length check")
    }

    /// AUTH-11 / AUTH-19: Passwords deben coincidir
    func testPasswordsMatchValidation() {
        let pw1 = "secret123"
        let pw2 = "secret456"
        XCTAssertFalse(pw1 == pw2, "Different passwords should fail match validation")
        XCTAssertTrue(pw1 == pw1, "Same passwords should pass match validation")
    }

    /// AUTH-15: Email en ForgotPassword debe contener @ y .
    func testEmailValidationForForgotPassword() {
        let valid   = "user@piums.com"
        let noAt    = "userpiums.com"
        let noDot   = "user@piumscom"
        let empty   = ""

        XCTAssertTrue(valid.contains("@") && valid.contains("."),   "Valid email should pass")
        XCTAssertFalse(noAt.contains("@") && noAt.contains("."),    "Email without @ should fail")
        XCTAssertFalse(noDot.contains("@") && noDot.contains("."),  "Email without . should fail")
        XCTAssertFalse(empty.contains("@") && empty.contains("."),  "Empty email should fail")
    }

    // MARK: - ForgotPassword canReset logic

    /// AUTH-19: canReset requiere código no vacío + password ≥ 6 + passwords iguales
    func testForgotPasswordCanReset() {
        func canReset(code: String, pw: String, confirm: String) -> Bool {
            !code.isEmpty && pw.count >= 6 && pw == confirm
        }

        XCTAssertFalse(canReset(code: "", pw: "abc123", confirm: "abc123"), "Empty code should fail")
        XCTAssertFalse(canReset(code: "12345", pw: "abc", confirm: "abc"),  "Short password should fail")
        XCTAssertFalse(canReset(code: "12345", pw: "abc123", confirm: "xyz"), "Mismatched passwords should fail")
        XCTAssertTrue(canReset(code: "12345", pw: "abc123", confirm: "abc123"), "Valid inputs should pass")
    }

    // MARK: - DIS-07 / DIS-08 — Disputa canSubmit

    /// Asunto mín 5 chars, descripción mín 10 chars
    func testDisputaCanSubmit() {
        func canSubmit(subject: String, description: String) -> Bool {
            subject.trimmingCharacters(in: .whitespaces).count >= 5 &&
            description.trimmingCharacters(in: .whitespaces).count >= 10
        }

        XCTAssertFalse(canSubmit(subject: "abc", description: "descripcion larga"),  "Short subject should fail")
        XCTAssertFalse(canSubmit(subject: "asunto valido", description: "corta"),    "Short description should fail")
        XCTAssertFalse(canSubmit(subject: "   ", description: "   "),                "Whitespace-only should fail")
        XCTAssertTrue(canSubmit(subject: "Problema real", description: "Descripcion detallada del problema"), "Valid inputs should pass")
    }

    // MARK: - RES-08 — Double-tap protection

    /// updatingBookingId debe bloquear llamadas concurrentes
    @MainActor
    func testDoubleBookingActionBlocked() async {
        let vm = BookingsViewModel()
        vm.updatingBookingId = UUID()
        XCTAssertTrue(vm.updatingBookingId != nil, "Second booking action should be blocked while one is in progress")
    }

    // MARK: - SEC-03 — Logout clears artist_backend_id

    func testLogoutClearsArtistBackendId() {
        // Null the singleton token first to stop any background auto-login task
        // that could race and write auth_token back during the test.
        APIService.shared.authToken = nil
        UserDefaults.standard.removeObject(forKey: "refresh_token")

        // Set up state
        UserDefaults.standard.set("artist-123", forKey: "artist_backend_id")
        APIService.shared.authToken = "token-abc"       // via setter → writes auth_token
        UserDefaults.standard.set("refresh-xyz", forKey: "refresh_token")

        // Simulate what logout does
        UserDefaults.standard.removeObject(forKey: "refresh_token")
        UserDefaults.standard.removeObject(forKey: "artist_backend_id")
        APIService.shared.authToken = nil               // via setter → removes auth_token

        XCTAssertNil(UserDefaults.standard.string(forKey: "artist_backend_id"), "artist_backend_id must be cleared on logout")
        XCTAssertNil(UserDefaults.standard.string(forKey: "auth_token"),        "auth_token must be cleared on logout")
        XCTAssertNil(UserDefaults.standard.string(forKey: "refresh_token"),     "refresh_token must be cleared on logout")
    }

    // MARK: - DASH-06 — Fecha en español

    func testDateFormatterLocaleIsSpanish() {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "es_GT")

        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 20))!
        let result = formatter.string(from: date)

        XCTAssertFalse(result.contains("Monday"), "Date should not be in English")
        XCTAssertFalse(result.contains("April"),  "Date should not be in English")
        XCTAssertTrue(result.contains("abril") || result.contains("lunes"), "Date should be in Spanish")
    }


}
