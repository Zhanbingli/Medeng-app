//
//  VocabularyManager.swift
//  Medeng
//
//  Created by Medical English Learning App
//

import Foundation
import Combine

// 词汇数据管理器
@MainActor
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
    @Published var searchText: String = "" {
        didSet {
            invalidateFilterCache()
        }
    }
    @Published var selectedCategory: MedicalCategory? {
        didSet {
            invalidateFilterCache()
        }
    }
    @Published var selectedDifficulty: DifficultyLevel? {
        didSet {
            invalidateFilterCache()
        }
    }

    // Performance optimization: indexed lookups
    private var termsByCategory: [MedicalCategory: [MedicalTerm]] = [:]
    private var termsByDifficulty: [DifficultyLevel: [MedicalTerm]] = [:]
    private var termsByID: [UUID: MedicalTerm] = [:]

    // Cached filter results
    private var cachedFilteredTerms: [MedicalTerm]?
    private var filterCacheInvalidated = true

    // Cached derived lists
    private var cachedTermsToReview: [MedicalTerm]?
    private var termsToReviewCacheDate: Date?
    private let reviewCacheTTL: TimeInterval = 300 // 5 minutes to avoid stale due reminders
    private var cachedFavoriteTerms: [MedicalTerm]?

    // Cached statistics
    private var cachedStatistics: (total: Int, studied: Int, mastered: Int, accuracy: Double)?
    private var statisticsInvalidated = true

    private let termsKey = "medical_terms"
    private let progressKey = "study_progress"
    private let persistenceQueue = DispatchQueue(label: "com.medeng.vocabulary.persistence", qos: .utility)

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
        invalidateFilterCache()
        invalidateDerivedLists()
    }

    /// Invalidate filter cache
    private func invalidateFilterCache() {
        filterCacheInvalidated = true
    }

    /// Invalidate derived lists cache
    private func invalidateDerivedLists() {
        cachedTermsToReview = nil
        termsToReviewCacheDate = nil
        cachedFavoriteTerms = nil
    }

    /// Fast term lookup by ID
    func getTerm(by id: UUID) -> MedicalTerm? {
        return termsByID[id]
    }

    // 过滤后的术语列表 (优化版本 - 带缓存)
    var filteredTerms: [MedicalTerm] {
        // Return cached result if available
        if !filterCacheInvalidated, let cached = cachedFilteredTerms {
            return cached
        }

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

        // Cache the result
        cachedFilteredTerms = terms
        filterCacheInvalidated = false

        return terms
    }

    // 待复习的术语 (带缓存)
    var termsToReview: [MedicalTerm] {
        // Invalidate cache when it is too old or crosses day boundary
        if let cached = cachedTermsToReview,
           let cacheDate = termsToReviewCacheDate,
           !hasReviewCacheExpired(since: cacheDate) {
            return cached
        }

        let result = allTerms.filter { term in
            guard let progress = progressMap[term.id] else { return true }
            return progress.nextReviewDate <= Date()
        }

        cachedTermsToReview = result
        termsToReviewCacheDate = Date()
        return result
    }

    private func hasReviewCacheExpired(since date: Date) -> Bool {
        if Date().timeIntervalSince(date) > reviewCacheTTL {
            return true
        }
        // If day changed, expire to catch newly-due cards after midnight
        return !Calendar.current.isDate(date, inSameDayAs: Date())
    }

    // 收藏的术语 (带缓存)
    var favoriteTerms: [MedicalTerm] {
        if let cached = cachedFavoriteTerms {
            return cached
        }

        let result = allTerms.filter { term in
            progressMap[term.id]?.isFavorite ?? false
        }

        cachedFavoriteTerms = result
        return result
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
        invalidateDerivedLists()  // Invalidate since review status changed
        saveData()
    }

    // 切换收藏状态
    func toggleFavorite(for term: MedicalTerm) {
        var progress = getProgress(for: term)
        progress.isFavorite.toggle()
        progressMap[term.id] = progress
        invalidateDerivedLists()  // Invalidate since favorite status changed
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

    // MARK: - Activity / Streaks

    private func startOfDay(for date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// 当前连续打卡天数（基于最近一次复习到今天的连续天）
    func currentStudyStreak() -> Int {
        let days = Set(
            progressMap.values
                .filter { $0.reviewCount > 0 }
                .map { startOfDay(for: $0.lastReviewDate) }
        )
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var cursor = startOfDay(for: Date())

        while days.contains(cursor) {
            streak += 1
            if let previousDay = Calendar.current.date(byAdding: .day, value: -1, to: cursor) {
                cursor = previousDay
            } else {
                break
            }
        }
        return streak
    }

    /// 最近7天的活动布尔标记（从周一到周日或从今天回溯6天）
    func recentActivity(last daysCount: Int = 7) -> [Bool] {
        let daySet = Set(
            progressMap.values
                .filter { $0.reviewCount > 0 }
                .map { startOfDay(for: $0.lastReviewDate) }
        )
        let today = startOfDay(for: Date())
        var activity: [Bool] = []

        for offset in stride(from: daysCount - 1, through: 0, by: -1) {
            if let day = Calendar.current.date(byAdding: .day, value: -offset, to: today) {
                activity.append(daySet.contains(day))
            }
        }
        return activity
    }

    /// Invalidate statistics cache
    private func invalidateStatistics() {
        statisticsInvalidated = true
    }

    // 保存数据到UserDefaults
    private func saveData() {
        // Snapshot on main-actor, persist off-main to avoid UI stalls
        let termsSnapshot = allTerms
        let progressSnapshot = progressMap

        persistenceQueue.async { [termsKey, progressKey] in
            if let termsData = try? JSONEncoder().encode(termsSnapshot) {
                UserDefaults.standard.set(termsData, forKey: termsKey)
            }

            if let progressData = try? JSONEncoder().encode(progressSnapshot) {
                UserDefaults.standard.set(progressData, forKey: progressKey)
            }
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
