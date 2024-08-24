import Foundation
import UIKit
import SwiftUI
import Combine

@available(iOS 14.0, *)

public class TranslationManager: ObservableObject {
    @Published var currentLocale: Locale = Locale(identifier: "es")  // Set to Spanish
    private let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func translate(_ text: String, completion: @escaping (String) -> Void) {
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that translates text into Spanish."],
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
    
    // Function to translate all components in the view hierarchy
    public func translateAllTextInViewHierarchy(view: UIView) {
        translateAllLabels(in: view)
        translateAllTextFields(in: view)
        translateAllTextViews(in: view)
        translateAllButtons(in: view)
    }
    
    // Private helper functions
    private func translateAllLabels(in view: UIView) {
        for subview in view.subviews {
            if let label = subview as? UILabel {
                guard let text = label.text else { continue }
                self.translate(text) { translatedText in
                    DispatchQueue.main.async {
                        label.text = translatedText
                    }
                }
            }
            translateAllLabels(in: subview)  // Recursive call for nested subviews
        }
    }
    
    private func translateAllTextFields(in view: UIView) {
        for subview in view.subviews {
            if let textField = subview as? UITextField {
                guard let text = textField.placeholder else { continue }
                self.translate(text) { translatedText in
                    DispatchQueue.main.async {
                        textField.placeholder = translatedText
                    }
                }
            }
            translateAllTextFields(in: subview)  // Recursive call for nested subviews
        }
    }
    
    private func translateAllTextViews(in view: UIView) {
        for subview in view.subviews {
            if let textView = subview as? UITextView {
                guard let text = textView.text else { continue }
                self.translate(text) { translatedText in
                    DispatchQueue.main.async {
                        textView.text = translatedText
                    }
                }
            }
            translateAllTextViews(in: subview)  // Recursive call for nested subviews
        }
    }
    
    private func translateAllButtons(in view: UIView) {
        for subview in view.subviews {
            if let button = subview as? UIButton {
                guard let text = button.title(for: .normal) else { continue }
                self.translate(text) { translatedText in
                    DispatchQueue.main.async {
                        button.setTitle(translatedText, for: .normal)
                    }
                }
            }
            translateAllButtons(in: subview)  // Recursive call for nested subviews
        }
    }
}
