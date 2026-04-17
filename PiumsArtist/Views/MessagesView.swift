//
//  MessagesView.swift
//  PiumsArtist
//
//  Estilo idéntico al de la app de cliente (ChatInboxView / ChatDetailView).
//  Conectado a MessagesViewModel — carga conversaciones y mensajes reales del backend.
//

import SwiftUI

// MARK: - MessagesView

struct MessagesView: View {
    @StateObject private var viewModel = MessagesViewModel()

    var body: some View {
        ZStack {
            Color(.secondarySystemGroupedBackground).ignoresSafeArea()
            Group {
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    ProgressView().tint(.piumsOrange)
                } else if let err = viewModel.errorMessage {
                    errorState(err)
                } else if viewModel.filteredConversations.isEmpty {
                    emptyState
                } else {
                    conversationList
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Buscar conversaciones")
        .onChange(of: viewModel.searchText) { _, text in viewModel.updateSearchText(text) }
        .navigationTitle("Mensajes")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.loadConversations() }
        .toolbarBackground(Color(.secondarySystemGroupedBackground), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - List

    private var conversationList: some View {
        List {
            ForEach(viewModel.filteredConversations) { conv in
                ConversationRow(conversation: conv)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .background(
                        NavigationLink("") {
                            ChatDetailView(conversation: conv, viewModel: viewModel)
                        }
                        .opacity(0)
                    )
            }
            if viewModel.isLoading {
                ProgressView().frame(maxWidth: .infinity).listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await viewModel.loadConversations() }
    }

    // MARK: - Empty / Error

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "message.fill")
                .font(.system(size: 56))
                .foregroundStyle(.secondary.opacity(0.3))
            Text(viewModel.searchText.isEmpty ? "Sin conversaciones" : "Sin resultados")
                .font(.title3.weight(.semibold))
            Text(viewModel.searchText.isEmpty
                 ? "Las conversaciones con tus clientes aparecerán aquí"
                 : "Intenta con otros términos de búsqueda")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(.piumsWarning)
            Text("No se pudieron cargar los mensajes")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Reintentar") {
                Task { await viewModel.loadConversations() }
            }
            .buttonStyle(.borderedProminent)
            .tint(.piumsOrange)
            Spacer()
        }
    }
}

// MARK: - ConversationRow (mismo estilo que cliente)

struct ConversationRow: View {
    let conversation: MessagesViewModel.ConversationItem

    var body: some View {
        HStack(spacing: 12) {
            // Avatar con inicial
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                Text(String(conversation.clientName.prefix(1)).uppercased())
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(statusColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.clientName)
                        .font(.subheadline.bold())
                        .lineLimit(1)
                    Spacer()
                    Text(relativeDate)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                // Badge de estado de la conversación
                Text(statusLabel)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(statusColor.opacity(0.12))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }

            // Badge de no leídos
            if conversation.unreadCount > 0 {
                Text("\(conversation.unreadCount)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(Color.piumsOrange))
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statusColor: Color {
        switch conversation.status.uppercased() {
        case "ACTIVE":  return .piumsOrange
        case "PENDING": return .blue
        case "CLOSED":  return .secondary
        default:        return .piumsOrange
        }
    }

    private var statusLabel: String {
        switch conversation.status.uppercased() {
        case "ACTIVE":  return "Activa"
        case "PENDING": return "Pendiente"
        case "CLOSED":  return "Cerrada"
        default:        return "Activa"
        }
    }

    private var relativeDate: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: conversation.timestamp, relativeTo: Date())
    }
}

// MARK: - ChatDetailView (mismo patrón que cliente)

struct ChatDetailView: View {
    let conversation: MessagesViewModel.ConversationItem
    @ObservedObject var viewModel: MessagesViewModel

    @State private var messages: [MessagesViewModel.MessageItem] = []
    @State private var newMessage = ""
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(messages) { msg in
                            ChatBubbleView(message: msg)
                                .id(msg.id)
                        }
                        Color.clear.frame(height: 8).id("bottom")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .scrollIndicators(.hidden)
                .onChange(of: messages.count) { _, _ in
                    withAnimation { proxy.scrollTo("bottom") }
                }
                .onAppear {
                    proxy.scrollTo("bottom")
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            inputBar
        }
        .navigationTitle(conversation.clientName)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isLoading = true
            messages = await viewModel.loadMessages(for: conversation.conversationId)
            isLoading = false
        }
        .overlay {
            if isLoading {
                ProgressView().tint(.piumsOrange)
            }
        }
    }

    // MARK: Input bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Escribe un mensaje...", text: $newMessage, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button {
                send()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(
                        newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.secondary : Color.piumsOrange
                    )
                    .font(.system(size: 20))
            }
            .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func send() {
        let text = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        newMessage = ""

        // Optimistic append
        let optimistic = MessagesViewModel.MessageItem(
            content: text,
            isFromArtist: true,
            timestamp: Date(),
            isRead: false
        )
        messages.append(optimistic)

        viewModel.sendMessage(text, conversationId: conversation.conversationId)
    }
}

// MARK: - ChatBubbleView (mismo estilo que cliente)

struct ChatBubbleView: View {
    let message: MessagesViewModel.MessageItem

    var body: some View {
        VStack(alignment: message.isFromArtist ? .trailing : .leading, spacing: 2) {
            HStack {
                if message.isFromArtist { Spacer(minLength: 60) }
                Text(message.content)
                    .font(.subheadline)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(message.isFromArtist ? Color.piumsOrange : Color(.secondarySystemBackground))
                    .foregroundStyle(message.isFromArtist ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                if !message.isFromArtist { Spacer(minLength: 60) }
            }
            Text(formattedTime)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
        }
    }

    private var formattedTime: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: message.timestamp)
    }
}
