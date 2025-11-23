#!/bin/bash
# MinTik 自动化发布脚本
set -euo pipefail

# 配置
VERSION_ARG=${1:-""}
BUMP=${BUMP:-patch}
DMG_FILE="dist/MinTik.dmg"
RELEASE_NOTES="docs/RELEASE_NOTES.md"
NOTARY_VALIDATE=${NOTARY_VALIDATE:-true}
DEPLOY_WEB=${DEPLOY_WEB:-true}

echo "🚀 MinTik 自动化发布流程"
echo "========================="
echo "版本: 未确定，准备计算..."
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

# 3. 计算版本（自动或使用入参）
if [ -n "$VERSION_ARG" ] && [ "$VERSION_ARG" != "auto" ]; then
    VERSION="$VERSION_ARG"
else
    LATEST_TAG=$(git tag -l 'v*' | sort -V | tail -n 1 || true)
    if [ -z "$LATEST_TAG" ]; then
        LATEST_TAG="v1.0.0"
    fi
    MAJOR=$(echo "${LATEST_TAG#v}" | cut -d. -f1)
    MINOR=$(echo "${LATEST_TAG#v}" | cut -d. -f2)
    PATCH=$(echo "${LATEST_TAG#v}" | cut -d. -f3)
    case "$BUMP" in
      major)
        MAJOR=$((MAJOR+1)); MINOR=0; PATCH=0 ;;
      minor)
        MINOR=$((MINOR+1)); PATCH=0 ;;
      *)
        PATCH=$((PATCH+1)) ;;
    esac
    VERSION="v${MAJOR}.${MINOR}.${PATCH}"
fi

APP_VERSION="${VERSION#v}"
echo "📦 将发布版本: $VERSION"
echo ""

# 4. 构建 DMG（若不存在则自动构建）
if [ ! -f "$DMG_FILE" ]; then
    echo "🛠️  未找到 DMG，开始构建..."
    bash scripts/build-and-package.sh MinTik "$APP_VERSION" dist
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

# 5. 检查 Release Notes
if [ ! -f "$RELEASE_NOTES" ]; then
    echo "❌ 错误: 找不到 Release Notes: $RELEASE_NOTES"
    exit 1
fi

echo "✅ 找到 Release Notes"
echo ""

# 6. 创建 Git Tag
echo "🏷️  创建 Git Tag: $VERSION"
if git rev-parse "$VERSION" &> /dev/null; then
    echo "⚠️  Tag $VERSION 已存在，跳过创建"
else
    git tag -a "$VERSION" -m "Release $VERSION"
    git push origin "$VERSION"
    echo "✅ Tag 已推送到远程仓库"
fi
echo ""

# 7. 创建 GitHub Release
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

# 8. 可选：发布官网到 GitHub Pages（web/ 目录）
if [ "$DEPLOY_WEB" = true ]; then
    echo "🌐 部署官网到 GitHub Pages..."
    REPO_NAME_WITH_OWNER=$(gh repo view --json nameWithOwner -q .nameWithOwner || echo "")
    if [ -n "$REPO_NAME_WITH_OWNER" ]; then
        git subtree split --prefix web -b gh-pages-tmp >/dev/null 2>&1 || true
        git push -f origin gh-pages-tmp:gh-pages >/dev/null 2>&1 || true
        git branch -D gh-pages-tmp >/dev/null 2>&1 || true
        OWNER=$(echo "$REPO_NAME_WITH_OWNER" | cut -d'/' -f1)
        REPO=$(echo "$REPO_NAME_WITH_OWNER" | cut -d'/' -f2)
        echo "✅ 官网已发布：https://$OWNER.github.io/$REPO/"
        echo "   提示：下载按钮将自动使用最新 Release 资产（DMG）"
    else
        echo "⚠️  未能确定仓库信息，跳过 Pages 部署"
    fi
fi
