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
    @State private var showingImporter = false
    @State private var importQuery = ""
    @State private var isImporting = false
    @State private var importError: String?
    @State private var importResult: MedicalTerm?
    @State private var importSuccess = false
    @State private var showFavoritesOnly = false
    @State private var showDueOnly = false
    @State private var showingAISettings = false
    @State private var showingCustomAdder = false
    @State private var customTermInput = ""
    @State private var customPronunciationInput = ""
    @State private var customTranslationInput = ""
    @State private var customDefinitionInput = ""
    @State private var customExampleInput = ""
    @State private var customEtymologyInput = ""
    @State private var customCategory: MedicalCategory = .general
    @State private var customDifficulty: DifficultyLevel = .beginner
    @State private var customError: String?

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
        var baseTerms = vocabularyManager.filteredTerms

        if showFavoritesOnly {
            baseTerms = baseTerms.filter { vocabularyManager.progressMap[$0.id]?.isFavorite ?? false }
        }

        if showDueOnly {
            let dueSet = Set(vocabularyManager.termsToReview.map { $0.id })
            baseTerms = baseTerms.filter { dueSet.contains($0.id) }
        }

        let sorted: [MedicalTerm]

        switch sortMode {
        case .alphabetical:
            sorted = baseTerms.sorted { $0.term < $1.term }
        case .category:
            sorted = baseTerms.sorted { $0.category.rawValue < $1.category.rawValue }
        case .difficulty:
            sorted = baseTerms.sorted {
                ($0.difficulty.rawValue, $0.term) < ($1.difficulty.rawValue, $1.term)
            }
        case .recent:
            sorted = baseTerms.sorted { term1, term2 in
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
            contentView
        }
    }

    @ViewBuilder
    private var contentView: some View {
        VStack(spacing: 0) {
            headerControls
            listContent
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Medical Vocabulary")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showingAISettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }

                    Button {
                        showingCustomAdder = true
                    } label: {
                        Image(systemName: "plus")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            FilterView()
        }
        .sheet(item: $selectedTerm) { term in
            TermDetailView(term: term)
        }
        .sheet(isPresented: $showingImporter) {
            ImportTermSheet(
                query: $importQuery,
                isImporting: $isImporting,
                error: $importError,
                result: $importResult,
                success: $importSuccess,
                onImport: importTerm
            )
        }
        .sheet(isPresented: $showingCustomAdder) {
            AddCustomTermSheet(
                term: $customTermInput,
                pronunciation: $customPronunciationInput,
                translation: $customTranslationInput,
                definition: $customDefinitionInput,
                example: $customExampleInput,
                etymology: $customEtymologyInput,
                category: $customCategory,
                difficulty: $customDifficulty,
                error: $customError,
                onGenerate: simulateAIGeneration,
                onSave: saveCustomTerm,
                onReset: resetCustomInputs
            )
        }
        .sheet(isPresented: $showingAISettings) {
            AISettingsView()
        }
    }

    @ViewBuilder
    private var headerControls: some View {
        // 搜索栏
        ModernSearchBar(text: $vocabularyManager.searchText)
            .padding(.horizontal)
            .padding(.top, 8)

        QuickScopeChips(
            showFavoritesOnly: $showFavoritesOnly,
            showDueOnly: $showDueOnly,
            clearFilters: clearFilters
        )
        .padding(.horizontal)
        .padding(.bottom, 4)

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
    }

    @ViewBuilder
    private var listContent: some View {
        // 术语列表
        if groupedTerms.flatMap(\.terms).isEmpty {
            EmptyStateView()
        } else {
            ScrollViewReader { _ in
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

    private func importTerm() {
        guard !importQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        importError = nil
        isImporting = true
        importSuccess = false

        Task {
            do {
                if let term = try await MedicalDictionaryService.shared.fetchMedicalTerm(query: importQuery) {
                    await MainActor.run {
                        // Avoid duplicates by term name
                        if !vocabularyManager.allTerms.contains(where: { $0.term.caseInsensitiveCompare(term.term) == .orderedSame }) {
                            vocabularyManager.addCustomTerm(term)
                            importSuccess = true
                            importResult = term
                        } else {
                            importError = "\"\(term.term)\" already exists."
                            importResult = term
                        }
                    }
                } else {
                    await MainActor.run {
                        importError = "No result found for \"\(importQuery)\""
                    }
                }
            } catch {
                await MainActor.run {
                    importError = error.localizedDescription
                }
            }
            await MainActor.run {
                isImporting = false
            }
        }
    }

    private func simulateAIGeneration() {
        let term = customTermInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            customError = "Please enter a term first."
            return
        }
        customError = nil
        let short = term.prefix(40)
        if customDefinitionInput.isEmpty {
            customDefinitionInput = "\(short) is a medical term. This concise definition keeps the card readable."
        }
        if customExampleInput.isEmpty {
            customExampleInput = "Example: The patient presented with \(short.lowercased())."
        }
        if customEtymologyInput.isEmpty {
            customEtymologyInput = "Etymology: \(short)."
        }
    }

    private func saveCustomTerm() {
        let term = customTermInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let translation = customTranslationInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let definition = customDefinitionInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !term.isEmpty else { customError = "Term is required."; return }
        guard !translation.isEmpty else { customError = "Translation is required."; return }
        guard !definition.isEmpty else { customError = "Definition is required."; return }

        let newTerm = MedicalTerm(
            term: term,
            pronunciation: customPronunciationInput.isEmpty ? term : customPronunciationInput,
            definition: String(definition.prefix(200)),
            chineseTranslation: translation,
            etymology: customEtymologyInput.isEmpty ? nil : String(customEtymologyInput.prefix(140)),
            example: customExampleInput.isEmpty ? nil : String(customExampleInput.prefix(160)),
            category: customCategory,
            difficulty: customDifficulty
        )

        if !vocabularyManager.allTerms.contains(where: { $0.term.caseInsensitiveCompare(newTerm.term) == .orderedSame }) {
            vocabularyManager.addCustomTerm(newTerm)
            resetCustomInputs()
            showingCustomAdder = false
        } else {
            customError = "\"\(newTerm.term)\" already exists."
        }
    }

    private func resetCustomInputs() {
        customTermInput = ""
        customPronunciationInput = ""
        customTranslationInput = ""
        customDefinitionInput = ""
        customExampleInput = ""
        customEtymologyInput = ""
        customCategory = .general
        customDifficulty = .beginner
        customError = nil
    }

    private func clearFilters() {
        showFavoritesOnly = false
        showDueOnly = false
        vocabularyManager.selectedCategory = nil
        vocabularyManager.selectedDifficulty = nil
        vocabularyManager.searchText = ""
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

// 快速筛选 chips
struct QuickScopeChips: View {
    @Binding var showFavoritesOnly: Bool
    @Binding var showDueOnly: Bool
    let clearFilters: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(title: "All", isActive: !showFavoritesOnly && !showDueOnly, color: .blue) {
                    showFavoritesOnly = false
                    showDueOnly = false
                }
                FilterChip(title: "Favorites", isActive: showFavoritesOnly, color: .orange) {
                    showFavoritesOnly.toggle()
                    if showFavoritesOnly { showDueOnly = false }
                }
                FilterChip(title: "Due", isActive: showDueOnly, color: .red) {
                    showDueOnly.toggle()
                    if showDueOnly { showFavoritesOnly = false }
                }
                Button(action: clearFilters) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Reset")
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .padding(.vertical, 6)
        }
    }
}

struct FilterChip: View {
    let title: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if isActive {
                    Image(systemName: "checkmark")
                }
                Text(title)
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? color.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(isActive ? color : .primary)
            .cornerRadius(12)
        }
    }
}

