# 📱 真机部署指南

## ✅ 已完成的配置

- ✅ 部署目标已设置为 **iOS 17.0**
- ✅ 支持iOS 17.0 - iOS 18.4系统
- ✅ 你的iPhone（iOS 18.3.1）完全兼容
- ✅ 项目已成功编译

## 🚀 部署到真机的步骤

### 1️⃣ 连接设备
```bash
# 使用数据线连接iPhone到Mac
# 确保iPhone已解锁并信任电脑
```

### 2️⃣ 在Xcode中打开项目
```bash
cd /Users/lizhanbing12/learn_project/medical_english/Medeng
open Medeng.xcodeproj
```

### 3️⃣ 选择你的iPhone
- 在Xcode顶部工具栏，点击设备选择器
- 选择你的iPhone设备（应该显示为 "iPhone (18.3.1)"）

### 4️⃣ 配置代码签名

#### 如果你有Apple开发者账号：
1. 点击左侧项目导航中的 **Medeng** 项目
2. 选择 **Medeng** target
3. 点击 **Signing & Capabilities** 标签
4. 勾选 **Automatically manage signing**
5. 在 **Team** 下拉菜单中选择你的团队/账号

#### 如果你没有付费开发者账号（免费开发）：
1. 同样进入 **Signing & Capabilities**
2. 使用你的Apple ID登录（Xcode → Settings → Accounts → 添加Apple ID）
3. 选择你的个人团队（通常显示为 "Your Name (Personal Team)"）
4. **重要**：可能需要修改Bundle Identifier为唯一的ID：
   - 将 `lizhanbing.Medeng` 改为 `com.yourname.Medeng`

### 5️⃣ 构建并运行
```bash
# 点击运行按钮（▶️）或按 ⌘R
```

### 6️⃣ 首次运行 - 信任开发者

第一次安装时，iPhone会显示"未受信任的开发者"：

1. 在iPhone上打开：**设置** → **通用** → **VPN与设备管理**
2. 找到你的开发者证书（显示为你的Apple ID邮箱）
3. 点击 **信任 "xxx@xxx.com"**
4. 在弹出的确认对话框中点击 **信任**

### 7️⃣ 启动App
返回iPhone主屏幕，点击 **Medeng** 图标启动app！

## 🛠️ 故障排查

### 问题：找不到设备
**解决方案**：
- 确保iPhone已解锁
- 重新插拔数据线
- 在iPhone上点击"信任此电脑"
- 重启Xcode

### 问题：签名失败
**解决方案**：
- 检查是否登录了Apple ID（Xcode → Settings → Accounts）
- 修改Bundle Identifier为唯一值
- 确保选择了正确的Team

### 问题：部署目标不匹配
**解决方案**：
- 已修复！现在支持iOS 17.0+
- 你的iOS 18.3.1完全兼容

### 问题：App安装后无法打开
**解决方案**：
- 按照第6步信任开发者证书
- 检查 设置 → 隐私与安全 → 开发者模式（iOS 16+需要）

## 📊 验证部署

成功部署后，你应该能看到：

✅ 4个标签页：Vocabulary / Study / AI Assistant / Progress
✅ 8个示例医学术语
✅ 流畅的界面动画
✅ 所有功能正常运行

## 🔄 更新App

每次修改代码后：
```bash
# 在Xcode中直接点击运行按钮（⌘R）
# Xcode会自动重新编译并安装到iPhone
```

## 💡 开发者模式（iOS 16+）

如果你的iPhone运行iOS 16或更新版本，可能需要启用开发者模式：

1. 尝试首次安装时，系统会提示启用开发者模式
2. 或手动启用：**设置** → **隐私与安全** → **开发者模式** → 开启
3. iPhone会重启
4. 重启后再次运行Xcode部署

## 🎯 免费账号限制

使用免费Apple ID开发的限制：
- ✅ 可以在自己的设备上测试
- ✅ App可运行7天（之后需重新安装）
- ⚠️ 不能上传到App Store
- ⚠️ 最多3台设备
- ⚠️ 某些功能受限（如推送通知、App Groups）

**本app不受这些限制影响，可以正常使用所有功能！**

## 📞 需要帮助？

如果遇到问题：
1. 检查Xcode的错误日志（⌘9打开报告导航器）
2. 确保iPhone和Mac在同一WiFi（可选，但有助于调试）
3. 尝试清理项目：Xcode → Product → Clean Build Folder（⇧⌘K）

---

**享受你的医学英语学习之旅！** 📚💉🩺
