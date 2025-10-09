//
//  AISettingsView.swift
//  Medeng
//
//  AI配置界面
//

import SwiftUI

struct AISettingsView: View {
    @StateObject private var aiService = AIService.shared
    @Environment(\.dismiss) var dismiss

    @State private var selectedProvider: AIProvider
    @State private var apiKeyInput: String
    @State private var showingSaveAlert = false

    init() {
        let service = AIService.shared
        _selectedProvider = State(initialValue: service.currentProvider)
        _apiKeyInput = State(initialValue: service.apiKey)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Configure your AI service to get intelligent analysis of medical terms.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Section("AI Provider") {
                    Picker("Select Provider", selection: $selectedProvider) {
                        ForEach(AIProvider.allCases, id: \.self) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Model")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(selectedProvider.defaultModel)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                }

                Section("API Key") {
                    SecureField("Enter API Key", text: $apiKeyInput)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .font(.system(.body, design: .monospaced))

                    Link("Get \(selectedProvider.displayName) API Key",
                         destination: getProviderURL())
                        .font(.caption)
                }

                Section {
                    Button(action: saveConfiguration) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save Configuration")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    .disabled(apiKeyInput.isEmpty)
                }

                Section("How it works") {
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "Word Breakdown",
                        description: "AI analyzes etymology and word roots"
                    )
                    FeatureRow(
                        icon: "lightbulb.fill",
                        title: "Memory Techniques",
                        description: "Get personalized tips for each term"
                    )
                    FeatureRow(
                        icon: "stethoscope",
                        title: "Clinical Context",
                        description: "Real-world medical usage examples"
                    )
                    FeatureRow(
                        icon: "exclamationmark.triangle",
                        title: "Common Mistakes",
                        description: "Learn what students often confuse"
                    )
                }

                if aiService.isConfigured {
                    Section {
                        Button("Test Connection") {
                            // Test API connection
                        }
                        .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("AI Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Configuration Saved", isPresented: $showingSaveAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Your AI service is configured and ready to use!")
            }
        }
    }

    func getProviderURL() -> URL {
        switch selectedProvider {
        case .openai:
            return URL(string: "https://platform.openai.com/api-keys")!
        case .anthropic:
            return URL(string: "https://console.anthropic.com/settings/keys")!
        case .qwen:
            return URL(string: "https://dashscope.console.aliyun.com/apiKey")!
        case .kimi:
            return URL(string: "https://platform.moonshot.cn/console/api-keys")!
        }
    }

    func saveConfiguration() {
        aiService.saveConfiguration(provider: selectedProvider, apiKey: apiKeyInput)
        showingSaveAlert = true
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AISettingsView()
}
