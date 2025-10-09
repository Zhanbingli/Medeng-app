//
//  VocabularyListViewNew.swift
//  Medeng
//
//  现代化重构版本 - 卡片式布局 + 字母索引
//

import SwiftUI

struct VocabularyListView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @State private var showingFilters = false
    @State private var selectedTerm: MedicalTerm?
    @State private var viewMode: ViewMode = .card
    @State private var sortMode: SortMode = .alphabetical

    enum ViewMode {
        case card, list
    }

    enum SortMode: String, CaseIterable {
        case alphabetical = "A-Z"
        case category = "Category"
        case difficulty = "Difficulty"
        case recent = "Recent"
    }

    // 分组后的术语
    var groupedTerms: [(key: String, terms: [MedicalTerm])] {
        let sorted: [MedicalTerm]

        switch sortMode {
        case .alphabetical:
            sorted = vocabularyManager.filteredTerms.sorted { $0.term < $1.term }
        case .category:
            sorted = vocabularyManager.filteredTerms.sorted { $0.category.rawValue < $1.category.rawValue }
        case .difficulty:
            sorted = vocabularyManager.filteredTerms.sorted {
                ($0.difficulty.rawValue, $0.term) < ($1.difficulty.rawValue, $1.term)
            }
        case .recent:
            sorted = vocabularyManager.filteredTerms.sorted { term1, term2 in
                let date1 = vocabularyManager.progressMap[term1.id]?.lastReviewDate ?? Date.distantPast
                let date2 = vocabularyManager.progressMap[term2.id]?.lastReviewDate ?? Date.distantPast
                return date1 > date2
            }
        }

        let grouped: [String: [MedicalTerm]]
        switch sortMode {
        case .alphabetical:
            grouped = Dictionary(grouping: sorted) { String($0.term.prefix(1)) }
        case .category:
            grouped = Dictionary(grouping: sorted) { $0.category.rawValue }
        case .difficulty:
            grouped = Dictionary(grouping: sorted) { $0.difficulty.rawValue }
        case .recent:
            grouped = ["Recent": sorted]
        }

        return grouped.sorted { $0.key < $1.key }.map { (key: $0.key, terms: $0.value) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索栏
                ModernSearchBar(text: $vocabularyManager.searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // 工具栏
                HStack(spacing: 12) {
                    // 排序模式
                    Menu {
                        ForEach(SortMode.allCases, id: \.self) { mode in
                            Button(action: { sortMode = mode }) {
                                Label(mode.rawValue, systemImage: sortMode == mode ? "checkmark" : "")
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                            Text(sortMode.rawValue)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    // 过滤器
                    ModernFilterButton(
                        hasActiveFilters: vocabularyManager.selectedCategory != nil || vocabularyManager.selectedDifficulty != nil
                    ) {
                        showingFilters = true
                    }

                    Spacer()

                    // 视图切换
                    Button(action: { viewMode = viewMode == .card ? .list : .card }) {
                        Image(systemName: viewMode == .card ? "list.bullet" : "square.grid.2x2")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // 术语列表
                if vocabularyManager.filteredTerms.isEmpty {
                    EmptyStateView()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                                ForEach(groupedTerms, id: \.key) { section in
                                    Section {
                                        if viewMode == .card {
                                            LazyVStack(spacing: 12) {
                                                ForEach(section.terms) { term in
                                                    ModernVocabularyCard(term: term)
                                                        .onTapGesture {
                                                            selectedTerm = term
                                                        }
                                                }
                                            }
                                            .padding(.horizontal)
                                        } else {
                                            LazyVStack(spacing: 0) {
                                                ForEach(section.terms) { term in
                                                    ModernVocabularyRow(term: term)
                                                        .onTapGesture {
                                                            selectedTerm = term
                                                        }
                                                }
                                            }
                                        }
                                    } header: {
                                        SectionHeader(title: section.key)
                                    }
                                }
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Medical Vocabulary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Text("\(vocabularyManager.filteredTerms.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                FilterView()
            }
            .sheet(item: $selectedTerm) { term in
                TermDetailView(term: term)
            }
        }
    }
}

// 现代化搜索栏
struct ModernSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(isFocused ? .blue : .secondary)
                    .font(.body)

                TextField("Search medical terms...", text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .focused($isFocused)

                if !text.isEmpty {
                    Button(action: {
                        text = ""
                        isFocused = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.blue : Color.clear, lineWidth: 2)
            )
            .shadow(color: isFocused ? .blue.opacity(0.1) : .clear, radius: 8)
        }
        .animation(.spring(response: 0.3), value: isFocused)
    }
}

// 现代化过滤器按钮
struct ModernFilterButton: View {
    let hasActiveFilters: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.body)
                if hasActiveFilters {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
            }
            .foregroundColor(hasActiveFilters ? .blue : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(hasActiveFilters ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

// 分组标题
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground).opacity(0.95))
    }
}

// 现代化卡片视图
struct ModernVocabularyCard: View {
    let term: MedicalTerm
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @State private var isPressed = false

    var progress: StudyProgress {
        vocabularyManager.getProgress(for: term)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // 类别图标 - 更大更醒目
                CategoryIcon(category: term.category)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(term.term)
                            .font(.title3)
                            .fontWeight(.bold)

                        if progress.isFavorite {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                        }

                        Spacer()

                        // 掌握度指示
                        if progress.reviewCount > 0 {
                            MasteryBadge(level: progress.masteryLevel)
                        }
                    }

                    Text(term.pronunciation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .italic()

                    Text(term.chineseTranslation)
                        .font(.body)
                        .foregroundColor(.blue)
                }
            }

            // 定义预览
            Text(term.definition)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .lineSpacing(4)

            // 底部标签行
            HStack {
                DifficultyBadge(difficulty: term.difficulty)

                if progress.reviewCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                        Text("\(progress.reviewCount)")
                            .font(.caption2)
                    }
                    .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                        Text("\(Int(progress.accuracy * 100))%")
                            .font(.caption2)
                    }
                    .foregroundColor(progress.accuracy > 0.7 ? .green : .orange)
                }

                Spacer()

                // 查看详情提示
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(isPressed ? 0.15 : 0.06), radius: isPressed ? 12 : 8, y: isPressed ? 6 : 4)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0.1, pressing: { pressing in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// 现代化列表行
struct ModernVocabularyRow: View {
    let term: MedicalTerm
    @EnvironmentObject var vocabularyManager: VocabularyManager

    var progress: StudyProgress {
        vocabularyManager.getProgress(for: term)
    }

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: term.category)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(term.term)
                        .font(.body)
                        .fontWeight(.semibold)

                    if progress.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption2)
                    }
                }

                Text(term.chineseTranslation)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    DifficultyBadge(difficulty: term.difficulty)

                    if progress.reviewCount > 0 {
                        MasteryIndicator(level: progress.masteryLevel)
                    }
                }
            }

            Spacer()

            if progress.reviewCount > 0 {
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(progress.accuracy * 100))%")
                        .font(.caption)
                        .bold()
                        .foregroundColor(progress.accuracy > 0.7 ? .green : .orange)

                    Text("\(progress.reviewCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

#Preview {
    VocabularyListView()
        .environmentObject(VocabularyManager.shared)
}
