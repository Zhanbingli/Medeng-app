//
//  FilterView.swift
//  Medeng
//
//  Created by Medical English Learning App
//

import SwiftUI

struct FilterView: View {
    @EnvironmentObject var vocabularyManager: VocabularyManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Select Category", selection: $vocabularyManager.selectedCategory) {
                        Text("All Categories").tag(nil as MedicalCategory?)
                        ForEach(MedicalCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as MedicalCategory?)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Difficulty Level") {
                    Picker("Select Difficulty", selection: $vocabularyManager.selectedDifficulty) {
                        Text("All Levels").tag(nil as DifficultyLevel?)
                        Text(DifficultyLevel.beginner.rawValue).tag(DifficultyLevel.beginner as DifficultyLevel?)
                        Text(DifficultyLevel.intermediate.rawValue).tag(DifficultyLevel.intermediate as DifficultyLevel?)
                        Text(DifficultyLevel.advanced.rawValue).tag(DifficultyLevel.advanced as DifficultyLevel?)
                    }
                    .pickerStyle(.inline)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FilterView()
        .environmentObject(VocabularyManager.shared)
}
