//
//  MedicalTerm.swift
//  Medeng
//
//  Created by Medical English Learning App
//

import Foundation

// 医学词汇类别
enum MedicalCategory: String, CaseIterable, Codable {
    case anatomy = "Anatomy"           // 解剖学
    case physiology = "Physiology"     // 生理学
    case pathology = "Pathology"       // 病理学
    case pharmacology = "Pharmacology" // 药理学
    case surgery = "Surgery"           // 外科
    case medicine = "Medicine"         // 内科
    case pediatrics = "Pediatrics"     // 儿科
    case cardiology = "Cardiology"     // 心脏科
    case neurology = "Neurology"       // 神经科
    case radiology = "Radiology"       // 放射科
    case general = "General"           // 通用
}

// 难度等级
enum DifficultyLevel: String, Codable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

// 医学术语模型
struct MedicalTerm: Identifiable, Codable, Equatable {
    let id: UUID
    let term: String                    // 术语
    let pronunciation: String           // 发音（音标）
    let definition: String              // 定义
    let chineseTranslation: String      // 中文翻译
    let etymology: String?              // 词源（词根词缀）
    let example: String?                // 例句
    let category: MedicalCategory       // 类别
    let difficulty: DifficultyLevel     // 难度
    let relatedTerms: [String]          // 相关术语
    let imageURL: String?               // 配图URL（可选）

    init(
        id: UUID = UUID(),
        term: String,
        pronunciation: String,
        definition: String,
        chineseTranslation: String,
        etymology: String? = nil,
        example: String? = nil,
        category: MedicalCategory,
        difficulty: DifficultyLevel,
        relatedTerms: [String] = [],
        imageURL: String? = nil
    ) {
        self.id = id
        self.term = term
        self.pronunciation = pronunciation
        self.definition = definition
        self.chineseTranslation = chineseTranslation
        self.etymology = etymology
        self.example = example
        self.category = category
        self.difficulty = difficulty
        self.relatedTerms = relatedTerms
        self.imageURL = imageURL
    }
}

// 学习进度模型
struct StudyProgress: Codable {
    let termId: UUID
    var reviewCount: Int                // 复习次数
    var correctCount: Int               // 正确次数
    var lastReviewDate: Date            // 最后复习日期
    var nextReviewDate: Date            // 下次复习日期
    var masteryLevel: Int               // 掌握程度 (0-5)
    var isFavorite: Bool                // 是否收藏

    init(termId: UUID) {
        self.termId = termId
        self.reviewCount = 0
        self.correctCount = 0
        self.lastReviewDate = Date()
        self.nextReviewDate = Date()
        self.masteryLevel = 0
        self.isFavorite = false
    }

    // 计算正确率
    var accuracy: Double {
        guard reviewCount > 0 else { return 0 }
        return Double(correctCount) / Double(reviewCount)
    }

    // 更新复习记录
    mutating func recordReview(isCorrect: Bool) {
        reviewCount += 1
        if isCorrect {
            correctCount += 1
            masteryLevel = min(5, masteryLevel + 1)
        } else {
            masteryLevel = max(0, masteryLevel - 1)
        }
        lastReviewDate = Date()

        // 间隔重复算法：根据掌握程度计算下次复习时间
        let intervalDays = calculateNextInterval()
        nextReviewDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: Date()) ?? Date()
    }

    // 计算下次复习间隔（天数）
    private func calculateNextInterval() -> Int {
        switch masteryLevel {
        case 0: return 0  // 立即复习
        case 1: return 1  // 1天后
        case 2: return 3  // 3天后
        case 3: return 7  // 1周后
        case 4: return 14 // 2周后
        case 5: return 30 // 1月后
        default: return 0
        }
    }
}
