# Release 流程说明

## 快速开始

### 1. 准备发布文档

为新版本创建发布说明文档：

```bash
# 在 docs/release/ 目录下创建版本文档
# 文件名格式: v{major}.{minor}.{patch}.md
# 例如: v1.1.0.md
```

### 2. 执行发布

```bash
# 自动递增 patch 版本（例如 v1.0.0 -> v1.0.1）
sh scripts/release.sh

# 指定版本号
sh scripts/release.sh v1.1.0

# 自动递增 minor 版本（例如 v1.0.0 -> v1.1.0）
BUMP=minor sh scripts/release.sh

# 自动递增 major 版本（例如 v1.0.0 -> v2.0.0）
BUMP=major sh scripts/release.sh
```

## Release Notes 查找规则

脚本会按以下优先级查找发布说明：

1. **版本特定文档**（推荐）：`docs/release/{VERSION}.md`

   - 例如：`docs/release/v1.1.0.md`
   - 优点：每个版本有独立的详细说明

2. **默认文档**（备用）：`docs/RELEASE_NOTES.md`

   - 当找不到版本特定文档时使用
   - 适合快速发布或小版本更新

3. **如果都不存在**：脚本会报错并提示创建文档

## 发布文档模板

创建新版本文档时，可以参考以下模板：

```markdown
# MinTik v{VERSION} 更新说明

发布日期：YYYY-MM-DD

## 🎨 UI/UX 优化

- 功能 1
- 功能 2

## 🔔 新功能

- 功能 1
- 功能 2

## 🐛 Bug 修复

- 修复 1
- 修复 2

## 🔧 技术改进

- 改进 1
- 改进 2

## 📝 已知问题

- 问题 1

## 🎯 下一步计划

- 计划 1
```

## 环境变量

可以通过环境变量自定义发布行为：

```bash
# 跳过公证验证
NOTARY_VALIDATE=false sh scripts/release.sh

# 跳过 GitHub Pages 部署
DEPLOY_WEB=false sh scripts/release.sh

# 组合使用
BUMP=minor DEPLOY_WEB=false sh scripts/release.sh v1.2.0
```

## 完整发布流程

1. **开发完成**

   ```bash
   # 确保所有改动已提交
   git status
   git add .
   git commit -m "feat: 添加新功能"
   ```

2. **构建测试**

   ```bash
   # 本地构建并测试
   sh scripts/build-and-package.sh
   # 测试 DMG 安装
   ```

3. **准备发布文档**

   ```bash
   # 创建版本发布说明
   # 编辑 docs/release/v1.1.0.md
   ```

4. **执行发布**

   ```bash
   # 发布到 GitHub
   sh scripts/release.sh v1.1.0
   ```

5. **验证发布**
   - 检查 GitHub Release 页面
   - 验证 DMG 下载链接
   - 测试官网更新（如果启用了 DEPLOY_WEB）

## 示例

### 发布 v1.1.0 版本

```bash
# 1. 确保已创建 docs/release/v1.1.0.md
ls docs/release/v1.1.0.md

# 2. 执行发布
sh scripts/release.sh v1.1.0

# 脚本会：
# - 检测到 docs/release/v1.1.0.md
# - 显示前 20 行预览
# - 创建 Git tag v1.1.0
# - 上传 DMG 到 GitHub Release
# - 使用 v1.1.0.md 作为 Release Notes
# - 部署官网到 GitHub Pages
```

### 快速补丁发布

```bash
# 使用默认 RELEASE_NOTES.md
# 自动递增 patch 版本
sh scripts/release.sh
```

## 故障排除

### 问题：找不到 Release Notes

**错误信息：**

```
❌ 错误: 找不到 Release Notes
   请创建以下文件之一：
   - docs/release/v1.1.0.md (推荐)
   - docs/RELEASE_NOTES.md
```

**解决方案：**

1. 创建版本特定文档：`docs/release/v1.1.0.md`
2. 或创建默认文档：`docs/RELEASE_NOTES.md`

### 问题：Tag 已存在

**错误信息：**

```
⚠️  Tag v1.1.0 已存在，跳过创建
```

**解决方案：**

- 这是正常提示，脚本会继续执行
- 如需重新发布，先删除远程 tag：
  ```bash
  git push origin :refs/tags/v1.1.0
  git tag -d v1.1.0
  ```

## 相关文档

- [构建脚本说明](../scripts/build-and-package.sh)
- [版本发布历史](./release/)
- [变更日志](../CHANGELOG.md)
