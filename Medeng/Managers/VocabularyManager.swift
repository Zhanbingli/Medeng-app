//
//  VocabularyManager.swift
//  Medeng
//
//  Created by Medical English Learning App
//

import Foundation
import Combine

// 词汇数据管理器
class VocabularyManager: ObservableObject {
    static let shared = VocabularyManager()

    @Published var allTerms: [MedicalTerm] = [] {
        didSet {
            // Rebuild indices when terms change
            buildIndices()
        }
    }
    @Published var progressMap: [UUID: StudyProgress] = [:] {
        didSet {
            // Invalidate statistics cache when progress changes
            invalidateStatistics()
        }
    }
    @Published var searchText: String = ""
    @Published var selectedCategory: MedicalCategory?
    @Published var selectedDifficulty: DifficultyLevel?

    // Performance optimization: indexed lookups
    private var termsByCategory: [MedicalCategory: [MedicalTerm]] = [:]
    private var termsByDifficulty: [DifficultyLevel: [MedicalTerm]] = [:]
    private var termsByID: [UUID: MedicalTerm] = [:]

    // Cached statistics
    private var cachedStatistics: (total: Int, studied: Int, mastered: Int, accuracy: Double)?
    private var statisticsInvalidated = true

    private let termsKey = "medical_terms"
    private let progressKey = "study_progress"

    private init() {
        loadData()
        if allTerms.isEmpty {
            loadSampleData()
        }
        buildIndices()
    }

    /// Build indices for fast lookups
    private func buildIndices() {
        termsByCategory = Dictionary(grouping: allTerms) { $0.category }
        termsByDifficulty = Dictionary(grouping: allTerms) { $0.difficulty }
        termsByID = Dictionary(uniqueKeysWithValues: allTerms.map { ($0.id, $0) })
    }

    /// Fast term lookup by ID
    func getTerm(by id: UUID) -> MedicalTerm? {
        return termsByID[id]
    }

    // 过滤后的术语列表 (优化版本)
    var filteredTerms: [MedicalTerm] {
        // Start with indexed lookup if possible
        var terms: [MedicalTerm]

        // Use index for category filtering (O(1) lookup)
        if let category = selectedCategory {
            terms = termsByCategory[category] ?? []
        } else {
            terms = allTerms
        }

        // Apply difficulty filter (on smaller set if category was filtered)
        if let difficulty = selectedDifficulty {
            terms = terms.filter { $0.difficulty == difficulty }
        }

        // Apply search filter last (on smallest possible set)
        if !searchText.isEmpty {
            let lowercased = searchText.lowercased()
            terms = terms.filter {
                $0.term.lowercased().contains(lowercased) ||
                $0.chineseTranslation.contains(lowercased) ||
                $0.definition.lowercased().contains(lowercased)
            }
        }

        return terms
    }

    // 待复习的术语
    var termsToReview: [MedicalTerm] {
        allTerms.filter { term in
            guard let progress = progressMap[term.id] else { return true }
            return progress.nextReviewDate <= Date()
        }
    }

    // 收藏的术语
    var favoriteTerms: [MedicalTerm] {
        allTerms.filter { term in
            progressMap[term.id]?.isFavorite ?? false
        }
    }

    // 获取术语的进度
    func getProgress(for term: MedicalTerm) -> StudyProgress {
        if let progress = progressMap[term.id] {
            return progress
        } else {
            let newProgress = StudyProgress(termId: term.id)
            progressMap[term.id] = newProgress
            return newProgress
        }
    }

    // 记录复习结果
    func recordReview(for term: MedicalTerm, isCorrect: Bool) {
        var progress = getProgress(for: term)
        progress.recordReview(isCorrect: isCorrect)
        progressMap[term.id] = progress
        saveData()
    }

    // 切换收藏状态
    func toggleFavorite(for term: MedicalTerm) {
        var progress = getProgress(for: term)
        progress.isFavorite.toggle()
        progressMap[term.id] = progress
        saveData()
    }

    // 获取学习统计 (优化版本 - 使用缓存)
    func getStudyStatistics() -> (total: Int, studied: Int, mastered: Int, accuracy: Double) {
        // Return cached result if available
        if !statisticsInvalidated, let cached = cachedStatistics {
            return cached
        }

        // Calculate statistics
        let total = allTerms.count
        let studied = progressMap.values.filter { $0.reviewCount > 0 }.count
        let mastered = progressMap.values.filter { $0.masteryLevel >= 4 }.count

        let totalReviews = progressMap.values.reduce(0) { $0 + $1.reviewCount }
        let totalCorrect = progressMap.values.reduce(0) { $0 + $1.correctCount }
        let accuracy = totalReviews > 0 ? Double(totalCorrect) / Double(totalReviews) : 0

        // Cache the result
        let result = (total, studied, mastered, accuracy)
        cachedStatistics = result
        statisticsInvalidated = false

        return result
    }

    /// Invalidate statistics cache
    private func invalidateStatistics() {
        statisticsInvalidated = true
    }

    // 保存数据到UserDefaults
    private func saveData() {
        if let termsData = try? JSONEncoder().encode(allTerms) {
            UserDefaults.standard.set(termsData, forKey: termsKey)
        }

        if let progressData = try? JSONEncoder().encode(progressMap) {
            UserDefaults.standard.set(progressData, forKey: progressKey)
        }
    }

    // 从UserDefaults加载数据
    private func loadData() {
        if let termsData = UserDefaults.standard.data(forKey: termsKey),
           let terms = try? JSONDecoder().decode([MedicalTerm].self, from: termsData) {
            allTerms = terms
        }

        if let progressData = UserDefaults.standard.data(forKey: progressKey),
           let progress = try? JSONDecoder().decode([UUID: StudyProgress].self, from: progressData) {
            progressMap = progress
        }
    }

    // 加载示例数据 - 使用医学词典服务提供的完整术语库
    private func loadSampleData() {
        // 使用MedicalDictionaryService提供的90+专业医学术语
        allTerms = MedicalDictionaryService.shared.loadComprehensiveMedicalTerms()
        saveData()
    }

    // 重置所有数据
    func resetAllData() {
        progressMap.removeAll()
        saveData()
    }

    // 添加自定义术语
    func addCustomTerm(_ term: MedicalTerm) {
        allTerms.append(term)
        saveData()
    }
}
