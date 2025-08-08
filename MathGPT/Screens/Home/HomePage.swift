//
//  HoomePage.swift
//  MathGPT
//
//  Created by Aagontuk on 7/4/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation
import Speech

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
        let audioURL: URL?
        let transcript: String?

        init(sender: Sender, text: String?, showsImageCard: Bool, isVoice: Bool = false, audioURL: URL? = nil, transcript: String? = nil) {
            self.sender = sender
            self.text = text
            self.showsImageCard = showsImageCard
            self.isVoice = isVoice
            self.audioURL = audioURL
            self.transcript = transcript
        }
    }

    @State private var composedMessageText: String = ""
    @State private var messages: [ChatMessage] = []

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

    // Voice recording/playback state
    @State private var isRecording: Bool = false
    @State private var audioRecorder: AVAudioRecorder?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var recordingMessageId: UUID?

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView {
                            if messages.isEmpty {
                                EmptyChatView()
                                    .padding(.top, 80)
                            } else {
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
                                                transcript: message.transcript,
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

                    InputBar(
                        text: $composedMessageText,
                        onSend: handleSendTapped,
                        onMic: handleMicTapped,
                        onAttach: handleAttachTapped,
                        micIsRecording: isRecording
                    )
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
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            guard granted else {
                print("Microphone permission denied")
                return
            }
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized, .notDetermined:
                        beginRecordingSession()
                    default:
                        beginRecordingSession() // Proceed without STT if denied
                    }
                }
            }
        }
    }

    private func beginRecordingSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)

            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("voice_\(UUID().uuidString).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()
            isRecording = true

            // Show a temporary user-side listening message
            let listeningMessage = ChatMessage(sender: .user, text: "Listening…", showsImageCard: false)
            messages.append(listeningMessage)
            recordingMessageId = listeningMessage.id
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        let recordedURL = audioRecorder?.url
        audioRecorder = nil
        isRecording = false

        guard let url = recordedURL else { return }

        // Replace the temporary "Listening…" message with a voice bubble
        if let id = recordingMessageId, let index = messages.firstIndex(where: { $0.id == id }) {
            let voiceMessage = ChatMessage(sender: .user, text: nil, showsImageCard: false, isVoice: true, audioURL: url, transcript: nil)
            messages[index] = voiceMessage
            recordingMessageId = nil
        } else {
            messages.append(.init(sender: .user, text: nil, showsImageCard: false, isVoice: true, audioURL: url))
        }

        // Try to transcribe; update the message when available
        transcribeAudio(at: url)

        // Simulate assistant response to voice
        simulateAssistantResponse(to: "[voice]")
    }

    private func transcribeAudio(at url: URL) {
        let recognizer = SFSpeechRecognizer()
        guard recognizer?.isAvailable == true else { return }
        let request = SFSpeechURLRecognitionRequest(url: url)
        recognizer?.recognitionTask(with: request) { result, error in
            if let transcript = result?.bestTranscription.formattedString, result?.isFinal == true {
                if let index = messages.lastIndex(where: { $0.isVoice && $0.audioURL == url && $0.sender == .user }) {
                    let old = messages[index]
                    messages[index] = ChatMessage(sender: old.sender, text: transcript, showsImageCard: old.showsImageCard, isVoice: true, audioURL: old.audioURL, transcript: transcript)
                }
            } else if let error = error {
                print("Transcription error: \(error)")
            }
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
        print("Copy button pressed for message id: \(message.id)")
    }
    private func handleToolbarLike(for message: ChatMessage) {
        print("Like button pressed for message id: \(message.id)")
    }
    private func handleToolbarDislike(for message: ChatMessage) {
        print("Dislike button pressed for message id: \(message.id)")
    }
    private func handleToolbarReload(for message: ChatMessage) {
        print("Reload button pressed for message id: \(message.id)")
    }
    private func handleToolbarShare(for message: ChatMessage) {
        print("Share button pressed for message id: \(message.id)")
    }

    private func handlePlay(for message: ChatMessage) {
        guard let url = message.audioURL else {
            print("No audio URL to play")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Audio play failed: \(error)")
        }
    }
}

// MARK: - Subviews

struct ChatBubble: View {
    let text: String
    let isFromUser: Bool
    let isVoice: Bool
    let transcript: String?
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
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 10) {
                            Button(action: { onPlay?() }) {
                                Image(systemName: "play.fill")
                                    .foregroundStyle(isFromUser ? .white : .accentColor)
                            }
                            Text("Voice message")
                                .font(.body)
                                .foregroundColor(isFromUser ? .white : .primary)
                        }
                        if let transcript, transcript.isEmpty == false {
                            Text(transcript)
                                .font(.caption)
                                .foregroundColor(isFromUser ? .white.opacity(0.9) : .secondary)
                        }
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

struct EmptyChatView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "message")
                .font(.system(size: 48, weight: .regular))
                .foregroundColor(.secondary)
            Text("Your chat is empty")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Start a conversation by typing a message or using the mic.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
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
    var micIsRecording: Bool

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onAttach) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .padding(4)
            }

            TextField("How can I help?", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)

            Button(action: onMic) {
                Image(systemName: micIsRecording ? "stop.circle.fill" : "mic.fill")
                    .foregroundColor(micIsRecording ? .red : .accentColor)
                    .padding(8)
            }

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
