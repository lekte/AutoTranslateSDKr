import SwiftUI

public class AutoTranslateSDK {
    public static let shared = AutoTranslateSDK()
    
    private var apiKey: String = ""
    private let supportedLanguages = ["es", "fr", "de", "it", "pt", "nl", "ru", "ja", "ko", "zh"]
    private var translations: [String: String] = [:]
    public var currentLanguage: String = "en"

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

public func translateText(_ text: String, completion: @escaping (String) -> Void) {
        let prompt = "Translate the following text to \(currentLanguage): \(text)"
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that translates text."],
                ["role": "user", "content": prompt]
            ]
        ]

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(text) // Return original text if URL is invalid
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(text) // Return original text if request encoding fails
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Translation error: \(error)")
                completion(text) // Return original text if there's an error
                return
            }

            guard let data = data else {
                completion(text) // Return original text if no data is received
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let translatedText = message["content"] as? String {
                    DispatchQueue.main.async {
                        completion(translatedText)
                    }
                } else {
                    completion(text) // Return original text if response parsing fails
                }
            } catch {
                print("JSON parsing error: \(error)")
                completion(text) // Return original text if JSON parsing fails
            }
        }.resume()
    }
}


public struct TranslatableText<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var translatedStrings: [String: String] = [:]
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content()
            .transformEnvironment(\.self) { view in
                view.transformText { string in
                    if let translated = translatedStrings[string] {
                        return translated
                    } else {
                        AutoTranslateSDK.shared.translateText(string) { translated in
                            translatedStrings[string] = translated
                        }
                        return string
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
                translatedStrings.removeAll()
            }
    }
}

@available(iOS 14.0, *)


extension View {
    func transformText(_ transform: @escaping (String) -> String) -> some View {
        self.transformEffect(.init(transform))
    }
}

struct TransformTextEffect: ViewModifier {
    let transform: (String) -> String
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: TransformTextPreferenceKey.self,
                    value: [(geo.frame(in: .global), transform)]
                )
            }
        )
        .overlayPreferenceValue(TransformTextPreferenceKey.self) { preferences in
            ZStack {
                ForEach(Array(preferences.enumerated()), id: \.offset) { _, preference in
                    Text(verbatim: transform(preference.1(content)))
                        .fixedSize()
                        .frame(width: preference.0.width, height: preference.0.height)
                        .offset(x: preference.0.minX, y: preference.0.minY)
                }
            }
        }
    }
}

struct TransformTextPreferenceKey: PreferenceKey {
    static var defaultValue: [(CGRect, (Text) -> String)] = []
    
    static func reduce(value: inout [(CGRect, (Text) -> String)], nextValue: () -> [(CGRect, (Text) -> String)]) {
        value.append(contentsOf: nextValue())
    }
}

extension ViewEffect where Self == TransformTextEffect {
    static func `init`(_ transform: @escaping (String) -> String) -> Self {
        TransformTextEffect(transform: transform)
    }
}

