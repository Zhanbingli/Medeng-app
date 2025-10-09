//
//  AIAssistantView.swift
//  Medeng
//
//  Medical Terminology Learning Assistant
//

import SwiftUI

struct AIAssistantView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @StateObject private var assistant = MedicalAssistant()
    @State private var selectedTerm: MedicalTerm?
    @State private var showingTermPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 欢迎卡片
                    WelcomeCard()
                        .padding(.horizontal)

                    // 快速学习工具
                    QuickToolsSection(
                        onCompare: { showingTermPicker = true },
                        onQuiz: { assistant.generateQuiz(from: vocabularyManager.allTerms) },
                        onBreakdown: { showingTermPicker = true },
                        onPractice: { assistant.generatePractice(from: vocabularyManager.allTerms) }
                    )
                    .padding(.horizontal)

                    // 学习建议
                    if !assistant.suggestions.isEmpty {
                        StudySuggestionsSection(suggestions: assistant.suggestions)
                            .padding(.horizontal)
                    }

                    // 词根词缀库
                    MedicalRootsSection()
                        .padding(.horizontal)

                    // 记忆技巧
                    MemoryTipsSection()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Learning Assistant")
            .background(Color(.systemGroupedBackground))
            .sheet(isPresented: $showingTermPicker) {
                TermPickerView(terms: vocabularyManager.allTerms) { term in
                    selectedTerm = term
                    assistant.analyzeTerm(term)
                }
            }
        }
    }
}

// 医学学习助手
class MedicalAssistant: ObservableObject {
    @Published var suggestions: [String] = []
    @Published var currentQuiz: QuizQuestion?

    init() {
        generateDailySuggestions()
    }

    func generateDailySuggestions() {
        suggestions = [
            "💡 Focus on word roots: 'cardio-' means heart",
            "📚 Review terms you marked as 'Again' yesterday",
            "🎯 Try to master 3 new terms today",
            "⏰ Best time to review: before sleep"
        ]
    }

    func analyzeTerm(_ term: MedicalTerm) {
        // 本地分析术语
        if let etymology = term.etymology {
            suggestions.insert("📖 \(term.term): \(etymology)", at: 0)
        }
    }

    func generateQuiz(from terms: [MedicalTerm]) {
        guard !terms.isEmpty else { return }
        let randomTerms = terms.shuffled().prefix(5)
        suggestions.insert("🎯 Quiz ready! Test yourself on \(randomTerms.count) terms", at: 0)
    }

    func generatePractice(from terms: [MedicalTerm]) {
        let categories = Set(terms.map { $0.category })
        suggestions.insert("📝 Practice available for \(categories.count) categories", at: 0)
    }
}

struct QuizQuestion {
    let term: MedicalTerm
    let options: [String]
    let correctAnswer: String
}

// 欢迎卡片
struct WelcomeCard: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Learning Assistant")
                        .font(.title3)
                        .bold()

                    Text("Your personal medical terminology guide")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Divider()

            HStack(spacing: 20) {
                AssistantFeature(icon: "book.fill", title: "Word Roots", color: .blue)
                AssistantFeature(icon: "brain.head.profile", title: "Memory Tips", color: .purple)
                AssistantFeature(icon: "chart.line.uptrend.xyaxis", title: "Progress", color: .green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct AssistantFeature: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// 快速工具区域
struct QuickToolsSection: View {
    let onCompare: () -> Void
    let onQuiz: () -> Void
    let onBreakdown: () -> Void
    let onPractice: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Tools")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                QuickToolButton(
                    icon: "arrow.left.arrow.right",
                    title: "Compare Terms",
                    subtitle: "Find differences",
                    color: .blue,
                    action: onCompare
                )

                QuickToolButton(
                    icon: "questionmark.circle",
                    title: "Quick Quiz",
                    subtitle: "Test yourself",
                    color: .orange,
                    action: onQuiz
                )

                QuickToolButton(
                    icon: "scissors",
                    title: "Break Down",
                    subtitle: "Word roots",
                    color: .green,
                    action: onBreakdown
                )

                QuickToolButton(
                    icon: "text.bubble",
                    title: "Practice",
                    subtitle: "Conversations",
                    color: .purple,
                    action: onPractice
                )
            }
        }
    }
}

struct QuickToolButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

// 学习建议区域
struct StudySuggestionsSection: View {
    let suggestions: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Study Tips")
                .font(.headline)

            ForEach(suggestions.prefix(4), id: \.self) { suggestion in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.body)

                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
        }
    }
}

// 常用医学词根
struct MedicalRootsSection: View {
    let commonRoots = [
        ("cardio-", "heart", "cardiology, cardiac"),
        ("neuro-", "nerve", "neurology, neuron"),
        ("gastro-", "stomach", "gastritis, gastric"),
        ("derm-", "skin", "dermatology, dermatitis"),
        ("-itis", "inflammation", "arthritis, bronchitis"),
        ("-ology", "study of", "biology, pathology")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Word Roots")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(commonRoots, id: \.0) { root, meaning, examples in
                    MedicalRootRow(root: root, meaning: meaning, examples: examples)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

struct MedicalRootRow: View {
    let root: String
    let meaning: String
    let examples: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(root)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)

                Text("= \(meaning)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()
            }

            Text("Examples: \(examples)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// 记忆技巧
struct MemoryTipsSection: View {
    let tips = [
        ("🧠", "Visualize", "Create mental images for each term"),
        ("🔄", "Spaced Repetition", "Review at increasing intervals"),
        ("📝", "Write It Down", "Physical writing improves memory"),
        ("🗣️", "Say It Aloud", "Pronunciation helps retention")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Memory Techniques")
                .font(.headline)

            VStack(spacing: 8) {
                ForEach(tips, id: \.1) { emoji, title, description in
                    HStack(spacing: 12) {
                        Text(emoji)
                            .font(.title2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
                }
            }
        }
    }
}

// 术语选择器
struct TermPickerView: View {
    let terms: [MedicalTerm]
    let onSelect: (MedicalTerm) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List(terms) { term in
                Button(action: {
                    onSelect(term)
                    dismiss()
                }) {
                    HStack {
                        CategoryIcon(category: term.category)
                            .frame(width: 32, height: 32)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(term.term)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            Text(term.chineseTranslation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Select Term")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AIAssistantView()
        .environmentObject(VocabularyManager.shared)
}
