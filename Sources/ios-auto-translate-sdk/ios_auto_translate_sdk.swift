import Foundation
import UIKit
import SwiftUI

public class AutoTranslateSDK: ObservableObject {
    public static let shared = AutoTranslateSDK()
    
    @Published private var translations: [String: String] = [:]
    private var apiKey: String = ""
    private var currentLanguage: String = "en"
    
    private init() {}
    
    public func configure(withAPIKey apiKey: String, initialLanguage: String = "en") {
        self.apiKey = apiKey
        self.currentLanguage = initialLanguage
    }
    
    public func setLanguage(_ language: String) {
        currentLanguage = language
        translations.removeAll()
    }
    
    private func translate(_ text: String, to targetLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {

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

struct TranslatableTextModifier: ViewModifier {
    @ObservedObject var sdk = AutoTranslateSDK.shared
    let originalText: String
    
    func body(content: Content) -> some View {
        content
            .transformEffect(.identity) // This triggers a redraw when sdk changes
            .overlay(
                Text(sdk.translate(originalText))
                    .fixedSize(horizontal: false, vertical: true)
                    .allowsHitTesting(false)
            )
            .accessibility(label: Text(sdk.translate(originalText)))
    }
}

extension View {
    func translated(_ text: String) -> some View {
        self.modifier(TranslatableTextModifier(originalText: text))
    }
}

struct AutoTranslateViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .transformEnvironment(\.self) { view in
                view.visitAllViews { subview in
                    if let text = subview as? Text {
                        _ = text.translated(text.verbatim)
                    } else if let textField = subview as? TextField<Text> {
                        _ = textField.translated(textField.title.verbatim)
                    } else if let button = subview as? Button<Text> {
                        _ = button.translated(button.label.verbatim)
                    }
                    // Add more cases for other text-based views as needed
                }
            }
    }
}

extension View {
    func autoTranslate() -> some View {
        self.modifier(AutoTranslateViewModifier())
    }
}

private extension View {
    func visitAllViews(visitor: (Any) -> Void) {
        visitor(self)
        
        if let group = self as? Group<Any> {
            for i in 0..<10 { // SwiftUI's Group can have up to 10 children
                guard let view = group[i] as? View else { break }
                view.visitAllViews(visitor: visitor)
            }
        } else {
            let mirror = Mirror(reflecting: self)
            for child in mirror.children {
                if let view = child.value as? View {
                    view.visitAllViews(visitor: visitor)
                }
            }
        }
    }
}
