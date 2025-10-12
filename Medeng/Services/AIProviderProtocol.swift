//
//  AIProviderProtocol.swift
//  Medeng
//
//  Protocol-based AI provider abstraction to reduce code duplication
//

import Foundation

/// Protocol for AI provider implementations
protocol AIProviderProtocol {
    var provider: AIProvider { get }
    var apiKey: String { get set }

    /// Make an API call with the given prompt
    func call(prompt: String) async throws -> AIAnalysisResult

    /// Build the request for this provider
    func buildRequest(prompt: String, baseURL: String, model: String) throws -> URLRequest

    /// Parse the response from this provider
    func parseResponse(_ data: Data) throws -> AIAnalysisResult
}

/// Base implementation with common functionality
class BaseAIProvider: AIProviderProtocol {
    let provider: AIProvider
    var apiKey: String

    init(provider: AIProvider, apiKey: String) {
        self.provider = provider
        self.apiKey = apiKey
    }

    func call(prompt: String) async throws -> AIAnalysisResult {
        let request = try buildRequest(
            prompt: prompt,
            baseURL: provider.baseURL,
            model: provider.defaultModel
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError(underlying: URLError(.badServerResponse))
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.apiError(
                statusCode: httpResponse.statusCode,
                message: errorMessage,
                provider: provider
            )
        }

        return try parseResponse(data)
    }

    func buildRequest(prompt: String, baseURL: String, model: String) throws -> URLRequest {
        fatalError("Subclasses must implement buildRequest")
    }

    func parseResponse(_ data: Data) throws -> AIAnalysisResult {
        fatalError("Subclasses must implement parseResponse")
    }

    /// Common JSON parsing helper
    func parseAnalysisContent(_ content: String) throws -> AIAnalysisResult {
        guard let jsonData = content.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: String] else {
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

// MARK: - OpenAI Provider

class OpenAIProvider: BaseAIProvider {
    override func buildRequest(prompt: String, baseURL: String, model: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a medical education expert helping students learn medical terminology."],
                ["role": "user", "content": prompt]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    override func parseResponse(_ data: Data) throws -> AIAnalysisResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError(details: "Invalid OpenAI response format")
        }

        return try parseAnalysisContent(content)
    }
}

// MARK: - Anthropic Provider

class AnthropicProvider: BaseAIProvider {
    override func buildRequest(prompt: String, baseURL: String, model: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/messages") else {
            throw AIError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    override func parseResponse(_ data: Data) throws -> AIAnalysisResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIError.parseError(details: "Invalid Anthropic response format")
        }

        return try parseAnalysisContent(text)
    }
}

// MARK: - Qwen Provider

class QwenProvider: BaseAIProvider {
    override func buildRequest(prompt: String, baseURL: String, model: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/services/aigc/text-generation/generation") else {
            throw AIError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "input": ["messages": [["role": "user", "content": prompt]]],
            "parameters": ["result_format": "message"]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    override func parseResponse(_ data: Data) throws -> AIAnalysisResult {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let output = json?["output"] as? [String: Any],
              let message = output["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.parseError(details: "Invalid Qwen response format")
        }

        return try parseAnalysisContent(content)
    }
}

// MARK: - Kimi Provider

class KimiProvider: OpenAIProvider {
    // Kimi uses OpenAI-compatible format, so we can reuse OpenAI implementation
    override func buildRequest(prompt: String, baseURL: String, model: String) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "你是一位医学教育专家，帮助学生学习医学术语。"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}
