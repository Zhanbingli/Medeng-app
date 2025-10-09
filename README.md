# Medeng - Medical English Learning App

一个专为医学英语学习设计的iOS应用，提供交互式词汇学习、智能复习和AI助手功能。

## ✨ 主要功能

### 1. 📚 医学词汇库
- **8个初始医学术语**涵盖心脏科、神经科、呼吸科等多个领域
- 详细的词汇信息：
  - 英文术语和音标
  - 中文翻译
  - 完整定义
  - 词根词缀解析
  - 临床例句
  - 相关术语推荐

### 2. 🎯 智能学习系统
- **间隔重复算法（Spaced Repetition）**
  - 根据掌握程度自动调整复习间隔
  - 5级掌握度追踪（0-5）
  - 智能提醒待复习词汇

- **多种学习模式**
  - 全部词汇学习
  - 待复习词汇优先
  - 收藏词汇专项复习

### 3. 📖 交互式卡片学习
- 精美的翻卡动画效果
- 即时反馈机制（Hard/Good评分）
- 实时进度追踪
- 详细的学习统计

### 4. 🤖 AI学习助手
- **智能对话功能**
  - 术语解释与深度分析
  - 词根词缀拆解
  - 临床场景模拟
  - 自动生成测验题

- **快捷操作**
  - 一键获取术语解释
  - 快速生成测试题
  - 词源分析
  - 例句生成

- **API配置**
  - 支持OpenAI GPT-4集成
  - 可配置API密钥
  - 包含模拟响应（无需API即可体验）

### 5. 📊 学习进度追踪
- **统计仪表板**
  - 总词汇量、已学习数量、掌握数量
  - 整体正确率统计
  - 学习环形进度图

- **分类分析**
  - 按医学类别显示学习进度
  - 每个类别的完成度可视化
  - 识别薄弱环节

- **学习打卡**
  - 每日学习记录
  - 连续打卡天数追踪
  - 学习历史查看

- **近期活动**
  - 最近学习的词汇
  - 复习次数和正确率
  - 待复习提醒

### 6. 🔍 高级搜索与筛选
- 全文搜索（术语、定义、中文翻译）
- 按医学类别筛选
- 按难度等级筛选
- 收藏功能

## 🏗️ 技术架构

### 核心技术
- **SwiftUI** - 现代化的声明式UI框架
- **Combine** - 响应式编程
- **MVVM架构** - 清晰的代码组织
- **UserDefaults** - 本地数据持久化

### 数据模型
```swift
// 医学术语模型
- MedicalTerm: 包含术语的所有信息
- StudyProgress: 学习进度追踪
- MedicalCategory: 9大医学分类
- DifficultyLevel: 初级/中级/高级

// 管理器
- VocabularyManager: 词汇和进度管理单例
- ChatManager: AI对话管理
```

### 视图组件
```
ContentView (主导航)
├── VocabularyListView (词汇列表)
│   ├── FilterView (筛选器)
│   └── TermDetailView (词汇详情)
├── FlashcardView (卡片学习)
│   └── StudyOptionsView (学习选项)
├── AIAssistantView (AI助手)
│   └── APISettingsView (API设置)
└── StudyProgressView (学习进度)
```

## 🚀 开始使用

### 环境要求
- Xcode 16.0+
- iOS 17.0+（支持iOS 17.0 - iOS 18.4）
- Swift 5.0+

### 运行步骤

#### 在模拟器上运行
1. 使用Xcode打开 `Medeng.xcodeproj`
2. 选择iOS模拟器（iPhone 16或其他）
3. 点击运行按钮（⌘R）

#### 在真机上运行
1. 使用Lightning/USB-C线连接iPhone到Mac
2. 在Xcode中打开 `Medeng.xcodeproj`
3. 选择你的iPhone作为目标设备
4. 如果是首次开发，需要配置签名：
   - 点击项目 → Medeng target → Signing & Capabilities
   - 选择你的Apple ID账号（Team）
   - Xcode会自动管理签名
5. 点击运行按钮（⌘R）
6. 首次安装时，在iPhone上：
   - 打开 设置 → 通用 → VPN与设备管理
   - 信任你的开发者证书
7. 返回主屏幕，打开Medeng app

### 配置AI助手（可选）
1. 打开app，进入"AI Assistant"标签
2. 点击右上角设置图标⚙️
3. 访问 [OpenAI API Keys](https://platform.openai.com/api-keys)
4. 创建并复制API密钥
5. 粘贴到app的API设置中
6. 保存后即可使用完整AI功能

**注意**：即使不配置API，app也提供了智能模拟响应，可以体验基本功能。

## 📱 使用指南

### 学习词汇
1. 在"Vocabulary"标签浏览所有术语
2. 点击任意术语查看详细信息
3. 点击⭐️收藏重要术语

### 卡片学习
1. 切换到"Study"标签
2. 选择学习模式（全部/待复习/收藏）
3. 阅读术语后点击"Show Answer"查看答案
4. 根据掌握程度选择"Hard"或"Good"
5. 系统自动记录并安排下次复习时间

### AI助手互动
1. 进入"AI Assistant"标签
2. 使用快捷按钮或直接输入问题
3. 支持的问题类型：
   - "解释术语hypertension"
   - "测试我5个心脏科术语"
   - "cardiology的词源是什么？"
   - "用myocardial infarction造句"

### 查看进度
1. 打开"Progress"标签
2. 查看总体统计和学习环形图
3. 分析各类别掌握情况
4. 查看待复习提醒

## 🎨 特色设计

### 用户体验
- 直观的标签式导航
- 流畅的动画过渡
- 清晰的视觉层次
- 响应式布局适配

### 颜色编码
- 🔵 蓝色：一般信息
- 🟢 绿色：正确/已掌握
- 🟠 橙色：中等/待改进
- 🔴 红色：错误/困难
- 🟣 紫色：相关术语

### 图标系统
- 每个医学类别有独特图标和颜色
- SF Symbols图标系统
- 一致的视觉语言

## 📈 未来扩展计划

### 短期目标
- [ ] 更多医学术语（目标1000+）
- [ ] 语音朗读功能（AVSpeech）
- [ ] 发音练习和评分
- [ ] iCloud同步
- [ ] 深色模式优化

### 中期目标
- [ ] 真实AI API集成（GPT-4）
- [ ] 病例阅读模块
- [ ] 医学缩写学习
- [ ] 分享学习成果
- [ ] 排行榜和成就系统

### 长期目标
- [ ] 多语言支持
- [ ] Apple Watch配套应用
- [ ] 社区学习功能
- [ ] 医学文献阅读器
- [ ] 专业考试备考模式（USMLE, IELTS医学等）

## 🛠️ 数据管理

### 本地存储
- 使用UserDefaults存储所有学习数据
- 自动保存进度
- 支持重置功能

### 数据导出（计划中）
- JSON格式导出
- CSV学习报告
- PDF学习证书

## 🤝 贡献指南

欢迎提交问题和功能建议！

### 如何添加新术语
编辑 `VocabularyManager.swift` 中的 `loadSampleData()` 方法：

```swift
MedicalTerm(
    term: "Your Term",
    pronunciation: "/pronunciation/",
    definition: "Definition here",
    chineseTranslation: "中文翻译",
    etymology: "词根词缀分析",
    example: "Example sentence",
    category: .cardiology,  // 选择合适类别
    difficulty: .intermediate,
    relatedTerms: ["Term1", "Term2"]
)
```

## 📄 许可证

此项目为教育目的创建。

## 👨‍💻 作者

创建于 2025-10-08

---

**学习医学英语，从Medeng开始！** 💉📚🩺
