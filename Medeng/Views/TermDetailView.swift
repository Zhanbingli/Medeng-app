//
//  TermDetailView.swift
//  Medeng
//
//  Created by Medical English Learning App
//

import SwiftUI

struct TermDetailView: View {
    let term: MedicalTerm
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @Environment(\.dismiss) var dismiss
    @State private var showingAIInsights = false

    var progress: StudyProgress {
        vocabularyManager.getProgress(for: term)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 标题和发音
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(term.term)
                                .font(.largeTitle)
                                .bold()

                            Spacer()

                            Button(action: {
                                vocabularyManager.toggleFavorite(for: term)
                            }) {
                                Image(systemName: progress.isFavorite ? "star.fill" : "star")
                                    .foregroundColor(progress.isFavorite ? .yellow : .gray)
                                    .font(.title2)
                            }
                        }

                        Text(term.pronunciation)
                            .font(.title3)
                            .foregroundColor(.secondary)

                        Text(term.chineseTranslation)
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    // AI智能分析按钮
                    Button(action: { showingAIInsights.toggle() }) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("AI Insights")
                                    .font(.headline)
                                Text("Get smart breakdown and tips")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()

                    // 定义
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Definition", systemImage: "text.book.closed.fill")
                            .font(.headline)
                            .foregroundColor(.blue)

                        Text(term.definition)
                            .font(.body)
                    }

                    // 词源
                    if let etymology = term.etymology {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Etymology", systemImage: "tree.fill")
                                .font(.headline)
                                .foregroundColor(.green)

                            Text(etymology)
                                .font(.body)
                        }
                    }

                    // 例句
                    if let example = term.example {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Example", systemImage: "quote.bubble.fill")
                                .font(.headline)
                                .foregroundColor(.orange)

                            Text(example)
                                .font(.body)
                                .italic()
                        }
                    }

                    // 相关术语
                    if !term.relatedTerms.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Label("Related Terms", systemImage: "link")
                                .font(.headline)
                                .foregroundColor(.purple)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(term.relatedTerms, id: \.self) { relatedTerm in
                                        Text(relatedTerm)
                                            .font(.subheadline)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.purple.opacity(0.2))
                                            .foregroundColor(.purple)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }

                    // 分类信息
                    Divider()

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Category")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack {
                                CategoryIcon(category: term.category)
                                    .frame(width: 24, height: 24)
                                Text(term.category.rawValue)
                                    .font(.subheadline)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Difficulty")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            DifficultyBadge(difficulty: term.difficulty)
                        }
                    }

                    // 学习统计
                    if progress.reviewCount > 0 {
                        Divider()

                        VStack(alignment: .leading, spacing: 12) {
                            Label("Study Statistics", systemImage: "chart.bar.fill")
                                .font(.headline)
                                .foregroundColor(.blue)

                            HStack(spacing: 20) {
                                StatBox(title: "Reviews", value: "\(progress.reviewCount)", color: .blue)
                                StatBox(title: "Accuracy", value: "\(Int(progress.accuracy * 100))%", color: .green)
                                StatBox(title: "Mastery", value: "\(progress.masteryLevel)/5", color: .orange)
                            }

                            if progress.nextReviewDate > Date() {
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.secondary)
                                    Text("Next review: \(progress.nextReviewDate, style: .date)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundColor(.orange)
                                    Text("Due for review")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAIInsights) {
                AIInsightsView(term: term)
            }
        }
    }
}

// AI智能分析视图
struct AIInsightsView: View {
    let term: MedicalTerm
    @Environment(\.dismiss) var dismiss
    @StateObject private var aiService = AIService.shared
    @State private var insights: [AIInsight] = []
    @State private var isAnalyzing = true
    @State private var errorMessage: String?
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 错误提示
                    if let error = errorMessage {
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)

                            Text(error)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)

                            Button(action: { showingSettings = true }) {
                                Text("Configure AI")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }

                            Button(action: analyzeTermWithAI) {
                                Text("Retry")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                    // 分析加载
                    else if isAnalyzing {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("AI is analyzing \"\(term.term)\"...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Using \(aiService.currentProvider.displayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    }
                    // 分析结果
                    else {
                        ForEach(insights) { insight in
                            InsightCard(insight: insight)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("AI Insights")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                AISettingsView()
            }
        }
        .onAppear {
            analyzeTermWithAI()
        }
    }

    func analyzeTermWithAI() {
        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                let result = try await aiService.analyzeTerm(term)
                await MainActor.run {
                    insights = convertToInsights(result)
                    isAnalyzing = false
                }
            } catch let error as AIError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Unknown error occurred: \(error.localizedDescription)"
                    isAnalyzing = false
                }
            }
        }
    }

    func convertToInsights(_ result: AIAnalysisResult) -> [AIInsight] {
        var insights: [AIInsight] = []

        if !result.breakdown.isEmpty {
            insights.append(AIInsight(
                id: UUID(),
                icon: "tree.fill",
                title: "Word Breakdown",
                content: result.breakdown,
                color: .green
            ))
        }

        if !result.memoryTip.isEmpty {
            insights.append(AIInsight(
                id: UUID(),
                icon: "brain.head.profile",
                title: "Memory Technique",
                content: result.memoryTip,
                color: .purple
            ))
        }

        if !result.clinicalUsage.isEmpty {
            insights.append(AIInsight(
                id: UUID(),
                icon: "stethoscope",
                title: "Clinical Usage",
                content: result.clinicalUsage,
                color: .blue
            ))
        }

        if !result.commonMistakes.isEmpty {
            insights.append(AIInsight(
                id: UUID(),
                icon: "exclamationmark.triangle",
                title: "Common Mistakes",
                content: result.commonMistakes,
                color: .orange
            ))
        }

        if !result.relatedTerms.isEmpty {
            insights.append(AIInsight(
                id: UUID(),
                icon: "link",
                title: "Related Terms",
                content: result.relatedTerms,
                color: .indigo
            ))
        }

        return insights
    }

}

struct AIInsight: Identifiable {
    let id: UUID
    let icon: String
    let title: String
    let content: String
    let color: Color
}

struct InsightCard: View {
    let insight: AIInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: insight.icon)
                    .font(.title2)
                    .foregroundColor(insight.color)

                Text(insight.title)
                    .font(.headline)

                Spacer()
            }

            Text(insight.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// 统计框
struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .bold()
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

#Preview {
    TermDetailView(term: MedicalTerm(
        term: "Hypertension",
        pronunciation: "/ˌhaɪpərˈtenʃən/",
        definition: "A condition in which the force of the blood against the artery walls is too high.",
        chineseTranslation: "高血压",
        etymology: "hyper- (above) + tension (pressure)",
        example: "The patient was diagnosed with hypertension.",
        category: .cardiology,
        difficulty: .beginner,
        relatedTerms: ["Hypotension", "Blood Pressure"]
    ))
    .environmentObject(VocabularyManager.shared)
}
