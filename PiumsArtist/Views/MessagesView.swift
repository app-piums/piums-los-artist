//
//  MessagesView.swift
//  PiumsArtist
//
//  Created by piums on 13/04/26.
//

import SwiftUI

struct MessagesView: View {
    @State private var searchText = ""
    
    // Mock messages data
    let mockConversations = [
        Conversation(
            id: 1,
            clientName: "María García",
            clientAvatar: "person.circle.fill",
            lastMessage: "¡Perfecto! Nos vemos mañana a las 10:00",
            timestamp: Date(),
            unreadCount: 0,
            isOnline: true
        ),
        Conversation(
            id: 2,
            clientName: "Ana López",
            clientAvatar: "person.circle.fill",
            lastMessage: "¿Podrías confirmar la cita?",
            timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
            unreadCount: 2,
            isOnline: false
        ),
        Conversation(
            id: 3,
            clientName: "Carlos Ruiz",
            clientAvatar: "person.circle.fill",
            lastMessage: "Gracias por el excelente servicio",
            timestamp: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            unreadCount: 0,
            isOnline: true
        ),
        Conversation(
            id: 4,
            clientName: "Laura Martín",
            clientAvatar: "person.circle.fill",
            lastMessage: "¿Tienes disponibilidad para el viernes?",
            timestamp: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            unreadCount: 1,
            isOnline: false
        )
    ]
    
    var filteredConversations: [Conversation] {
        if searchText.isEmpty {
            return mockConversations
        } else {
            return mockConversations.filter { conversation in
                conversation.clientName.localizedCaseInsensitiveContains(searchText) ||
                conversation.lastMessage.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Buscar conversaciones...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Conversations list
                if filteredConversations.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "message")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text(searchText.isEmpty ? "No hay conversaciones" : "No se encontraron conversaciones")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text(searchText.isEmpty ? "Las conversaciones con tus clientes aparecerán aquí" : "Intenta con otros términos de búsqueda")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredConversations) { conversation in
                            NavigationLink(destination: ChatDetailView(conversation: conversation)) {
                                ConversationRow(conversation: conversation)
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Mensajes")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct Conversation: Identifiable {
    let id: Int
    let clientName: String
    let clientAvatar: String
    let lastMessage: String
    let timestamp: Date
    let unreadCount: Int
    let isOnline: Bool
}

struct ConversationRow: View {
    let conversation: Conversation
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(conversation.timestamp) {
            formatter.dateFormat = "HH:mm"
        } else if Calendar.current.isDate(conversation.timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEE"
        } else {
            formatter.dateFormat = "dd/MM"
        }
        
        return formatter
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with online indicator
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: conversation.clientAvatar)
                            .foregroundColor(.blue)
                            .font(.title3)
                    )
                
                if conversation.isOnline {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .offset(x: 18, y: 18)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .frame(width: 12, height: 12)
                        )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.clientName)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(timeFormatter.string(from: conversation.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

struct ChatDetailView: View {
    let conversation: Conversation
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    
    var body: some View {
        VStack {
            // Messages list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Message input
            HStack {
                TextField("Escribir mensaje...", text: $messageText, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...4)
                
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .frame(width: 35, height: 35)
                        .background(messageText.isEmpty ? Color.gray : Color.blue)
                        .cornerRadius(17.5)
                }
                .disabled(messageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle(conversation.clientName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadMockMessages()
        }
    }
    
    private func loadMockMessages() {
        messages = [
            ChatMessage(id: 1, text: "Hola, ¿tienes disponibilidad para mañana?", isFromClient: true, timestamp: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date()),
            ChatMessage(id: 2, text: "¡Hola! Sí, tengo disponibilidad. ¿A qué hora te vendría bien?", isFromClient: false, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()),
            ChatMessage(id: 3, text: "¿Podrías a las 10:00 AM?", isFromClient: true, timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()),
            ChatMessage(id: 4, text: "Perfecto, te confirmo la cita para mañana a las 10:00 AM", isFromClient: false, timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date()) ?? Date())
        ]
    }
    
    private func sendMessage() {
        let newMessage = ChatMessage(
            id: messages.count + 1,
            text: messageText,
            isFromClient: false,
            timestamp: Date()
        )
        
        withAnimation {
            messages.append(newMessage)
        }
        
        messageText = ""
    }
}

struct ChatMessage: Identifiable {
    let id: Int
    let text: String
    let isFromClient: Bool
    let timestamp: Date
}

struct ChatBubble: View {
    let message: ChatMessage
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }
    
    var body: some View {
        HStack {
            if !message.isFromClient {
                Spacer()
            }
            
            VStack(alignment: message.isFromClient ? .leading : .trailing, spacing: 4) {
                Text(message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(message.isFromClient ? Color(.systemGray5) : Color.blue)
                    .foregroundColor(message.isFromClient ? .primary : .white)
                    .cornerRadius(18)
                
                Text(timeFormatter.string(from: message.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: 250, alignment: message.isFromClient ? .leading : .trailing)
            
            if message.isFromClient {
                Spacer()
            }
        }
    }
}

#Preview {
    MessagesView()
}