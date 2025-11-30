//
//  FlashcardViewNew.swift
//  Medeng
//
//  现代化重构版本 - 滑动手势 + 卡片堆叠效果
//

import SwiftUI

struct FlashcardView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @State private var currentIndex = 0
    @State private var showingOptions = false
    @State private var termsToStudy: [MedicalTerm] = []
    @State private var studySource: StudySource = .auto

    enum StudySource {
        case auto        // Due terms if available, otherwise all
        case dueOnly     // Only due terms
        case all         // All terms
    }

    private func refreshTermsToStudy(resetIndex: Bool) {
        let dueTerms = vocabularyManager.termsToReview
        let nextList: [MedicalTerm]

        switch studySource {
        case .auto:
            nextList = dueTerms.isEmpty ? vocabularyManager.allTerms : dueTerms
        case .dueOnly:
            nextList = dueTerms
        case .all:
            nextList = vocabularyManager.allTerms
        }

        // Only update when the data set actually changes
        if nextList.map(\.id) != termsToStudy.map(\.id) {
            termsToStudy = nextList

            if resetIndex {
                currentIndex = 0
            } else if currentIndex >= nextList.count {
                currentIndex = max(0, nextList.count - 1)
            }
        }
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()

                    if termsToStudy.isEmpty {
                        EmptyStudyView()
                    } else {
                        VStack(spacing: 0) {
                            // 顶部进度和统计
                            ModernProgressHeader(
                                current: currentIndex + 1,
                                total: termsToStudy.count,
                                dueCount: vocabularyManager.termsToReview.count
                            )
                            .padding(.horizontal)
                            .padding(.top, 8)

                            Spacer().frame(height: 20)

                            // 卡片堆叠区域
                            ZStack {
                                // 后面的卡片（预览效果）
                                ForEach(Array(termsToStudy.enumerated()), id: \.element.id) { index, term in
                                    if index >= currentIndex && index < currentIndex + 3 {
                                        SwipeableFlashcard(
                                            term: term,
                                            index: index - currentIndex,
                                            onSwipeLeft: {
                                                handleReview(for: term, isCorrect: false)
                                            },
                                            onSwipeRight: {
                                                handleReview(for: term, isCorrect: true)
                                            }
                                        )
                                        .environmentObject(vocabularyManager)
                                        .zIndex(Double(termsToStudy.count - index))
                                    }
                                }
                            }
                            .frame(height: geometry.size.height * 0.6)
                            .padding(.horizontal, 20)

                            Spacer()

                            // 底部提示
                            HStack(spacing: 40) {
                                VStack(spacing: 8) {
                                    Image(systemName: "arrow.left")
                                        .font(.title2)
                                        .foregroundColor(.red)
                                    Text("Again")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                VStack(spacing: 8) {
                                    Image(systemName: "hand.tap.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text("Flip Card")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                VStack(spacing: 8) {
                                    Image(systemName: "arrow.right")
                                        .font(.title2)
                                        .foregroundColor(.green)
                                    Text("Good")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingOptions = true }) {
                        Image(systemName: "ellipsis.circle")
                    }
                    .confirmationDialog("Practice Options", isPresented: $showingOptions) {
                        Button("Auto (Due → All)") {
                            studySource = .auto
                            refreshTermsToStudy(resetIndex: true)
                        }
                        Button("Due Terms Only") {
                            studySource = .dueOnly
                            refreshTermsToStudy(resetIndex: true)
                        }
                        Button("All Terms") {
                            studySource = .all
                            refreshTermsToStudy(resetIndex: true)
                        }
                        Button("Restart Session", role: .destructive) {
                            refreshTermsToStudy(resetIndex: true)
                        }
                        Button("Cancel", role: .cancel) { }
                    }
                }
            }
            .onAppear {
                refreshTermsToStudy(resetIndex: true)
            }
            .onReceive(vocabularyManager.$progressMap) { _ in
                // Keep deck in sync with newly reviewed items
                refreshTermsToStudy(resetIndex: false)
            }
            .onReceive(vocabularyManager.$allTerms) { _ in
                // New terms should restart the session ordering
                refreshTermsToStudy(resetIndex: true)
            }
        }
    }

    private func handleReview(for term: MedicalTerm, isCorrect: Bool) {
        vocabularyManager.recordReview(for: term, isCorrect: isCorrect)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            if currentIndex < termsToStudy.count - 1 {
                currentIndex += 1
            }
        }
    }
}

// 现代化进度头部
struct ModernProgressHeader: View {
    let current: Int
    let total: Int
    let dueCount: Int

    var progress: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Practice Session")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Text("\(current)")
                            .font(.title2)
                            .bold()
                        Text("/ \(total)")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if dueCount > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Due Today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(dueCount)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                }
            }

            // 渐变进度条
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

// 可滑动的闪卡
struct SwipeableFlashcard: View {
    let term: MedicalTerm
    let index: Int
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    @EnvironmentObject var vocabularyManager: VocabularyManager
    @State private var isShowingAnswer = false
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0

    @State private var cachedProgress: StudyProgress?

    var progress: StudyProgress {
        if let cached = cachedProgress {
            return cached
        }
        let p = vocabularyManager.getProgress(for: term)
        cachedProgress = p
        return p
    }

    // 计算卡片缩放和偏移（堆叠效果）- 优化为常量
    private let baseScale: CGFloat = 1.0
    private let scaleDecrement: CGFloat = 0.05
    private let verticalOffsetStep: CGFloat = -10

    var scale: CGFloat {
        baseScale - (CGFloat(index) * scaleDecrement)
    }

    var verticalOffset: CGFloat {
        CGFloat(index) * verticalOffsetStep
    }

