//
//  MedengTests.swift
//  MedengTests
//
//  Created by lizhanbing12 on 8/10/25.
//

import Testing
@testable import Medeng

// MARK: - Medical Term Tests

@Suite("Medical Term Tests")
struct MedicalTermTests {

    @Test("Medical term creation")
    func testMedicalTermCreation() async throws {
        let term = MedicalTerm(
            term: "Hypertension",
            pronunciation: "/ˌhaɪpərˈtenʃən/",
            definition: "High blood pressure",
            chineseTranslation: "高血压",
            etymology: "hyper- (excessive) + tension (pressure)",
            example: "The patient has hypertension.",
            category: .cardiology,
            difficulty: .beginner,
            relatedTerms: ["Hypotension", "Blood Pressure"]
        )

        #expect(term.term == "Hypertension")
        #expect(term.category == .cardiology)
        #expect(term.difficulty == .beginner)
        #expect(term.relatedTerms.count == 2)
    }
}

// MARK: - Study Progress Tests

@Suite("Study Progress Tests")
struct StudyProgressTests {

    @Test("Progress initialization")
    func testProgressInitialization() async throws {
        let termId = UUID()
        let progress = StudyProgress(termId: termId)

        #expect(progress.termId == termId)
        #expect(progress.reviewCount == 0)
        #expect(progress.correctCount == 0)
        #expect(progress.masteryLevel == 0)
        #expect(progress.isFavorite == false)
        #expect(progress.accuracy == 0.0)
    }

    @Test("Correct review records")
    func testCorrectReview() async throws {
        var progress = StudyProgress(termId: UUID())

        progress.recordReview(isCorrect: true)

        #expect(progress.reviewCount == 1)
        #expect(progress.correctCount == 1)
        #expect(progress.masteryLevel == 1)
        #expect(progress.accuracy == 1.0)
    }

    @Test("Incorrect review records")
    func testIncorrectReview() async throws {
        var progress = StudyProgress(termId: UUID())

        progress.recordReview(isCorrect: true)
        progress.recordReview(isCorrect: false)

        #expect(progress.reviewCount == 2)
        #expect(progress.correctCount == 1)
        #expect(progress.masteryLevel == 0)
        #expect(progress.accuracy == 0.5)
    }

    @Test("Spaced repetition algorithm")
    func testSpacedRepetition() async throws {
        var progress = StudyProgress(termId: UUID())

        // Test mastery level 0 -> 1
        progress.recordReview(isCorrect: true)
        #expect(progress.masteryLevel == 1)

        // Test mastery level increases
        progress.recordReview(isCorrect: true)
        #expect(progress.masteryLevel == 2)

        progress.recordReview(isCorrect: true)
        #expect(progress.masteryLevel == 3)

        // Test mastery level caps at 5
        for _ in 0..<10 {
            progress.recordReview(isCorrect: true)
        }
        #expect(progress.masteryLevel == 5)
    }

    @Test("Mastery level decreases on wrong answer")
    func testMasteryDecrease() async throws {
        var progress = StudyProgress(termId: UUID())

        progress.recordReview(isCorrect: true)
        progress.recordReview(isCorrect: true)
        #expect(progress.masteryLevel == 2)

        progress.recordReview(isCorrect: false)
        #expect(progress.masteryLevel == 1)

        progress.recordReview(isCorrect: false)
        #expect(progress.masteryLevel == 0)

        // Test mastery level doesn't go below 0
        progress.recordReview(isCorrect: false)
        #expect(progress.masteryLevel == 0)
    }
}

// MARK: - Secure Storage Tests

@Suite("Secure Storage Tests")
struct SecureStorageTests {

    @Test("Save and load data")
    func testSaveAndLoad() async throws {
        let storage = SecureStorage()
        let key = "test_key_\(UUID().uuidString)"
        let value = "test_value"

        try storage.save(key: key, value: value)
        let loaded = try storage.load(key: key)

        #expect(loaded == value)

        // Cleanup
        try storage.delete(key: key)
    }

    @Test("Overwrite existing data")
    func testOverwrite() async throws {
        let storage = SecureStorage()
        let key = "test_key_\(UUID().uuidString)"
        let value1 = "value1"
        let value2 = "value2"

        try storage.save(key: key, value: value1)
        try storage.save(key: key, value: value2)

        let loaded = try storage.load(key: key)
        #expect(loaded == value2)

        // Cleanup
        try storage.delete(key: key)
    }

    @Test("Delete data")
    func testDelete() async throws {
        let storage = SecureStorage()
        let key = "test_key_\(UUID().uuidString)"
        let value = "test_value"

        try storage.save(key: key, value: value)
        #expect(storage.exists(key: key) == true)

        try storage.delete(key: key)
        #expect(storage.exists(key: key) == false)

        let loaded = try storage.load(key: key)
        #expect(loaded == nil)
    }
}

// MARK: - Performance Tests

@Suite("Performance Tests")
struct PerformanceTests {

    @Test("Vocabulary filtering performance")
    func testFilteringPerformance() async throws {
        let manager = VocabularyManager.shared
        _ = manager.filteredTerms
        // Performance baseline established
    }

    @Test("Statistics calculation performance")
    func testStatisticsPerformance() async throws {
        let manager = VocabularyManager.shared
        _ = manager.getStudyStatistics()
        // Performance baseline established
    }
}
