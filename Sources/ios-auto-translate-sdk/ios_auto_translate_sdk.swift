import SwiftUI

@available(iOS 14.0, *)
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
            completion(text)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(text)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Translation error: \(error)")
                completion(text)
                return
            }

            guard let data = data else {
                completion(text)
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
                    completion(text)
                }
            } catch {
                print("JSON parsing error: \(error)")
                completion(text)
            }
        }.resume()
    }
}

@available(iOS 14.0, *)
public struct TranslatableText<Content: View>: View {
    @ViewBuilder let content: () -> Content
    @State private var translatedStrings: [String: String] = [:]
    
    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content()
            .modifier(TranslateTextModifier(translatedStrings: $translatedStrings))
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageChanged"))) { _ in
                translatedStrings.removeAll()
            }
    }
}

@available(iOS 14.0, *)
struct TranslateTextModifier: ViewModifier {
    @Binding var translatedStrings: [String: String]
    
    func body(content: Content) -> some View {
        content.transformText { string in
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
}

@available(iOS 14.0, *)
extension View {
    func transformText(_ transform: @escaping (String) -> String) -> some View {
        self.modifier(TransformTextModifier(transform: transform))
    }
}

@available(iOS 14.0, *)
struct TransformTextModifier: ViewModifier {
    let transform: (String) -> String
    
    func body(content: Content) -> some View {
        content.background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: TransformTextPreferenceKey.self,
                    value: [(geo.frame(in: .global), { text in
                        if let textString = (text as? Text)?.verbatim {
                            return transform(textString)
                        }
                        return ""
                    })]
                )
            }
        )
        .overlayPreferenceValue(TransformTextPreferenceKey.self) { preferences in
            ZStack {
                ForEach(Array(preferences.enumerated()), id: \.offset) { _, preference in
                    if let text = findText(in: content) {
                        Text(verbatim: transform(text.verbatim ?? ""))
                            .fixedSize()
                            .frame(width: preference.0.width, height: preference.0.height)
                            .offset(x: preference.0.minX, y: preference.0.minY)
                    }
                }
            }
        }
    }
    
    private func findText(in view: Content) -> Text? {
        let mirror = Mirror(reflecting: view)
        for child in mirror.children {
            if let text = child.value as? Text {
                return text
            }
        }
        return nil
    }
}

@available(iOS 14.0, *)
struct TransformTextPreferenceKey: PreferenceKey {
    static var defaultValue: [(CGRect, (Text) -> String)] = []
    
    static func reduce(value: inout [(CGRect, (Text) -> String)], nextValue: () -> [(CGRect, (Text) -> String)]) {
        value.append(contentsOf: nextValue())
    }
}
