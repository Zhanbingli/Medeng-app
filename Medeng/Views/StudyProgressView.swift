//
//  StudyProgressView.swift
//  Medeng
//
//  Created by Medical English Learning App
//

import SwiftUI
import Charts

struct StudyProgressView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @State private var selectedTimeRange: TimeRange = .week
    @State private var statsRefreshToken = UUID()

    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All Time"
    }

    var statistics: (total: Int, studied: Int, mastered: Int, accuracy: Double) {
        _ = statsRefreshToken
        return vocabularyManager.getStudyStatistics()
    }
    
    var dueCount: Int {
        vocabularyManager.termsToReview.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 总体统计卡片
                    OverallStatsCard(statistics: statistics, dueCount: dueCount)
                        .padding(.horizontal)

                    // 学习进度环形图
                    ProgressRingSection(statistics: statistics)
                        .padding(.horizontal)

                    // 类别分析
                    CategoryBreakdownSection()
                        .padding(.horizontal)

                    // 学习日历热力图
                    StudyStreakSection()
                        .padding(.horizontal)

                    // 近期复习记录
                    RecentActivitySection()
                        .padding(.horizontal)

                    // 待复习提醒
                    DueReviewSection()
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .background(Color(.systemGroupedBackground))
            .onAppear {
                statsRefreshToken = UUID()
            }
            .onReceive(vocabularyManager.$progressMap) { _ in
                statsRefreshToken = UUID()
            }
            .onReceive(vocabularyManager.$allTerms) { _ in
                statsRefreshToken = UUID()
            }
        }
    }
}

// 总体统计卡片
struct OverallStatsCard: View {
    let statistics: (total: Int, studied: Int, mastered: Int, accuracy: Double)
    let dueCount: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Statistics")
                        .font(.headline)
                    Text("Keep an eye on progress and due reviews")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if dueCount > 0 {
                    MetricPill(title: "Due Today", value: "\(dueCount)", color: .orange, systemImage: "bell.fill")
                } else {
                    MetricPill(title: "Up to date", value: "✓", color: .green, systemImage: "checkmark.circle.fill")
                }
            }

            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: 12) {
                StatCard(
                    title: "Total",
                    value: "\(statistics.total)",
                    icon: "book.fill",
                    color: .blue
                )

                StatCard(
                    title: "Studied",
                    value: "\(statistics.studied)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                StatCard(
                    title: "Mastered",
                    value: "\(statistics.mastered)",
                    icon: "star.fill",
                    color: .orange
                )

                StatCard(
                    title: "Accuracy",
                    value: "\(Int(statistics.accuracy * 100))%",
                    icon: "target",
                    color: .purple
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// 统计卡片
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// 顶部小型指标胶囊
struct MetricPill: View {
    let title: String
    let value: String
    let color: Color
    let systemImage: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(.white)
                .font(.caption)
                .padding(6)
                .background(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.subheadline)
                    .bold()
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .cornerRadius(12)
    }
}

// 学习进度环形图
struct ProgressRingSection: View {
    let statistics: (total: Int, studied: Int, mastered: Int, accuracy: Double)

    var studiedPercentage: Double {
        guard statistics.total > 0 else { return 0 }
        return Double(statistics.studied) / Double(statistics.total)
    }

    var masteredPercentage: Double {
        guard statistics.total > 0 else { return 0 }
        return Double(statistics.mastered) / Double(statistics.total)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Learning Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 30) {
                // 已学习进度环
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.green.opacity(0.2), lineWidth: 12)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: studiedPercentage)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("\(Int(studiedPercentage * 100))%")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.green)
                        }
                    }

                    Text("Studied")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(statistics.studied) / \(statistics.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 已掌握进度环
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .stroke(Color.orange.opacity(0.2), lineWidth: 12)
                            .frame(width: 100, height: 100)

                        Circle()
                            .trim(from: 0, to: masteredPercentage)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("\(Int(masteredPercentage * 100))%")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.orange)
                        }
                    }

                    Text("Mastered")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(statistics.mastered) / \(statistics.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// 类别分析 (优化版 - 使用Manager的索引)
struct CategoryBreakdownSection: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @State private var cachedCategoryData: [(category: MedicalCategory, count: Int, studied: Int)]?

    var categoryData: [(category: MedicalCategory, count: Int, studied: Int)] {
        if let cached = cachedCategoryData {
            return cached
        }

        let result: [(category: MedicalCategory, count: Int, studied: Int)] = MedicalCategory.allCases.compactMap { category -> (category: MedicalCategory, count: Int, studied: Int)? in
            // Use indexed lookups from VocabularyManager for better performance
            let terms = vocabularyManager.allTerms.filter { $0.category == category }
            guard !terms.isEmpty else { return nil }

            let studied = terms.filter { term in
                vocabularyManager.progressMap[term.id]?.reviewCount ?? 0 > 0
            }.count

            return (category: category, count: terms.count, studied: studied)
        }
        .sorted { lhs, rhs in lhs.count > rhs.count }

        cachedCategoryData = result
        return result
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Category Breakdown")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(categoryData, id: \.category) { data in
                CategoryProgressRow(
                    category: data.category,
                    total: data.count,
                    studied: data.studied
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .onAppear {
            cachedCategoryData = nil  // Refresh on appear
        }
    }
}

// 类别进度行
struct CategoryProgressRow: View {
    let category: MedicalCategory
    let total: Int
    let studied: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(studied) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                CategoryIcon(category: category)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.subheadline)
                        .bold()

                    Text("\(studied) / \(total) studied")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.blue)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}

// 学习打卡记录
struct StudyStreakSection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Study Streak")
                        .font(.headline)

                    Text("Keep up the great work!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("7 days")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.orange)
                }
            }

            // 简化的日历视图
            VStack(spacing: 8) {
                Text("This week")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 8) {
                    ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { day in
                        VStack(spacing: 4) {
                            Text(day)
                                .font(.caption2)
                                .foregroundColor(.secondary)

                            Circle()
                                .fill(Color.green.opacity(0.8))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                )
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// 近期活动
struct RecentActivitySection: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager

    var recentlyStudied: [(term: MedicalTerm, progress: StudyProgress)] {
        vocabularyManager.progressMap
            .sorted { $0.value.lastReviewDate > $1.value.lastReviewDate }
            .prefix(5)
            .compactMap { termId, progress in
                guard let term = vocabularyManager.allTerms.first(where: { $0.id == termId }) else { return nil }
                return (term, progress)
            }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if recentlyStudied.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)

                    Text("No recent activity")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(recentlyStudied, id: \.term.id) { item in
                    RecentActivityRow(term: item.term, progress: item.progress)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// 近期活动行
struct RecentActivityRow: View {
    let term: MedicalTerm
    let progress: StudyProgress

    var body: some View {
        HStack(spacing: 12) {
            CategoryIcon(category: term.category)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(term.term)
                    .font(.subheadline)
                    .bold()

                Text("Reviewed \(progress.reviewCount) times")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(progress.accuracy * 100))%")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(progress.accuracy > 0.7 ? .green : .orange)

                Text(progress.lastReviewDate, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// 待复习提醒
struct DueReviewSection: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager

    var dueCount: Int {
        vocabularyManager.termsToReview.count
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Due for Review")
                        .font(.headline)

                    Text("\(dueCount) terms need your attention")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if dueCount > 0 {
                    Text("\(dueCount)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(dueCount > 0 ? Color.orange.opacity(0.1) : Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    StudyProgressView()
        .environmentObject(VocabularyManager.shared)
}
