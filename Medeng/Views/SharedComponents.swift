//
//  SharedComponents.swift
//  Medeng
//
//  共享UI组件
//

import SwiftUI

// 类别图标
struct CategoryIcon: View {
    let category: MedicalCategory

    var icon: String {
        switch category {
        case .anatomy: return "figure.stand"
        case .physiology: return "lungs.fill"
        case .pathology: return "cross.case.fill"
        case .pharmacology: return "pills.fill"
        case .surgery: return "bandage.fill"
        case .medicine: return "stethoscope"
        case .pediatrics: return "figure.and.child.holdinghands"
        case .cardiology: return "heart.fill"
        case .neurology: return "brain.head.profile"
        case .general: return "book.fill"
        case .radiology: return "waveform.path.ecg"
        }
    }

    var color: Color {
        switch category {
        case .anatomy: return .purple
        case .physiology: return .blue
        case .pathology: return .red
        case .pharmacology: return .green
        case .surgery: return .orange
        case .medicine: return .teal
        case .pediatrics: return .pink
        case .cardiology: return .red
        case .neurology: return .indigo
        case .general: return .gray
        case .radiology: return .cyan
        }
    }

    var body: some View {
        Image(systemName: icon)
            .foregroundColor(color)
            .frame(width: 40, height: 40)
            .background(color.opacity(0.2))
            .cornerRadius(8)
    }
}

// 难度标签
struct DifficultyBadge: View {
    let difficulty: DifficultyLevel

    var color: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }

    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

// 掌握度指示器
struct MasteryIndicator: View {
    let level: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Circle()
                    .fill(index < level ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }
}

// 空状态视图
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No terms found")
                .font(.title2)
                .bold()

            Text("Try adjusting your search or filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// 掌握度徽章（用于卡片视图）
struct MasteryBadge: View {
    let level: Int

    var color: Color {
        switch level {
        case 0...1: return .gray
        case 2...3: return .orange
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { index in
                Image(systemName: index < level ? "star.fill" : "star")
                    .font(.caption2)
                    .foregroundColor(index < level ? color : .gray.opacity(0.3))
            }
        }
    }
}
