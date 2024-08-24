import Foundation
import UIKit
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
        applyTranslations()
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

    private func translateAllTextElements(in view: UIView) {
        for subview in view.subviews {
            translateUIElement(subview)
            translateAllTextElements(in: subview)
        }
    }

    private func translateUIElement(_ element: UIView) {
        if let label = element as? UILabel {
            translateAndApply(label.text ?? "", to: label) { translatedText in
                label.text = translatedText
            }
        } else if let button = element as? UIButton {
            translateAndApply(button.title(for: .normal) ?? "", to: button) { translatedText in
                button.setTitle(translatedText, for: .normal)
            }
        } else if let textField = element as? UITextField {
            translateAndApply(textField.text ?? "", to: textField) { translatedText in
                textField.text = translatedText
            }
        } else if let textView = element as? UITextView {
            translateAndApply(textView.text, to: textView) { translatedText in
                textView.text = translatedText
            }
        }
    }

    private func translateAndApply(_ text: String, to view: UIView, apply: @escaping (String) -> Void) {
        translate(text, to: currentLanguage) { [weak self, weak view] result in
            switch result {
            case .success(let translatedText):
                DispatchQueue.main.async {
                    apply(translatedText)
                    self?.adjustConstraints(for: view!)
                }
            case .failure(let error):
                print("Translation error: \(error)")
            }
        }
    }

    private func adjustConstraints(for view: UIView) {
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func applyTranslations() {
        guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
        translateAllTextElements(in: window)
    }

    public func autoTranslateApp() {
        NotificationCenter.default.addObserver(forName: UIApplication.didFinishLaunchingNotification, object: nil, queue: .main) { [weak self] _ in
            self?.applyTranslations()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.applyTranslations()
        }
    }
}

@available(iOS 14.0, *)
public extension View {
    func autoTranslate() -> some View {
        self.onAppear {
            AutoTranslateSDK.shared.applyTranslations()
        }
    }
}

