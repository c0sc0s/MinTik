# MinTik

<div align="center">

**一个以 SwiftUI + AppKit 打造的 macOS 专注提醒应用**

[![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)](https://www.apple.com/macos)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

</div>

MinTik 是一款极简的 macOS 专注时间管理工具，通过实时监测键鼠活跃度，帮助你掌握工作节奏，适时提醒休息。提供优雅的圆角卡片界面与状态栏常驻入口，让专注管理触手可及。

## 功能亮点

- **实时专注计时**：每秒读取系统输入事件并累计工作秒数，界面以 00:28 样式显示。
- **分钟热力图**：一小时 60 个量化方块，深浅代表该分钟的活跃强度。
- **状态栏驻留**：红色关闭按钮不再退出，而是把窗口隐藏到托盘，那里会显示「Xm」的活跃分钟数，颜色含义：
  - 白色：未超出阈值；
  - 红色：超过提醒阈值（当前默认 1 分钟，方便测试）；
  - 黄色：处于暂停状态；
  - 灰色：长时间无输入（Idle）。
- **系统通知提醒**：抵达专注阈值即弹出「该休息一下啦」通知；若权限被关闭，卡片顶部会提示并可一键跳转到系统设置开启。
- **一键恢复窗口**：点击状态栏文案即可打开或隐藏主窗口。
- **快速设置**：在 `Settings` 中实时调节专注时长（1-90 分钟）与休息重置时间（60-600 秒）。
- **纯暗色 UI**：采用深色渐变、柔和阴影及定制圆角，无边框拖拽交互。

## 运行要求

- macOS 12+（Monterey）
- Xcode 15 / Swift 5.9+
- 第一次运行需授权「辅助功能」，用于检测键鼠活跃度。

## 快速开始

### 安装与运行

1. 克隆仓库：
```bash
git clone https://github.com/yourusername/MinTik.git
cd MinTik
```

2. 使用 Swift Package Manager 运行：
```bash
swift run
```

或在 Xcode 中打开 `Package.swift`，选择 `RestApp` Scheme 直接运行 (`⌘R`)。

### 首次使用

首次运行需要授权「辅助功能」权限，用于检测键盘和鼠标活跃度：
1. 系统设置 → 隐私与安全性 → 辅助功能
2. 添加 MinTik 并启用权限
3. 重启应用

## 自定义

- 修改 `AppConfig` 以设置默认专注阈值、活跃/休息判定。
- 调整 `FocusDashboardView` 的颜色与阴影，获得不同的视觉风格。
- 状态栏文本由 `Notification.Name.restAppStatusUpdate` 驱动，如需改造菜单或图标，可在 `AppDelegate` 中扩展。

欢迎继续拓展，例如添加提醒通知、历史统计或导出功能。

## 技术栈

- **SwiftUI**: 现代化的声明式 UI 框架
- **AppKit**: macOS 原生菜单栏与窗口管理
- **Swift Package Manager**: 项目依赖管理
- **UserDefaults**: 本地配置持久化
- **NSEvent**: 系统事件监听

## 项目结构

```
MinTik/
├── Sources/
│   └── RestApp/          # 主要源代码
├── resources/            # 资源文件
├── scripts/              # 构建脚本
├── Package.swift         # SPM 配置文件
├── README.md             # 项目说明
└── LICENSE               # MIT 开源协议
```

## 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

## 致谢

感谢所有为这个项目做出贡献的开发者！

