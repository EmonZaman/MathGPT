//
//  HoomePage.swift
//  MathGPT
//
//  Created by Aagontuk on 7/4/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct HomeView: View {
    struct ChatMessage: Identifiable, Hashable {
        enum Sender {
            case user
            case assistant
        }
        let id: UUID = UUID()
        let sender: Sender
        let text: String?
        let showsImageCard: Bool
        let isVoice: Bool

        init(sender: Sender, text: String?, showsImageCard: Bool, isVoice: Bool = false) {
            self.sender = sender
            self.text = text
            self.showsImageCard = showsImageCard
            self.isVoice = isVoice
        }
    }

    @State private var composedMessageText: String = ""
    @State private var messages: [ChatMessage] = [
        .init(sender: .user, text: "Hello ! there", showsImageCard: false),
        .init(sender: .assistant, text: "Hello there! How may I assist you today?", showsImageCard: false),
        .init(sender: .user, text: "I want to learn how to solve a cubic equation? 1. Linear Equations:\n\n• Solve for x: 3x + 5 = 14\n  • Solution: x = 3\n• Solve for y: 2(y + 3) = 20\n  • Solution: y = 7\n• Solve for x: 4x + 7 = 2x + 12\n  • Solution: x = 2.5", showsImageCard: false),
        .init(sender: .assistant, text: nil, showsImageCard: true)
    ]

    private let fallbackReplies: [String] = [
        "Here’s a random response while the API is being wired up.",
        "Working on it... Here’s a placeholder answer.",
        "This is a simulated reply. The real API response will appear here.",
        "Got it! Responding with a temporary message.",
        "Thanks for your message — here’s a random placeholder.",
        "I’m a stub right now. Real answers coming soon.",
        "Placeholder reply: your request has been received.",
        "Simulated: I understand. Here’s something for now.",
        "Here’s a random message — API integration pending.",
        "Acknowledged. Returning a mock response."
    ]

    @State private var isShowingFileImporter: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(messages) { message in
                                    if message.showsImageCard {
                                        ImageCard()
                                            .padding(.horizontal)
                                    } else {
                                        ChatBubble(
                                            text: message.text ?? (message.isVoice ? "Voice message" : ""),
                                            isFromUser: message.sender == .user,
                                            isVoice: message.isVoice,
                                            showsActions: message.sender == .assistant,
                                            onCopy: { handleToolbarCopy(for: message) },
                                            onLike: { handleToolbarLike(for: message) },
                                            onDislike: { handleToolbarDislike(for: message) },
                                            onReload: { handleToolbarReload(for: message) },
                                            onShare: { handleToolbarShare(for: message) },
                                            onPlay: { handlePlay(for: message) }
                                        )
                                        .padding(.horizontal)
                                    }
                                }
                                Spacer(minLength: 8)
                            }
                            .padding(.top, 8)
                        }
                        .onAppear {
                            if let lastId = messages.last?.id {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                        .onChange(of: messages.count) { _ in
                            if let lastId = messages.last?.id {
                                withAnimation(.easeOut(duration: 0.25)) {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                    }

                    Divider()

                    InputBar(text: $composedMessageText, onSend: handleSendTapped, onMic: handleMicTapped, onAttach: handleAttachTapped)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                }
            }
            .navigationBarTitle("RESULT", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: handleBackTapped) {
                        Image(systemName: "chevron.left")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleShareTapped) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .fileImporter(isPresented: $isShowingFileImporter, allowedContentTypes: [UTType.item], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    handleFilePicked(url)
                }
            case .failure:
                messages.append(.init(sender: .assistant, text: "File import canceled or failed.", showsImageCard: false))
            }
        }
    }

    private func handleBackTapped() {}
    private func handleShareTapped() {}

    private func handleAttachTapped() {
        isShowingFileImporter = true
    }

    private func handleFilePicked(_ url: URL) {
        let filename = url.lastPathComponent
        messages.append(.init(sender: .user, text: "Uploaded file: \(filename)", showsImageCard: false))
        simulateAssistantResponse(to: "[file] \(filename)")
    }

    private func handleMicTapped() {
        messages.append(.init(sender: .assistant, text: "Listening...", showsImageCard: false))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            messages.append(.init(sender: .user, text: "Voice message", showsImageCard: false, isVoice: true))
            simulateAssistantResponse(to: "[voice]")
        }
    }

    private func handleSendTapped() {
        let trimmed = composedMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        messages.append(.init(sender: .user, text: trimmed, showsImageCard: false))
        let userMessage = trimmed
        composedMessageText = ""

        simulateAssistantResponse(to: userMessage)
    }

    private func simulateAssistantResponse(to userMessage: String) {
        // API integration point:
        // Replace the simulated delay and random reply below with your real API call.
        // Example:
        // callYourAPI(with: userMessage) { resultText in
        //     DispatchQueue.main.async {
        //         self.messages.append(.init(sender: .assistant, text: resultText, showsImageCard: false))
        //     }
        // }

        let randomDelay = Double.random(in: 0.6...1.4)
        let replyText = fallbackReplies.randomElement() ?? "Okay."
        DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay) {
            self.messages.append(.init(sender: .assistant, text: replyText, showsImageCard: false))
        }
    }

    private func handleToolbarCopy(for message: ChatMessage) {
        messages.append(.init(sender: .assistant, text: "Copy button is pressed", showsImageCard: false))
    }
    private func handleToolbarLike(for message: ChatMessage) {
        messages.append(.init(sender: .assistant, text: "Like button is pressed", showsImageCard: false))
    }
    private func handleToolbarDislike(for message: ChatMessage) {
        messages.append(.init(sender: .assistant, text: "Dislike button is pressed", showsImageCard: false))
    }
    private func handleToolbarReload(for message: ChatMessage) {
        messages.append(.init(sender: .assistant, text: "Reload button is pressed", showsImageCard: false))
    }
    private func handleToolbarShare(for message: ChatMessage) {
        messages.append(.init(sender: .assistant, text: "Share button is pressed", showsImageCard: false))
    }

    private func handlePlay(for message: ChatMessage) {
        messages.append(.init(sender: .assistant, text: "Playing voice...", showsImageCard: false))
    }
}

