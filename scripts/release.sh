#!/bin/bash
# MinTik 自动化发布脚本
set -euo pipefail

# 配置
VERSION=${1:-"v1.0.0-beta"}
DMG_FILE="dist/MinTik.dmg"
RELEASE_NOTES="RELEASE_NOTES.md"
NOTARY_VALIDATE=${NOTARY_VALIDATE:-true}

echo "🚀 MinTik 自动化发布流程"
echo "========================="
echo "版本: $VERSION"
echo ""

# 1. 检查 GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ 错误: 未安装 GitHub CLI"
    echo "请运行: brew install gh"
    exit 1
fi

# 2. 检查登录状态
echo "📋 检查 GitHub 登录状态..."
if ! gh auth status &> /dev/null; then
    echo "⚠️  未登录 GitHub，正在启动登录流程..."
    gh auth login
fi

# 3. 检查 DMG 文件
if [ ! -f "$DMG_FILE" ]; then
    echo "❌ 错误: 找不到 DMG 文件: $DMG_FILE"
    echo "请先运行: bash scripts/build-and-package.sh"
    exit 1
fi

DMG_SIZE=$(du -h "$DMG_FILE" | cut -f1)
echo "✅ 找到 DMG 文件: $DMG_FILE ($DMG_SIZE)"
echo ""

# 3.1 校验 DMG 是否已粘贴公证票据（Stapled）
if [ "$NOTARY_VALIDATE" = true ]; then
    if command -v xcrun &> /dev/null; then
        echo "🔍 校验 DMG 公证状态..."
        if xcrun stapler validate "$DMG_FILE" &> /dev/null; then
            echo "✅ DMG 已完成公证并成功粘贴票据"
        else
            echo "⚠️  警告: DMG 未检测到 stapled 票据。终端首次打开可能仍会提示无法验证开发者。"
            echo "   解决：在构建脚本设置 CODESIGN_IDENTITY 与 NOTARY_PROFILE 并重建。"
        fi
    fi
fi

# 4. 检查 Release Notes
if [ ! -f "$RELEASE_NOTES" ]; then
    echo "❌ 错误: 找不到 Release Notes: $RELEASE_NOTES"
    exit 1
fi

echo "✅ 找到 Release Notes"
echo ""

# 5. 创建 Git Tag
echo "🏷️  创建 Git Tag: $VERSION"
if git rev-parse "$VERSION" &> /dev/null; then
    echo "⚠️  Tag $VERSION 已存在，跳过创建"
else
    git tag -a "$VERSION" -m "Release $VERSION"
    git push origin "$VERSION"
    echo "✅ Tag 已推送到远程仓库"
fi
echo ""

# 6. 创建 GitHub Release
echo "📦 创建 GitHub Release..."
gh release create "$VERSION" \
    "$DMG_FILE" \
    --title "MinTik $VERSION" \
    --notes-file "$RELEASE_NOTES" \
    --prerelease

echo ""
echo "✨ 发布成功！"
echo ""
echo "📥 下载链接:"
echo "https://github.com/c0sc0s/MinTik/releases/download/$VERSION/MinTik.dmg"
echo ""
echo "🌐 Release 页面:"
echo "https://github.com/c0sc0s/MinTik/releases/tag/$VERSION"
