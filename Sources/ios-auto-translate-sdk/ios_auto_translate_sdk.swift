#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation
import UIKit
import ObjectiveC

public class AutoTranslateSDK {
    private let apiKey: String
    private let supportedLanguages = ["es", "fr", "de", "it", "pt", "nl", "ru", "ja", "ko", "zh"]

    public init(apiKey: String) {
        self.apiKey = apiKey
    }

    public func translate(_ text: String, to targetLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard supportedLanguages.contains(targetLanguage) else {
            completion(.failure(TranslationError.unsupportedLanguage))
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
            completion(.failure(TranslationError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(TranslationError.requestEncodingFailed))
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(TranslationError.noDataReceived))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let translatedText = message["content"] as? String {
                    completion(.success(translatedText))
                } else {
                    completion(.failure(TranslationError.invalidResponse))
                }
            } catch {
                completion(.failure(TranslationError.jsonParsingFailed))
            }
        }.resume()
    }

    public func translateAllTextElements(in view: UIView, to targetLanguage: String) {
        for subview in view.subviews {
            if let label = subview as? UILabel {
                self.translate(label.text ?? "", to: targetLanguage) { [weak label] (result: Result<String, Error>) in
                    switch result {
                    case .success(let translatedText):
                        DispatchQueue.main.async {
                            label?.text = translatedText
                            self.adjustConstraints(for: label!)
                        }
                    case .failure(let error):
                        print("Translation error: \(error)")
                    }
                }
            } else if let button = subview as? UIButton {
                self.translate(button.title(for: .normal) ?? "", to: targetLanguage) { [weak button] (result: Result<String, Error>) in
                    switch result {
                    case .success(let translatedText):
                        DispatchQueue.main.async {
                            button?.setTitle(translatedText, for: .normal)
                            self.adjustConstraints(for: button!)
                        }
                    case .failure(let error):
                        print("Translation error: \(error)")
                    }
                }
            } else if let textField = subview as? UITextField {
                self.translate(textField.text ?? "", to: targetLanguage) { [weak textField] (result: Result<String, Error>) in
                    switch result {
                    case .success(let translatedText):
                        DispatchQueue.main.async {
                            textField?.text = translatedText
                            self.adjustConstraints(for: textField!)
                        }
                    case .failure(let error):
                        print("Translation error: \(error)")
                    }
                }
            } else if let textView = subview as? UITextView {
                self.translate(textView.text, to: targetLanguage) { [weak textView] (result: Result<String, Error>) in
                    switch result {
                    case .success(let translatedText):
                        DispatchQueue.main.async {
                            textView?.text = translatedText
                            self.adjustConstraints(for: textView!)
                        }
                    case .failure(let error):
                        print("Translation error: \(error)")
                    }
                }
            }

            translateAllTextElements(in: subview, to: targetLanguage)
        }
    }

    private func translateLabel(_ label: UILabel, to targetLanguage: String) {
        translate(label.text ?? "", to: targetLanguage) { result in
            switch result {
            case .success(let translatedText):
                DispatchQueue.main.async {
                    label.text = translatedText
                    self.adjustConstraints(for: label)
                }
            case .failure(let error):
                print("Translation error: \(error)")
            }
        }
    }

    private func translateButton(_ button: UIButton, to targetLanguage: String) {
        translate(button.title(for: .normal) ?? "", to: targetLanguage) { result in
            switch result {
            case .success(let translatedText):
                DispatchQueue.main.async {
                    button.setTitle(translatedText, for: .normal)
                    self.adjustConstraints(for: button)
                }
            case .failure(let error):
                print("Translation error: \(error)")
            }
        }
    }

    private func translateTextField(_ textField: UITextField, to targetLanguage: String) {
        translate(textField.text ?? "", to: targetLanguage) { result in
            switch result {
            case .success(let translatedText):
                DispatchQueue.main.async {
                    textField.text = translatedText
                    self.adjustConstraints(for: textField)
                }
            case .failure(let error):
                print("Translation error: \(error)")
            }
        }
    }

    private func translateTextView(_ textView: UITextView, to targetLanguage: String) {
        translate(textView.text, to: targetLanguage) { result in
            switch result {
            case .success(let translatedText):
                DispatchQueue.main.async {
                    textView.text = translatedText
                    self.adjustConstraints(for: textView)
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
}

public enum TranslationError: Error {
    case unsupportedLanguage
    case invalidURL
    case requestEncodingFailed
    case noDataReceived
    case invalidResponse
    case jsonParsingFailed
}

extension AutoTranslateSDK {
    private func translateUIElement(_ element: UIView, to targetLanguage: String) {
        if let label = element as? UILabel {
            translate(label.text ?? "", to: targetLanguage) { [weak self, weak label] (result: Result<String, Error>) in
                switch result {
                case .success(let translatedText):
                    DispatchQueue.main.async {
                        label?.text = translatedText
                        self?.adjustConstraints(for: label!)
                    }
                case .failure(let error):
                    print("Translation error: \(error)")
                }
            }
        } else if let button = element as? UIButton {
            translate(button.title(for: .normal) ?? "", to: targetLanguage) { [weak self, weak button] (result: Result<String, Error>) in
                switch result {
                case .success(let translatedText):
                    DispatchQueue.main.async {
                        button?.setTitle(translatedText, for: .normal)
                        self?.adjustConstraints(for: button!)
                    }
                case .failure(let error):
                    print("Translation error: \(error)")
                }
            }
        }
        // Add more UI element types as needed
    }
}
