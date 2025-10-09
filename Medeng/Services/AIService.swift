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

class AIService: ObservableObject {
    static let shared = AIService()

    @Published var currentProvider: AIProvider
    @Published var apiKey: String
    @Published var isConfigured: Bool = false

    private let apiKeyKey = "ai_api_key"
    private let providerKey = "ai_provider"

    init() {
        self.apiKey = UserDefaults.standard.string(forKey: apiKeyKey) ?? ""
        let providerString = UserDefaults.standard.string(forKey: providerKey) ?? AIProvider.openai.rawValue
        self.currentProvider = AIProvider(rawValue: providerString) ?? .openai
        self.isConfigured = !apiKey.isEmpty
    }

    func saveConfiguration(provider: AIProvider, apiKey: String) {
        self.currentProvider = provider
        self.apiKey = apiKey
        self.isConfigured = !apiKey.isEmpty

        UserDefaults.standard.set(apiKey, forKey: apiKeyKey)
        UserDefaults.standard.set(provider.rawValue, forKey: providerKey)
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

        switch currentProvider {
        case .openai:
            return try await callOpenAI(prompt: prompt)
        case .anthropic:
            return try await callAnthropic(prompt: prompt)
        case .qwen:
            return try await callQwen(prompt: prompt)
        case .kimi:
            return try await callKimi(prompt: prompt)
        }
    }

    // OpenAI API
    private func callOpenAI(prompt: String) async throws -> AIAnalysisResult {
        let url = URL(string: "\(currentProvider.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": currentProvider.defaultModel,
            "messages": [
                ["role": "system", "content": "You are a medical education expert helping students learn medical terminology."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("OpenAI Error: \(errorMessage)")
            throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try parseOpenAIResponse(data)
    }

    // Anthropic API
    private func callAnthropic(prompt: String) async throws -> AIAnalysisResult {
        let url = URL(string: "\(currentProvider.baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": currentProvider.defaultModel,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Anthropic Error: \(errorMessage)")
            throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try parseAnthropicResponse(data)
    }

    // Qwen API (阿里云)
    private func callQwen(prompt: String) async throws -> AIAnalysisResult {
        let url = URL(string: "\(currentProvider.baseURL)/services/aigc/text-generation/generation")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": currentProvider.defaultModel,
            "input": ["messages": [["role": "user", "content": prompt]]],
            "parameters": ["result_format": "message"]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Qwen Error: \(errorMessage)")
            throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try parseQwenResponse(data)
    }

    // Kimi API (月之暗面)
    private func callKimi(prompt: String) async throws -> AIAnalysisResult {
        let url = URL(string: "\(currentProvider.baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": currentProvider.defaultModel,
            "messages": [
                ["role": "system", "content": "你是一位医学教育专家，帮助学生学习医学术语。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("Kimi Error: \(errorMessage)")
            throw AIError.apiError(statusCode: httpResponse.statusCode, message: errorMessage)
        }

        return try parseKimiResponse(data)
    }

    // 解析响应
    private func parseOpenAIResponse(_ data: Data) throws -> AIAnalysisResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError
        }

        return try parseAnalysisContent(content)
    }

    private func parseAnthropicResponse(_ data: Data) throws -> AIAnalysisResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIError.parseError
        }

        return try parseAnalysisContent(text)
    }

    private func parseQwenResponse(_ data: Data) throws -> AIAnalysisResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let output = json?["output"] as? [String: Any],
              let message = output["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError
        }

        return try parseAnalysisContent(content)
    }

    private func parseKimiResponse(_ data: Data) throws -> AIAnalysisResult {
        return try parseOpenAIResponse(data) // Kimi uses OpenAI-compatible format
    }

    private func parseAnalysisContent(_ content: String) throws -> AIAnalysisResult {
        // 尝试解析JSON
        guard let jsonData = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] else {
            // 如果不是JSON，返回原始内容
            return AIAnalysisResult(
                breakdown: content,
                memoryTip: "AI returned unstructured response",
                clinicalUsage: "",
                commonMistakes: "",
                relatedTerms: ""
            )
        }

        return AIAnalysisResult(
            breakdown: json["breakdown"] ?? "",
            memoryTip: json["memory_tip"] ?? "",
            clinicalUsage: json["clinical_usage"] ?? "",
            commonMistakes: json["common_mistakes"] ?? "",
            relatedTerms: json["related_terms"] ?? ""
        )
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
    case networkError
    case apiError(statusCode: Int, message: String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "AI API not configured. Please add your API key in settings."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .apiError(let statusCode, let message):
            return "API Error (\(statusCode)): \(message)"
        case .parseError:
            return "Failed to parse AI response."
        }
    }
}
