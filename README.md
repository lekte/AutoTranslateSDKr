# AutoTranslateSDK

AutoTranslateSDK is a powerful iOS library that automatically translates your app's text elements into multiple languages using OpenAI's GPT-3.5 model, while maintaining your app's layout.

## Features

- Automatic translation of all text elements in your app
- Minimal integration with just 1-2 lines of code
- Maintains app layout during translation
- Supports translation to 10 languages: Spanish, French, German, Italian, Portuguese, Dutch, Russian, Japanese, Korean, and Chinese
- Uses OpenAI's powerful GPT-3.5 model for high-quality translations
- Asynchronous API with completion handlers for smooth user experience

## Installation

### Swift Package Manager

Add the following line to your `Package.swift` file:

```swift
.package(url: "https://github.com/yourusername/AutoTranslateSDK.git", from: "1.0.0")
```

## Usage

1. Import the SDK in your Swift file:

```swift
import AutoTranslateSDK
```

2. Initialize the SDK with your OpenAI API key and translate all text elements:

```swift
let translator = AutoTranslateSDK(apiKey: "your-openai-api-key")
translator.translateAllTextElements(in: view, to: "es") // Replace 'view' with your root view and 'es' with the target language code
```

The `translateAllTextElements(in:to:)` function automatically identifies and translates all text elements within the specified view hierarchy. It supports UILabel, UIButton, UITextField, and UITextView elements. You can call this function on your root view to translate the entire user interface.

That's it! With just these two lines of code, all text elements in your app will be automatically translated while maintaining the original layout.

## Automatic Translation

The SDK uses advanced techniques to identify and translate all text elements in your app, including:

- UILabel
- UIButton
- UITextField
- UITextView
- Navigation bar titles and buttons
- Tab bar items
- And more...

The translation process happens in the background, ensuring a smooth user experience. The SDK intelligently handles layout constraints to maintain your app's design across different languages:

1. Recursive traversal: The `translateAllTextElements` function recursively traverses the entire view hierarchy of your app.
2. Element identification: It automatically identifies supported UI elements (UILabel, UIButton, UITextField, UITextView).
3. Individual translation: Each text element is translated separately, preserving context and meaning.
4. Layout preservation: After translation, the SDK adjusts constraints and layouts to accommodate the new text length.
5. Asynchronous processing: Translations are performed asynchronously to prevent UI freezing.

This comprehensive approach ensures that your app's entire interface is translated while maintaining its original design and user experience.

## Manual Translation

For more granular control, you can also translate individual strings:

```swift
translator.translate("Hello, world!", to: "es") { result in
    switch result {
    case .success(let translatedText):
        print("Translated text: \(translatedText)")
    case .failure(let error):
        print("Translation error: \(error)")
    }
}
```

## Supported Languages

- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Dutch (nl)
- Russian (ru)
- Japanese (ja)
- Korean (ko)
- Chinese (zh)

## Error Handling

The SDK includes comprehensive error handling. Possible errors are defined in the `TranslationError` enum:

- `unsupportedLanguage`: The target language is not supported
- `invalidURL`: The API endpoint URL is invalid
- `requestEncodingFailed`: Failed to encode the request body
- `noDataReceived`: No data was received from the API
- `invalidResponse`: The API response was invalid or couldn't be parsed
- `jsonParsingFailed`: Failed to parse the JSON response

## OpenAI API Usage

The SDK requires an OpenAI API key to function. Make sure you have signed up for an OpenAI account and obtained an API key. The SDK uses the GPT-3.5 model for translations, which provides high-quality results while being cost-effective.

## Best Practices

- Test your app thoroughly with different languages to ensure proper layout and functionality
- Consider using pseudo-localization during development to catch potential issues early
- Be mindful of API usage and costs, especially for apps with high traffic

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For any questions or issues, please open an issue on the GitHub repository or contact our support team.
