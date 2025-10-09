//
//  ContentView.swift
//  Medeng
//
//  Created by lizhanbing12 on 8/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vocabularyManager = VocabularyManager.shared
    @State private var selectedTab = 0
    @State private var showWelcome = false
    @Namespace private var animation

    var body: some View {
        ZStack {
            // 主界面
            TabView(selection: $selectedTab) {
                // 词汇列表
                VocabularyListView()
                    .tabItem {
                        Label("Words", systemImage: selectedTab == 0 ? "text.book.closed.fill" : "text.book.closed")
                    }
                    .tag(0)

                // 学习卡片
                FlashcardView()
                    .tabItem {
                        Label("Practice", systemImage: selectedTab == 1 ? "brain.head.profile" : "brain")
                    }
                    .tag(1)

                // 学习进度
                StudyProgressView()
                    .tabItem {
                        Label("Progress", systemImage: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    }
                    .tag(2)
            }
            .environmentObject(vocabularyManager)
            .accentColor(.blue)

            // 欢迎界面（首次启动）
            if showWelcome {
                WelcomeView(isShowing: $showWelcome)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale),
                        removal: .opacity
                    ))
                    .zIndex(1)
            }
        }
        .onAppear {
            checkFirstLaunch()
        }
    }

    private func checkFirstLaunch() {
        let hasLaunched = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunched {
            showWelcome = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
}

// 欢迎界面
struct WelcomeView: View {
    @Binding var isShowing: Bool
    @State private var currentPage = 0

    let features = [
        (icon: "text.book.closed.fill", title: "90+ Medical Terms", description: "Comprehensive vocabulary covering all major medical fields", color: Color.blue),
        (icon: "brain.head.profile", title: "Smart Learning", description: "Spaced repetition algorithm for optimal retention", color: Color.purple),
        (icon: "sparkles", title: "AI Insights", description: "Get intelligent analysis with OpenAI, Claude, Qwen & Kimi", color: Color.orange)
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(0..<features.count, id: \.self) { index in
                        VStack(spacing: 32) {
                            Spacer()

                            Image(systemName: features[index].icon)
                                .font(.system(size: 80))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [features[index].color, features[index].color.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: features[index].color.opacity(0.3), radius: 20)

                            VStack(spacing: 12) {
                                Text(features[index].title)
                                    .font(.title)
                                    .bold()

                                Text(features[index].description)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 40)
                            }

                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .frame(height: 400)

                // 页面指示器和按钮
                VStack(spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(0..<features.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? Color.blue : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }

                    if currentPage == features.count - 1 {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isShowing = false
                            }
                        }) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 32)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.bottom, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: 600)
            .background(
                RoundedRectangle(cornerRadius: 32)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 30)
            )
            .padding(20)
        }
    }
}

#Preview {
    ContentView()
}
