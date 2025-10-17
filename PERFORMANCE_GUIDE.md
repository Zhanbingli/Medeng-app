# 🚀 Medeng 性能优化指南

## 快速参考

### 核心优化原则

1. **缓存优先** - 避免重复计算
2. **懒加载** - 只在需要时计算
3. **及时失效** - 数据变更时更新缓存
4. **测量优化** - 先测量再优化

---

## 📊 性能监控命令

### 构建时间分析
```bash
# Xcode中启用Build Time Analyzer
# Product → Scheme → Edit Scheme → Build → Build Options
# 勾选 "Time Build Commands"
```

### Instruments快速启动
```bash
# Time Profiler
cmd + I → Time Profiler

# Allocations
cmd + I → Allocations

# Core Animation
cmd + I → Core Animation → Debug Options → Color Offscreen-Rendered
```

---

## 🎯 常见性能问题解决方案

### 问题1: 列表滚动卡顿

**症状**: 滚动时掉帧,FPS < 50

**解决方案**:
```swift
// ❌ 避免
ForEach(vocabularyManager.allTerms.filter { ... }) { ... }

// ✅ 推荐
@State private var filteredTerms: [MedicalTerm] = []
ForEach(filteredTerms) { ... }
    .onAppear { filteredTerms = ... }
```

### 问题2: 搜索输入延迟

**症状**: 输入文字后>200ms才显示结果

**解决方案**:
```swift
// ✅ 使用缓存
var filteredTerms: [MedicalTerm] {
    if let cached = cachedFilteredTerms {
        return cached
    }
    let result = performFiltering()
    cachedFilteredTerms = result
    return result
}

// ✅ 添加debounce(未来)
@Published var searchText = ""
var debouncedSearch: String {
    // 实施300ms防抖
}
```

### 问题3: 视图重复渲染

**症状**: Instruments显示大量重复的body调用

**解决方案**:
```swift
// ❌ 避免在body中计算
var body: some View {
    let items = expensiveCalculation()  // 每次渲染都计算
    ForEach(items) { ... }
}

// ✅ 使用@State缓存
@State private var items: [Item] = []
var body: some View {
    ForEach(items) { ... }
        .task { items = await fetchItems() }
}
```

### 问题4: 动画不流畅

**症状**: 动画掉帧,不够smooth

**解决方案**:
```swift
// ❌ 避免
.animation(.linear(duration: 0.3))

// ✅ 推荐
.animation(.spring(response: 0.3, dampingFraction: 0.7))

// ✅ 明确动画值
.animation(.spring(), value: offset)
```

---

## 💡 性能优化技巧

### 1. 计算属性优化

```swift
// ❌ 每次都计算
var filteredTerms: [MedicalTerm] {
    allTerms.filter { term in
        // 复杂过滤逻辑
    }
}

// ✅ 带缓存
private var cached: [MedicalTerm]?
var filteredTerms: [MedicalTerm] {
    if let c = cached { return c }
    let result = allTerms.filter { ... }
    cached = result
    return result
}
```

### 2. 列表性能

```swift
// ✅ 使用LazyVStack
ScrollView {
    LazyVStack {  // 懒加载
        ForEach(items, id: \.id) { item in
            ItemRow(item: item)
        }
    }
}

// ✅ 使用合适的id
ForEach(items, id: \.id) { ... }  // 稳定的id
// 而非
ForEach(items, id: \.hashValue) { ... }  // 可能变化
```

### 3. 图片优化

```swift
// ✅ 异步加载
AsyncImage(url: url) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
.frame(width: 100, height: 100)  // 指定大小
```

### 4. 网络请求

```swift
// ✅ 使用Task管理
.task {
    do {
        let data = try await fetchData()
        await MainActor.run {
            self.items = data
        }
    } catch {
        // 错误处理
    }
}
```

---

## 🔍 性能测试检查项

### 启动性能
- [ ] 冷启动 < 2秒
- [ ] 热启动 < 0.5秒
- [ ] 首屏渲染 < 1秒

### 运行时性能
- [ ] 列表滚动 60 FPS
- [ ] 搜索响应 < 100ms
- [ ] 页面切换 < 200ms
- [ ] 动画流畅度 60 FPS

### 内存占用
- [ ] 空闲状态 < 60MB
- [ ] 使用中 < 100MB
- [ ] 峰值 < 150MB
- [ ] 无内存泄漏

### 电池影响
- [ ] CPU使用 < 10% (空闲)
- [ ] CPU使用 < 30% (活跃)
- [ ] 无后台活动消耗

---

## 📱 设备适配建议

### iPhone SE (小屏)
```swift
// ✅ 动态布局
GeometryReader { geometry in
    if geometry.size.height < 700 {
        CompactLayout()
    } else {
        StandardLayout()
    }
}
```

### iPhone Pro Max (大屏)
```swift
// ✅ 利用额外空间
HStack {
    if horizontalSizeClass == .regular {
        SidebarView()
    }
    MainContentView()
}
```

### iPad
```swift
// ✅ 分栏布局
NavigationSplitView {
    SidebarView()
} detail: {
    DetailView()
}
```

---

## 🛠️ 调试技巧

### 1. 打印渲染次数
```swift
var body: some View {
    let _ = Self._printChanges()  // Xcode 15+
    // 或
    let _ = print("Body rendered")

    return content
}
```

### 2. 测量执行时间
```swift
func measure<T>(_ label: String, _ block: () -> T) -> T {
    let start = Date()
    let result = block()
    print("\(label): \(Date().timeIntervalSince(start) * 1000)ms")
    return result
}

// 使用
let filtered = measure("Filter") {
    allTerms.filter { ... }
}
```

### 3. 内存监控
```swift
// 查看内存使用
#if DEBUG
func reportMemory() {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }
    if kerr == KERN_SUCCESS {
        print("Memory: \(Double(info.resident_size) / 1024 / 1024) MB")
    }
}
#endif
```

---

## 📚 推荐阅读

### Apple官方文档
- [Optimizing Your SwiftUI Views](https://developer.apple.com/documentation/swiftui)
- [Improving Performance](https://developer.apple.com/documentation/xcode/improving-app-performance)
- [Energy Efficiency Guide](https://developer.apple.com/library/content/documentation/Performance/Conceptual/EnergyGuide-iOS/)

### 最佳实践
- 使用Instruments定期分析
- 在真机上测试性能
- 关注Core Animation图层
- 监控网络请求数量

---

## 🎯 性能目标

### 必须达成 (P0)
- ✅ 60 FPS 滚动
- ✅ < 100ms 搜索响应
- ✅ < 2s 冷启动
- ✅ 无内存泄漏

### 应该达成 (P1)
- ✅ < 50MB 空闲内存
- ✅ < 200ms 页面切换
- ✅ < 1s 首屏渲染

### 期望达成 (P2)
- ⏳ < 1s 冷启动
- ⏳ < 50ms 搜索响应
- ⏳ 后台0功耗

---

**版本**: 1.2.0
**更新日期**: 2025-10-17
**维护者**: Development Team
