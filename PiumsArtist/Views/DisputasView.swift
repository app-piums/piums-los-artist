//
//  DisputasView.swift
//  PiumsArtist
//
//  Lista de quejas/disputas — equivale a /artist/dashboard/quejas en la web.
//  Incluye DisputaDetailView con chat tipo WhatsApp para intercambio de mensajes.
//

import SwiftUI
import Combine

// MARK: - Shared helpers

private let statusConfig: [String: (label: String, fg: Color, bg: Color)] = [
    "OPEN":          ("Abierta",         .red,    Color.red.opacity(0.12)),
    "IN_REVIEW":     ("En revisión",     .blue,   Color.blue.opacity(0.12)),
    "AWAITING_INFO": ("Info solicitada", .orange, Color.orange.opacity(0.12)),
    "ESCALATED":     ("Escalada",        .purple, Color.purple.opacity(0.12)),
    "RESOLVED":      ("Resuelta",        .green,  Color.green.opacity(0.12)),
    "CLOSED":        ("Cerrada",         .gray,   Color.gray.opacity(0.12)),
]

private let typeLabels: [String: String] = [
    "CANCELLATION":   "Cancelación",
    "QUALITY":        "Calidad",
    "REFUND":         "Reembolso",
    "NO_SHOW":        "Cliente no se presentó",
    "ARTIST_NO_SHOW": "Artista no se presentó",
    "PRICING":        "Precio",
    "BEHAVIOR":       "Comportamiento",
    "OTHER":          "Otro",
]

// MARK: - Enriched model

struct DisputeItem: Identifiable {
    let dispute: DisputeDTO
    let myRole: String  // "reporter" | "reported"
    var id: String { dispute.id }
    var isActive: Bool {
        let s = dispute.status.uppercased()
        return s != "RESOLVED" && s != "CLOSED"
    }
}

// MARK: - DisputasViewModel

