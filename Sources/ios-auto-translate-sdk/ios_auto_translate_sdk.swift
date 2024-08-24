import SwiftUI

public class AutoTranslateSDK {
    public static let shared = AutoTranslateSDK()
    
    private var apiKey: String = ""
    private let supportedLanguages = ["es", "fr", "de", "it", "pt", "nl", "ru", "ja", "ko", "zh"]
    private var translations: [String: String] = [:]
    private var currentLanguage: String = "en"

    private init() {}

    public func configure(withAPIKey apiKey: String, initialLanguage: String = "en") {
        self.apiKey = apiKey
        setLanguage(initialLanguage)
    }

    public func setLanguage(_ language: String) {
        guard supportedLanguages.contains(language) else {
            print("Unsupported language: \(language)")
            return
        }
        currentLanguage = language
        NotificationCenter.default.post(name: Notification.Name("LanguageChanged"), object: nil)
    }

    public func translate(_ text: String, to targetLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        if let cachedTranslation = translations["\(targetLanguage):\(text)"] {
            completion(.success(cachedTranslation))
            return
        }

        let prompt = "Translate the following text to \(targetLanguage): \(text)"
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that translates text."],
                ["role": "user", "content": prompt]
            ]
        ]

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(NSError(domain: "InvalidURL", code: 0, userInfo: nil)))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: "NoData", code: 0, userInfo: nil)))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let translatedText = message["content"] as? String {
                    self.translations["\(targetLanguage):\(text)"] = translatedText
                    completion(.success(translatedText))
                } else {
                    completion(.failure(NSError(domain: "InvalidResponse", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

public struct TranslatableText: View {
    @State private var translatedText: String
    private let originalText: String

    public init(_ text: String) {
        self.originalText = text
        self._translatedText = State(initialValue: text)
    }

    public var body: some View {
        Text(translatedText)
            .onAppear(perform: translate)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
                translate()
            }
    }

    private func translate() {
        AutoTranslateSDK.shared.translate(originalText, to: AutoTranslateSDK.shared.currentLanguage) { result in
            switch result {
            case .success(let translated):
                DispatchQueue.main.async {
                    self.translatedText = translated
                }
            case .failure(let error):
                print("Translation error: \(error)")
            }
        }
    }
}
