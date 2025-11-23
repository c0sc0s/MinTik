# MinTik v1.0.0-beta 首个公测版本 🎉

## ✨ 核心功能

### 🎯 智能工作追踪
- **自动记录**：基于键盘/鼠标活动自动追踪工作时间
- **疲劳检测**：智能识别连续高强度工作，及时提醒休息
- **可视化热力图**：60分钟活动矩阵，直观展示工作节奏

### 💡 健康守护
- **休息提醒**：可自定义疲劳阈值和休息策略
- **静默运行**：菜单栏应用，不打扰工作流
- **数据本地**：所有数据仅存储在本地，隐私至上

### 🎨 极简设计
- **原生 macOS 体验**：SwiftUI 打造，轻量高效
- **暗色模式**：现代化 UI 设计
- **一目了然**：专注仪表盘、统计视图、数据仓库三大核心界面

## 📦 安装说明

1. 下载 `MinTik.dmg`
2. 打开 DMG 文件
3. 将 MinTik 拖拽到 Applications 文件夹
4. 首次运行时授予必要权限（通知、辅助功能）

## ⚠️ 安装注意事项

如果您在打开 MinTik 时看到 "无法验证开发者" 或 "来自未确认开发者的应用" 的提示，请按照以下步骤操作：
1. 按住 `Control` 键并点击 MinTik 应用图标
2. 在弹出的菜单中选择 "打开"
3. 在新弹出的窗口中再次点击 "打开"

这样就可以正常运行 MinTik 了。如果您希望完全移除这个提示，可以在终端中运行以下命令：
```bash
sudo xattr -dr com.apple.quarantine /Applications/MinTik.app
```

### English Instructions for Security Prompt:

#### Method 1: Allow through System Settings (Recommended)
1. Try to open MinTik directly, and you will see the "Developer Cannot be Verified" alert
2. Open "System Settings" → "Privacy & Security"
3. Scroll down to the "Security" section at the bottom of the page, where you will see a prompt for MinTik
4. Click the "Open Anyway" button
5. Click "Open" again in the new window that pops up

#### Method 2: Open with Control+click
If Method 1 doesn't work, you can try these steps:
1. Press and hold the `Control` key while clicking the MinTik app icon
2. Select "Open" from the menu that appears
3. Click "Open" again in the new window that pops up

#### Method 3: Permanently remove quarantine attribute
If you want to remove this alert permanently, you can run this command in Terminal:
```bash
sudo xattr -dr com.apple.quarantine /Applications/MinTik.app
```

#### Special Note for macOS Ventura and later
In macOS Ventura and later versions, the "Allow apps downloaded from: Anywhere" option is hidden by default. If you encounter issues, you can enable this option with the following terminal command:
```bash
sudo spctl --master-disable
```
After enabling it, you will see the "Allow apps downloaded from: Anywhere" option in System Settings → Privacy & Security → General.

## ⚙️ 系统要求

- macOS Monterey 12.0 或更高版本
- M1/M2/Intel 芯片均支持

## 🐛 已知问题

- 首次启动需要手动授予辅助功能权限
- 暂不支持多显示器独立追踪

## 📝 反馈渠道

如遇到问题或有功能建议，欢迎通过 GitHub Issues 反馈。

---

**重要提示**：本版本为 Beta 测试版，部分功能仍在持续优化中。