// 自定义术语添加弹窗
struct AddCustomTermSheet: View {
    @Binding var term: String
    @Binding var pronunciation: String
    @Binding var translation: String
    @Binding var definition: String
    @Binding var example: String
    @Binding var etymology: String
    @Binding var category: MedicalCategory
    @Binding var difficulty: DifficultyLevel
    @Binding var error: String?
    let onGenerate: () -> Void
    let onSave: () -> Void
    let onReset: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Term (required)", text: $term)
                        .autocapitalization(.none)
                    TextField("Pronunciation", text: $pronunciation)
                        .autocapitalization(.none)
                    TextField("Translation (required)", text: $translation)
                }

                Section("Details") {
                    TextField("Definition (required)", text: $definition, axis: .vertical)
                        .lineLimit(2...4)
                    TextField("Example", text: $example, axis: .vertical)
                        .lineLimit(1...3)
                    TextField("Etymology", text: $etymology, axis: .vertical)
                        .lineLimit(1...2)
                }

                Section("Meta") {
                    Picker("Category", selection: $category) {
                        ForEach(MedicalCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }

                    Picker("Difficulty", selection: $difficulty) {
                        Text(DifficultyLevel.beginner.rawValue).tag(DifficultyLevel.beginner)
                        Text(DifficultyLevel.intermediate.rawValue).tag(DifficultyLevel.intermediate)
                        Text(DifficultyLevel.advanced.rawValue).tag(DifficultyLevel.advanced)
                    }
                }

                if let error = error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Section {
                    Button {
                        onGenerate()
                    } label: {
                        Label("Auto-fill (concise)", systemImage: "wand.and.stars")
                    }
                    .disabled(term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        onSave()
                    } label: {
                        Label("Save Term", systemImage: "checkmark.circle.fill")
                    }
                }
            }
            .navigationTitle("Add Medical Term")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        onReset()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                    }
                }
            }
        }
    }
}

// 术语导入弹窗
struct ImportTermSheet: View {
    @Binding var query: String
    @Binding var isImporting: Bool
    @Binding var error: String?
    @Binding var result: MedicalTerm?
    @Binding var success: Bool
    let onImport: () -> Void
    @Environment(\.dismiss) private var dismiss
    private var hasKey: Bool {
        !(MedicalDictionaryService.shared.currentAPIKey() ?? "").isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("UMLS Search") {
                    TextField("Enter medical term", text: $query)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    if isImporting {
                        ProgressView("Searching…")
                    }

                    if let result = result {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(result.term).font(.headline)
                            Text(result.definition).font(.caption).foregroundColor(.secondary).lineLimit(3)
                        }
                    }

                    if success {
                        Label("Added to vocabulary", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }

                    if !hasKey {
                        Label("Add your UMLS API key in Settings to enable online search.", systemImage: "key.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else if let error = error {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Section {
                    Button {
                        onImport()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Import Term")
                        }
                    }
                    .disabled(isImporting || query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !hasKey)
                }
            }
            .navigationTitle("Add Vocabulary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        query = ""
                        error = nil
                        result = nil
                        success = false
                        dismiss()
                    }
                }
            }
        }
    }
}