// MARK: - Subviews

struct ChatBubble: View {
    let text: String
    let isFromUser: Bool
    let isVoice: Bool
    var showsActions: Bool = false
    var onCopy: (() -> Void)? = nil
    var onLike: (() -> Void)? = nil
    var onDislike: (() -> Void)? = nil
    var onReload: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil
    var onPlay: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: isFromUser ? .trailing : .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                if isFromUser == false {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                }

                if isVoice {
                    HStack(spacing: 10) {
                        Button(action: { onPlay?() }) {
                            Image(systemName: "play.fill")
                                .foregroundStyle(isFromUser ? .white : .accentColor)
                        }
                        Text("Voice message")
                            .font(.body)
                            .foregroundColor(isFromUser ? .white : .primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(isFromUser ? Color.accentColor : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .frame(maxWidth: .infinity, alignment: isFromUser ? .trailing : .leading)
                } else {
                    Text(text)
                        .font(.body)
                        .foregroundColor(isFromUser ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(isFromUser ? Color.accentColor : Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .frame(maxWidth: .infinity, alignment: isFromUser ? .trailing : .leading)
                }

                if isFromUser {
                    Spacer(minLength: 0)
                        .frame(width: 28)
                }
            }
            .frame(maxWidth: .infinity, alignment: isFromUser ? .trailing : .leading)

            if showsActions {
                HStack(spacing: 16) {
                    Button(action: { onCopy?() }) { Image(systemName: "doc.on.doc") }
                    Button(action: { onLike?() }) { Image(systemName: "hand.thumbsup") }
                    Button(action: { onDislike?() }) { Image(systemName: "hand.thumbsdown") }
                    Button(action: { onReload?() }) { Image(systemName: "arrow.clockwise") }
                    Button(action: { onShare?() }) { Image(systemName: "square.and.arrow.up") }
                }
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.horizontal, isFromUser ? 0 : 36)
            }
        }
    }
}

struct ImageCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .overlay(
                    Image(systemName: "doc.text.image")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .foregroundColor(.secondary)
                )

            HStack(spacing: 8) {
                Image(systemName: "camera.viewfinder")
                Text("Math Scan")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.75))
            .clipShape(Capsule())
            .padding(12)
        }
    }
}

struct InputBar: View {
    @Binding var text: String
    var onSend: () -> Void
    var onMic: () -> Void
    var onAttach: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField("How can I help?", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button(action: onMic) {
                Image(systemName: "mic.fill")
                    .padding(8)
            }

                        Button(action: onAttach) {
                Image(systemName: "plus.circle")
                    .padding(8)
            }
            .buttonStyle(.borderedProminent)
 
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
                    .padding(8)
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    HomeView()
}
