//
//  ReviewsView.swift
//  PiumsArtist
//
//  Pantalla de reseñas recibidas — equivale a /artist/dashboard/reviews en la web.
//  Permite ver las reseñas, responderlas y paginar.
//

import SwiftUI
import Combine

// MARK: - ViewModel

@MainActor
final class ReviewsViewModel: ObservableObject {
    @Published var reviews: [ReviewDetailedDTO] = []
    @Published var total: Int = 0
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    @Published var isLoading = false
    @Published var errorMessage: String?

    // Estado del formulario de respuesta
    @Published var respondingToId: String?
    @Published var responseText: String = ""
    @Published var isSendingResponse = false
    @Published var responseError: String?

    private let api = APIService.shared

    init() {
        Task { await loadReviews() }
    }

    func refreshData() async { await loadReviews() }

    @MainActor
    func loadReviews() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        guard let artistId = AuthService.shared.artistBackendId, !artistId.isEmpty else {
            // Si el perfil aún no cargó, intentarlo
            if let profileResp = try? await api.get(endpoint: .artistDashboard, responseType: ArtistProfileResponseDTO.self) {
                AuthService.shared.artistBackendId = profileResp.artist.id
            }
            guard let artistId = AuthService.shared.artistBackendId else {
                errorMessage = "No se pudo obtener el perfil de artista."
                return
            }
            await fetchReviews(artistId: artistId)
            return
        }
        await fetchReviews(artistId: artistId)
    }

    private func fetchReviews(artistId: String) async {
        do {
            let resp = try await api.get(
                endpoint: .reviewsList(artistId: artistId, page: currentPage),
                responseType: ReviewsListResponseDTO.self
            )
            reviews = resp.reviews
            total = resp.total
            totalPages = resp.totalPages
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func goToPage(_ page: Int) {
        guard page >= 1, page <= totalPages else { return }
        currentPage = page
        Task { await loadReviews() }
    }

    @MainActor
    func submitResponse(reviewId: String) async {
        guard !responseText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSendingResponse = true
        responseError = nil
        let body = RespondToReviewRequest(message: responseText.trimmingCharacters(in: .whitespaces))
        do {
            let _ = try await api.post(
                endpoint: .respondToReview(reviewId),
                body: body,
                responseType: ReviewResponseDTO.self
            )
            responseText = ""
            respondingToId = nil
            await loadReviews()
        } catch {
            responseError = error.localizedDescription
        }
        isSendingResponse = false
    }
}

// MARK: - ReviewsView

struct ReviewsView: View {
    @StateObject private var vm = ReviewsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                if vm.isLoading {
                    ProgressView()
                        .tint(.piumsOrange)
                        .padding(.top, 80)
                } else if let err = vm.errorMessage {
                    errorState(err)
                } else if vm.reviews.isEmpty {
                    emptyState
                        .padding(.top, 60)
                } else {
                    reviewsList
                        .padding(.horizontal, 16)
                    paginationBar
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                }

                Spacer(minLength: 120)
            }
        }
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Reseñas")
        .navigationBarTitleDisplayMode(.large)
        .refreshable { await vm.refreshData() }
    }

    // MARK: Header

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reseñas de clientes")
                    .font(.title2.weight(.bold))
                if vm.total > 0 {
                    Text("\(vm.total) reseña\(vm.total == 1 ? "" : "s") en total")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    // MARK: Reviews list

    private var reviewsList: some View {
        VStack(spacing: 12) {
            ForEach(vm.reviews, id: \.id) { review in
                ReviewCard(review: review, vm: vm)
            }
        }
    }

    // MARK: Pagination

    private var paginationBar: some View {
        Group {
            if vm.totalPages > 1 {
                HStack(spacing: 12) {
                    Button {
                        vm.goToPage(vm.currentPage - 1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.footnote.weight(.semibold))
                    }
                    .disabled(vm.currentPage <= 1)

                    Text("Página \(vm.currentPage) de \(vm.totalPages)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button {
                        vm.goToPage(vm.currentPage + 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                    }
                    .disabled(vm.currentPage >= vm.totalPages)
                }
                .foregroundColor(.piumsOrange)
            }
        }
    }

    // MARK: Empty / Error

    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("⭐")
                .font(.system(size: 56))
            Text("Sin reseñas todavía")
                .font(.headline)
            Text("Las reseñas de tus clientes aparecerán aquí una vez que completen un servicio.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.piumsError)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar") { Task { await vm.refreshData() } }
                .buttonStyle(.borderedProminent)
                .tint(.piumsOrange)
        }
        .padding(.top, 60)
    }
}

