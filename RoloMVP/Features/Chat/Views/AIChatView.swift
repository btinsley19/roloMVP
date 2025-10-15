//
//  AIChatView.swift
//  RoloMVP
//

import SwiftUI

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if viewModel.isProcessing {
                                HStack {
                                    ProgressView()
                                        .padding(12)
                                        .background(Color.roloSecondaryBackground)
                                        .cornerRadius(16)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $viewModel.inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding(12)
                        .background(Color.roloSecondaryBackground)
                        .cornerRadius(20)
                        .lineLimit(1...5)
                    
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.inputText.isEmpty ? .gray : .roloPrimary)
                    }
                    .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
                }
                .padding()
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
            }
            
            VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .padding(12)
                    .background(message.isFromUser ? Color.roloPrimary : Color.roloSecondaryBackground)
                    .foregroundColor(message.isFromUser ? .white : .primary)
                    .cornerRadius(16)
                
                Text(Formatters.relativeDateFormatter.localizedString(for: message.timestamp, relativeTo: Date()))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isFromUser ? .trailing : .leading)
            
            if !message.isFromUser {
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    AIChatView()
}

