//
//  AIService.swift
//  Medeng
//
//  真实的AI服务集成
//

import Foundation

enum AIProvider: String, CaseIterable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case qwen = "Qwen"
    case kimi = "Kimi"

    var displayName: String { rawValue }

    var baseURL: String {
        switch self {
        case .openai: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com/v1"
        case .qwen: return "https://dashscope.aliyuncs.com/api/v1"
        case .kimi: return "https://api.moonshot.cn/v1"
        }
    }

    var defaultModel: String {
        switch self {
        case .openai: return "gpt-4o-mini"
        case .anthropic: return "claude-3-5-sonnet-20241022"
        case .qwen: return "qwen-turbo"
        case .kimi: return "moonshot-v1-8k"
        }
    }
}

@MainActor
class AIService: ObservableObject {
    static let shared = AIService()

    @Published var currentProvider: AIProvider
    @Published var apiKey: String
    @Published var isConfigured: Bool = false

    private let secureStorage = SecureStorage()
    private let apiKeyKey = "ai_api_key"
    private let providerKey = "ai_provider"

    init() {
        // Initialize all properties first
        let providerString = UserDefaults.standard.string(forKey: providerKey) ?? AIProvider.openai.rawValue
        self.currentProvider = AIProvider(rawValue: providerString) ?? .openai
        self.apiKey = ""
        self.isConfigured = false

        // Now we can call methods
        migrateAPIKeyToKeychain()

        // Load API key from secure storage
        self.apiKey = (try? secureStorage.load(key: apiKeyKey)) ?? ""
        self.isConfigured = !apiKey.isEmpty
    }

    func saveConfiguration(provider: AIProvider, apiKey: String) {
        self.currentProvider = provider
        self.apiKey = apiKey
        self.isConfigured = !apiKey.isEmpty

        // Save API key securely in Keychain
        try? secureStorage.save(key: apiKeyKey, value: apiKey)

        // Provider is not sensitive, can stay in UserDefaults
        UserDefaults.standard.set(provider.rawValue, forKey: providerKey)
    }

    /// Migrate API key from UserDefaults to Keychain (one-time migration)
    private func migrateAPIKeyToKeychain() {
        // Check if key exists in UserDefaults but not in Keychain
        if let oldKey = UserDefaults.standard.string(forKey: apiKeyKey),
           !oldKey.isEmpty,
           !secureStorage.exists(key: apiKeyKey) {
            // Migrate to Keychain
            try? secureStorage.save(key: apiKeyKey, value: oldKey)
            // Remove from UserDefaults
            UserDefaults.standard.removeObject(forKey: apiKeyKey)
        }
    }

    /// Clear API configuration (useful for logout/reset)
    func clearConfiguration() {
        self.apiKey = ""
        self.isConfigured = false
        try? secureStorage.delete(key: apiKeyKey)
        UserDefaults.standard.removeObject(forKey: providerKey)
    }

    // 分析医学术语
    func analyzeTerm(_ term: MedicalTerm) async throws -> AIAnalysisResult {
        guard isConfigured else {
            throw AIError.notConfigured
        }

        let prompt = """
        Analyze this medical term for a student learning medical English:

        Term: \(term.term)
        Definition: \(term.definition)
        Chinese: \(term.chineseTranslation)

        Provide:
        1. Word breakdown (etymology and roots)
        2. Memory technique (creative and practical)
        3. Clinical usage (real examples)
        4. Common mistakes (what students often confuse)
        5. Related terms and how they differ

        Format as JSON with keys: breakdown, memory_tip, clinical_usage, common_mistakes, related_terms
        """

        // Use protocol-based provider
        let provider = getProvider()
        return try await provider.call(prompt: prompt)
    }

    /// Get the appropriate AI provider based on current selection
    private func getProvider() -> AIProviderProtocol {
        switch currentProvider {
        case .openai:
            return OpenAIProvider(provider: .openai, apiKey: apiKey)
        case .anthropic:
            return AnthropicProvider(provider: .anthropic, apiKey: apiKey)
        case .qwen:
            return QwenProvider(provider: .qwen, apiKey: apiKey)
        case .kimi:
            return KimiProvider(provider: .kimi, apiKey: apiKey)
        }
    }

}

struct AIAnalysisResult {
    let breakdown: String
    let memoryTip: String
    let clinicalUsage: String
    let commonMistakes: String
    let relatedTerms: String
}

enum AIError: Error, LocalizedError {
    case notConfigured
    case networkError(underlying: Error)
    case apiError(statusCode: Int, message: String, provider: AIProvider)
    case parseError(details: String)
    case invalidRequest
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case invalidAPIKey

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI API not configured. Please add your API key in settings."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let statusCode, let message, let provider):
            return "\(provider.displayName) API Error (\(statusCode)): \(message)"
        case .parseError(let details):
            return "Failed to parse AI response: \(details)"
        case .invalidRequest:
            return "Invalid API request"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limit exceeded. Please try again in \(Int(retryAfter)) seconds."
            }
            return "Rate limit exceeded. Please try again later."
        case .invalidAPIKey:
            return "Invalid API key. Please check your settings."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .notConfigured:
            return "Go to Settings and add your AI provider API key."
        case .networkError:
            return "Check your internet connection and try again."
        case .apiError(let statusCode, _, _):
            if statusCode == 401 {
                return "Your API key appears to be invalid. Please check your settings."
            } else if statusCode == 429 {
                return "You've made too many requests. Please wait a moment and try again."
            }
            return "Please try again or contact support if the problem persists."
        case .invalidAPIKey:
            return "Double-check your API key in Settings."
        case .rateLimitExceeded:
            return "Wait a moment before making another request."
        default:
            return nil
        }
    }
}