    var isDragging: Bool {
        abs(offset.width) > 5 || abs(offset.height) > 5  // Add threshold to avoid micro-movements
    }

    var body: some View {
        ZStack {
            // 卡片背景
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
                .shadow(
                    color: isDragging ? .blue.opacity(0.3) : .black.opacity(0.1),
                    radius: isDragging ? 20 : 15,
                    y: isDragging ? 10 : 5
                )

            // 卡片内容
            if index == 0 {
                FlashcardContent(
                    term: term,
                    isShowingAnswer: $isShowingAnswer,
                    progress: progress
                )
                .padding(24)
            } else {
                // 后面的卡片只显示简化内容
                VStack {
                    Text(term.term)
                        .font(.title)
                        .bold()
                }
                .padding(24)
            }

            // 滑动指示器
            if index == 0 && isDragging {
                VStack {
                    HStack {
                        if offset.width < -50 {
                            SwipeIndicator(color: .red, icon: "xmark", text: "Again")
                                .opacity(Double(-offset.width / 100))
                        }

                        Spacer()

                        if offset.width > 50 {
                            SwipeIndicator(color: .green, icon: "checkmark", text: "Good")
                                .opacity(Double(offset.width / 100))
                        }
                    }
                    Spacer()
                }
                .padding(32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .scaleEffect(scale)
        .offset(y: verticalOffset)
        .offset(x: index == 0 ? offset.width : 0, y: index == 0 ? offset.height : 0)
        .rotationEffect(.degrees(index == 0 ? rotation : 0))
        .opacity(index < 2 ? 1.0 : 0.5)
        .gesture(
            index == 0 ? DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
                }
                .onEnded { gesture in
                    let threshold: CGFloat = 100

                    if gesture.translation.width < -threshold {
                        // 向左滑 - Again
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = CGSize(width: -500, height: gesture.translation.height)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwipeLeft()
                            resetCard()
                        }
                    } else if gesture.translation.width > threshold {
                        // 向右滑 - Good
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            offset = CGSize(width: 500, height: gesture.translation.height)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onSwipeRight()
                            resetCard()
                        }
                    } else {
                        // 回弹
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            offset = .zero
                            rotation = 0
                        }
                    }
                }
            : nil
        )
        .onTapGesture {
            if index == 0 {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isShowingAnswer.toggle()
                }
            }
        }
    }

    private func resetCard() {
        offset = .zero
        rotation = 0
        isShowingAnswer = false
    }
}

// 闪卡内容
struct FlashcardContent: View {
    let term: MedicalTerm
    @Binding var isShowingAnswer: Bool
    let progress: StudyProgress

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                if !isShowingAnswer {
                    // 问题面
                    VStack(spacing: 16) {
                        HStack {
                            CategoryIcon(category: term.category)
                                .frame(width: 56, height: 56)

                            DifficultyBadge(difficulty: term.difficulty)
                                .padding(.leading, 4)

                            Spacer()

                            SmallPronunciationButton(term: term)
                        }

                        Text(term.term)
                            .font(.system(size: 36, weight: .bold))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.7)

                        Text(term.pronunciation)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .italic()

                        Spacer().frame(height: 8)

                        HStack(spacing: 10) {
                            Label("Tap to reveal", systemImage: "hand.tap.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if progress.masteryLevel > 0 {
                                MasteryBadge(level: progress.masteryLevel)
                            }
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }

                } else {
                    // 答案面
                    VStack(alignment: .leading, spacing: 16) {
                        // 标题
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(term.term)
                                        .font(.title)
                                        .bold()

                                    Text(term.chineseTranslation)
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 8) {
                                    DifficultyBadge(difficulty: term.difficulty)
                                    SmallPronunciationButton(term: term)
                                }
                            }

                            if progress.reviewCount > 0 {
                                MasteryBadge(level: progress.masteryLevel)
                            }
                        }

                        Divider()

                        // 定义
                        InfoSection(
                            icon: "book.fill",
                            title: "Definition",
                            content: term.definition,
                            color: .blue
                        )

                        // 词源
                        if let etymology = term.etymology {
                            InfoSection(
                                icon: "tree.fill",
                                title: "Etymology",
                                content: etymology,
                                color: .green
                            )
                        }

                        // 例句
                        if let example = term.example {
                            InfoSection(
                                icon: "quote.bubble.fill",
                                title: "Example",
                                content: example,
                                color: .orange
                            )
                        }

                        // 学习统计
                        if progress.reviewCount > 0 {
                            Divider()

                            HStack(spacing: 16) {
                                StatPill(
                                    icon: "arrow.clockwise",
                                    value: "\(progress.reviewCount)",
                                    label: "Reviews",
                                    color: .blue
                                )

                                StatPill(
                                    icon: "checkmark.circle.fill",
                                    value: "\(Int(progress.accuracy * 100))%",
                                    label: "Accuracy",
                                    color: progress.accuracy > 0.7 ? .green : .orange
                                )
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
    }
}

// 信息区块
struct InfoSection: View {
    let icon: String
    let title: String
    let content: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(content)
                .font(.body)
                .lineSpacing(4)
                .foregroundColor(.primary)
        }
    }
}

// 统计药丸
struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .bold()
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(12)
    }
}

// 滑动指示器
struct SwipeIndicator: View {
    let color: Color
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon + ".circle.fill")
                .font(.system(size: 44))
                .foregroundColor(color)

            Text(text)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(16)
        .background(color.opacity(0.1))
        .cornerRadius(16)
    }
}

// 空状态视图
struct EmptyStudyView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 8) {
                Text("All Done!")
                    .font(.title)
                    .bold()

                Text("You've reviewed all due terms.\nGreat job! 🎉")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

#Preview {
    FlashcardView()
        .environmentObject(VocabularyManager.shared)
}
