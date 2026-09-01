import SwiftUI

public struct AIChatMessage: Identifiable, Sendable {
    public let id = UUID()
    public let sender: String // "user" | "ai"
    public let text: String
    public let suggestions: [String]
}

public struct AIChatView: View {
    @State private var messages: [AIChatMessage] = [
        AIChatMessage(
            sender: "ai",
            text: "Merhaba! Ben Sobo AI Asistanınız. 🧘‍♀️ Sobo Society derslerimiz (Barre, Reformer, Functional), canlı program veya paketlerimiz hakkında sorularınızı yanıtlayabilirim.",
            suggestions: ["Barre nedir?", "Yarınki dersler", "Stüdyo nerede?", "Paket fiyatları"]
        )
    ]
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Top Bar Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sobo AI Asistan")
                        .font(.custom("CormorantGaramond-Regular", size: 22))
                        .foregroundColor(SoboTheme.ink)
                    Text("Barre, Pilates & Stüdyo Danışmanı")
                        .font(.system(size: 11))
                        .foregroundColor(SoboTheme.secondary)
                }
                Spacer()
            }
            .padding()
            .background(SoboTheme.sand.opacity(0.5))

            // Chat Messages History
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(messages) { msg in
                            HStack {
                                if msg.sender == "user" { Spacer() }
                                VStack(alignment: msg.sender == "user" ? .trailing : .leading, spacing: 6) {
                                    Text(msg.text)
                                        .font(.system(size: 13))
                                        .foregroundColor(msg.sender == "user" ? .white : SoboTheme.ink)
                                        .padding(12)
                                        .background(msg.sender == "user" ? SoboTheme.espresso : Color.white)
                                        .cornerRadius(14)
                                        .shadow(color: Color.black.opacity(0.04), radius: 4)

                                    if !msg.suggestions.isEmpty {
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 6) {
                                                ForEach(msg.suggestions, id: \.self) { chip in
                                                    Button(action: { sendMessage(queryText: chip) }) {
                                                        Text(chip)
                                                            .font(.system(size: 11, weight: .medium))
                                                            .foregroundColor(SoboTheme.secondary)
                                                            .padding(.horizontal, 10)
                                                            .padding(.vertical, 6)
                                                            .background(SoboTheme.sand)
                                                            .cornerRadius(12)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                if msg.sender == "ai" { Spacer() }
                            }
                        }
                    }
                    .padding()
                }
            }

            // Input Bar
            HStack(spacing: 8) {
                TextField("Bir soru sorun...", text: $inputText)
                    .font(.system(size: 13))
                    .padding(10)
                    .background(Color.white)
                    .cornerRadius(10)

                Button(action: { sendMessage() }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(SoboTheme.espresso)
                        .cornerRadius(10)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
            }
            .padding(10)
            .background(SoboTheme.sand.opacity(0.4))
        }
        .background(SoboTheme.ivory.ignoresSafeArea())
    }

    private func sendMessage(queryText: String? = nil) {
        let query = (queryText ?? inputText).trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        let userMsg = AIChatMessage(sender: "user", text: query, suggestions: [])
        messages.append(userMsg)
        if queryText == nil { inputText = "" }
        isLoading = true

        Task {
            struct AIChatReq: Encodable { let mesaj: String }
            struct AIChatRes: Decodable { let yanit: String; let oneri_sorular: [String] }

            do {
                let reqData = try JSONEncoder().encode(AIChatReq(mesaj: query))
                let res: AIChatRes = try await APIClient.shared.request(endpoint: "/ai/chat", method: "POST", body: reqData)

                await MainActor.run {
                    messages.append(AIChatMessage(sender: "ai", text: res.yanit, suggestions: res.oneri_sorular))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(AIChatMessage(sender: "ai", text: "Şu an yanıt verilemiyor. Lütfen tekrar deneyin.", suggestions: []))
                    isLoading = false
                }
            }
        }
    }
}