@MainActor
final class DisputasViewModel: ObservableObject {
    @Published var items: [DisputeItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    init() {
        Task { await loadDisputes() }
    }

    func refreshData() async { await loadDisputes() }

    @MainActor
    func loadDisputes() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let resp = try await api.get(endpoint: .myDisputes, responseType: MyDisputesResponseDTO.self)
            let reporters = (resp.asReporter ?? []).map { DisputeItem(dispute: $0, myRole: "reporter") }
            let reported  = (resp.asReported  ?? []).map { DisputeItem(dispute: $0, myRole: "reported") }
            let all = (reporters + reported).sorted {
                $0.dispute.createdAt > $1.dispute.createdAt
            }
            items = all
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - DisputasView (List)

struct DisputasView: View {
    @StateObject private var vm = DisputasViewModel()

    var body: some View {
        NavigationView {
            Group {
                if vm.isLoading {
                    ProgressView().tint(.piumsOrange)
                } else if let err = vm.errorMessage {
                    errorState(err)
                } else if vm.items.isEmpty {
                    emptyState
                } else {
                    list
                }
            }
            .navigationTitle("Mis Quejas")
            .navigationBarTitleDisplayMode(.large)
            .refreshable { await vm.refreshData() }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: List

    private var list: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(vm.items) { item in
                    NavigationLink {
                        DisputaDetailView(disputeId: item.id, myRole: item.myRole)
                    } label: {
                        DisputaRowView(item: item)
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
    }

    // MARK: Empty / Error

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 56))
                .foregroundColor(.piumsSuccess)
            Text("Sin quejas registradas")
                .font(.headline)
            Text("Si tienes un problema con una reserva puedes reportarlo desde la pantalla de Reservas.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private func errorState(_ msg: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.piumsError)
            Text(msg)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar") { Task { await vm.refreshData() } }
                .buttonStyle(.borderedProminent)
                .tint(.piumsOrange)
        }
    }
}

// MARK: - DisputaRowView

struct DisputaRowView: View {
    let item: DisputeItem

    var body: some View {
        let d = item.dispute
        let cfg = statusConfig[d.status.uppercased()] ?? statusConfig["OPEN"]!
        let lastMsg = (d.messages ?? []).filter { !($0.isStatusUpdate ?? false) }.last
        let hasUnread = item.isActive && lastMsg?.senderType != "artist"

        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                // Badges row
                HStack(spacing: 6) {
                    Text(cfg.label)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(cfg.fg)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(cfg.bg)
                        .clipShape(Capsule())

                    Text(typeLabels[d.disputeType] ?? d.disputeType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())

                    if item.myRole == "reported" {
                        Text("Fuiste reportado")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text(d.subject)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if let msg = lastMsg {
                    HStack(spacing: 4) {
                        if hasUnread {
                            Circle()
                                .fill(Color.piumsOrange)
                                .frame(width: 7, height: 7)
                        }
                        Text(senderPrefix(msg.senderType ?? ""))
                            .font(.caption.weight(.medium))
                            .foregroundColor(hasUnread ? .piumsOrange : .secondary)
                        Text(msg.message)
                            .font(.caption)
                            .foregroundColor(hasUnread ? .piumsOrange : .secondary)
                            .lineLimit(1)
                    }
                } else {
                    Text(formattedDate(d.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 4) {
                if hasUnread {
                    Circle()
                        .fill(Color.piumsOrange)
                        .frame(width: 8, height: 8)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.piumsOrange)
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func senderPrefix(_ type: String) -> String {
        switch type {
        case "artist": return "Tú:"
        case "client": return "Cliente:"
        case "staff":  return "Piums:"
        default:       return ""
        }
    }

    private func formattedDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let d = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        return d.formatted(.dateTime.day().month(.wide).year())
    }
}

// MARK: - DisputaDetailView (Chat)

@MainActor
final class DisputaDetailViewModel: ObservableObject {
    @Published var dispute: DisputeDTO?
    @Published var messages: [DisputeMessageDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newMessage: String = ""
    @Published var isSending = false
    @Published var sendError: String?

    let disputeId: String
    let myRole: String
    private let api = APIService.shared

    init(disputeId: String, myRole: String) {
        self.disputeId = disputeId
        self.myRole = myRole
        Task { await loadDetail() }
    }

    @MainActor
    func loadDetail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let d = try await api.get(endpoint: .disputeById(disputeId), responseType: DisputeDTO.self)
            dispute = d
            messages = (d.messages ?? []).sorted { $0.createdAt < $1.createdAt }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var isActive: Bool {
        let s = (dispute?.status ?? "").uppercased()
        return s != "RESOLVED" && s != "CLOSED"
    }

    @MainActor
    func sendMessage() async {
        let text = newMessage.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        isSending = true
        sendError = nil

        // Optimistic
        let optimistic = DisputeMessageDTO(
            id: UUID().uuidString,
            disputeId: disputeId,
            senderType: "artist",
            message: text,
            isStatusUpdate: false,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(optimistic)
        newMessage = ""

        let body = AddDisputeMessageRequest(message: text)
        do {
            let _ = try await api.post(
                endpoint: .addDisputeMessage(disputeId),
                body: body,
                responseType: DisputeMessageDTO.self
            )
            await loadDetail()
        } catch {
            // Revertir el mensaje optimista
            messages.removeLast()
            newMessage = text
            sendError = error.localizedDescription
        }
        isSending = false
    }
}

struct DisputaDetailView: View {
    let disputeId: String
    let myRole: String

    @StateObject private var vm: DisputaDetailViewModel
    @FocusState private var inputFocused: Bool

    init(disputeId: String, myRole: String) {
        self.disputeId = disputeId
        self.myRole = myRole
        _vm = StateObject(wrappedValue: DisputaDetailViewModel(disputeId: disputeId, myRole: myRole))
    }

    var body: some View {
        VStack(spacing: 0) {
            if vm.isLoading && vm.dispute == nil {
                Spacer()
                ProgressView().tint(.piumsOrange)
                Spacer()
            } else if let err = vm.errorMessage {
                Spacer()
                Text(err).font(.subheadline).foregroundColor(.secondary).padding()
                Spacer()
            } else {
                // Info bar
                if let d = vm.dispute {
                    disputeInfoBar(d)
                }

                Divider()

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(Array(vm.messages.enumerated()), id: \.offset) { _, msg in
                                if msg.isStatusUpdate ?? false {
                                    StatusUpdateBubble(message: msg)
                                } else {
                                    ChatDisputeBubble(message: msg, isFromMe: msg.senderType == "artist")
                                }
                            }

                            if let err = vm.sendError {
                                Text(err)
                                    .font(.caption)
                                    .foregroundColor(.piumsError)
                                    .padding(.horizontal, 16)
                                    .padding(.top, 4)
                            }

                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: vm.messages.count) { _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                    .onAppear {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }

                Divider()

                // Input bar
                if vm.isActive {
                    inputBar
                } else {
                    closedBar
                }
            }
        }
        .navigationTitle(vm.dispute?.subject ?? "Queja")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Info bar

    private func disputeInfoBar(_ d: DisputeDTO) -> some View {
        let cfg = statusConfig[d.status.uppercased()] ?? statusConfig["OPEN"]!
        return HStack(spacing: 8) {
            Text(cfg.label)
                .font(.caption.weight(.semibold))
                .foregroundColor(cfg.fg)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(cfg.bg)
                .clipShape(Capsule())

            Text(typeLabels[d.disputeType] ?? d.disputeType)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color(.systemGray6))
                .clipShape(Capsule())

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.tertiarySystemGroupedBackground))
    }

    // MARK: Input bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Escribe un mensaje…", text: $vm.newMessage, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(20)
                .focused($inputFocused)

            Button {
                Task { await vm.sendMessage() }
            } label: {
                if vm.isSending {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 36, height: 36)
            .background(vm.newMessage.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSending
                        ? Color.gray.opacity(0.4) : Color.piumsOrange)
            .clipShape(Circle())
            .disabled(vm.newMessage.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    private var closedBar: some View {
        Text("Esta queja está cerrada")
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(.tertiarySystemGroupedBackground))
    }
}

// MARK: - Chat Bubble (Dispute)

struct ChatDisputeBubble: View {
    let message: DisputeMessageDTO
    let isFromMe: Bool

    var body: some View {
        HStack {
            if isFromMe { Spacer(minLength: 60) }

            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                if !isFromMe {
                    senderLabel
                }
                Text(message.message)
                    .font(.subheadline)
                    .foregroundColor(isFromMe ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isFromMe ? Color.piumsOrange : Color(.systemGray5))
                    .cornerRadius(18)

                Text(formattedTime(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isFromMe { Spacer(minLength: 60) }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 3)
    }

    private var senderLabel: some View {
        Text({
            switch message.senderType ?? "" {
            case "client": return "Cliente"
            case "staff":  return "Piums"
            default:       return ""
            }
        }())
        .font(.caption.weight(.semibold))
        .foregroundColor(.secondary)
        .padding(.leading, 4)
    }

    private func formattedTime(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let d = f.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) ?? Date()
        return d.formatted(.dateTime.hour().minute())
    }
}

// MARK: - Status Update Bubble

struct StatusUpdateBubble: View {
    let message: DisputeMessageDTO

    var body: some View {
        HStack {
            Spacer()
            Text(message.message)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }
}

#Preview { DisputasView() }
