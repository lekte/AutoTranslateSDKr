import Foundation
import UIKit
import SwiftUI
import Combine

// 1. TranslationManager Class
public class TranslationManager: ObservableObject {
    @Published var currentLocale: Locale = Locale(identifier: "en")
    private let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func translate(_ text: String, completion: @escaping (String) -> Void) {
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that translates text."],
                ["role": "user", "content": text]
            ]
        ]
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(text)  // Fallback to the original text if URL fails
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(text)  // Fallback to the original text if serialization fails
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(text)  // Fallback to the original text if the request fails
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let message = choices.first?["message"] as? [String: Any],
                   let translatedText = message["content"] as? String {
                    completion(translatedText.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    completion(text)  // Fallback to the original text if parsing fails
                }
            } catch {
                completion(text)  // Fallback to the original text if JSON decoding fails
            }
        }
        
        task.resume()
    }
}

// 2. Automatic Translation Handling for UIKit Components
public extension TranslationManager {
    
    func translateLabel(_ label: UILabel) {
        guard let text = label.text else { return }
        self.translate(text) { translatedText in
            DispatchQueue.main.async {
                label.text = translatedText
            }
        }
    }
    
    func translateTextField(_ textField: UITextField) {
        guard let text = textField.placeholder else { return }
        self.translate(text) { translatedText in
            DispatchQueue.main.async {
                textField.placeholder = translatedText
            }
        }
    }
    
    func translateTextView(_ textView: UITextView) {
        guard let text = textView.text else { return }
        self.translate(text) { translatedText in
            DispatchQueue.main.async {
                textView.text = translatedText
            }
        }
    }
    
    func translateButton(_ button: UIButton) {
        guard let text = button.title(for: .normal) else { return }
        self.translate(text) { translatedText in
            DispatchQueue.main.async {
                button.setTitle(translatedText, for: .normal)
            }
        }
    }
}