// MARK: - Review Card

private struct ReviewCard: View {
    let review: ReviewDetailedDTO
    @ObservedObject var vm: ReviewsViewModel

    private var isResponding: Bool { vm.respondingToId == review.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top row: stars + status badge
            HStack(alignment: .top) {
                StarRatingView(rating: review.rating)
                Spacer()
                statusBadge
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            // Date
            Text(formattedDate(review.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 4)

            // Comment
            if let comment = review.comment, !comment.isEmpty {
                Text(comment)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
            }

            Divider()
                .padding(.horizontal, 16)
                .padding(.top, 12)

            // Artist response (if exists)
            if let resp = review.response {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu respuesta")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.piumsOrange)
                    Text(resp.message)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Text(formattedDate(resp.createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.piumsOrange.opacity(0.08))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            } else {
                // Respond form or button
                if isResponding {
                    respondForm
                } else {
                    respondButton
                }
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    // MARK: Status badge

    private var statusBadge: some View {
        let (label, fg, bg): (String, Color, Color) = {
            switch (review.status ?? "").uppercased() {
            case "PUBLISHED": return ("Publicada", .green, Color.green.opacity(0.12))
            case "PENDING":   return ("Pendiente", .orange, Color.orange.opacity(0.12))
            case "HIDDEN":    return ("Oculta", .gray, Color.gray.opacity(0.12))
            default:          return ("Publicada", .green, Color.green.opacity(0.12))
            }
        }()
        return Text(label)
            .font(.caption.weight(.semibold))
            .foregroundColor(fg)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(bg)
            .clipShape(Capsule())
    }

    // MARK: Response controls

    private var respondButton: some View {
        Button {
            vm.respondingToId = review.id
            vm.responseText = ""
            vm.responseError = nil
        } label: {
            Label("Responder", systemImage: "bubble.left.and.bubble.right")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.piumsOrange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var respondForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Escribe tu respuesta")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            TextEditor(text: $vm.responseText)
                .frame(minHeight: 72)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .font(.subheadline)

            if let errMsg = vm.responseError {
                Text(errMsg)
                    .font(.caption)
                    .foregroundColor(.piumsError)
            }

            HStack(spacing: 10) {
                Button("Cancelar") {
                    vm.respondingToId = nil
                    vm.responseText = ""
                    vm.responseError = nil
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                Spacer()

                Button {
                    Task { await vm.submitResponse(reviewId: review.id) }
                } label: {
                    if vm.isSendingResponse {
                        ProgressView().tint(.white).scaleEffect(0.85)
                    } else {
                        Text("Publicar")
                            .font(.subheadline.weight(.semibold))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(
                    vm.responseText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSendingResponse
                    ? Color.gray.opacity(0.5) : Color.piumsOrange
                )
                .cornerRadius(10)
                .disabled(vm.responseText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSendingResponse)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .padding(.top, 8)
    }

    // MARK: Helpers

    private func formattedDate(_ iso: String) -> String {
        let isoFull = ISO8601DateFormatter()
        isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFull.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        return date.formatted(.dateTime.day().month(.wide).year())
    }
}

// MARK: - Star Rating View

struct StarRatingView: View {
    let rating: Int
    var body: some View {
        HStack(spacing: 3) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.caption)
                    .foregroundColor(star <= rating ? .yellow : Color(.systemGray4))
            }
        }
    }
}

#Preview { NavigationView { ReviewsView() } }
