# GitHub Pages 部署指南

## 🚀 概述
本文档指导如何将 MkDocs 文档站点自动部署到 GitHub Pages。通过 GitHub Actions 工作流，每次推送到 `main` 分支时自动构建并部署文档。

---

## 📋 前置条件

### 1. 项目结构要求
```
erpnext_china_opc/
├── docs/                    # MkDocs 文档源文件
│   ├── index.md
│   ├── erpnext/
│   │   ├── 01_Introduction.md
│   │   ├── 02_Quick_Start.md
│   │   └── ...
│   └── ...
├── mkdocs.yml              # MkDocs 配置文件
├── .github/workflows/      # GitHub Actions 工作流
└── requirements.txt        # Python 依赖
```

### 2. MkDocs 配置检查
确保 `mkdocs.yml` 包含正确的 `site_url` 配置：
```yaml
site_name: ERPNext 中国版文档
site_url: https://kingpy-tech.github.io/erpnext_china_opc/
repo_url: https://github.com/kingpy-tech/erpnext_china_opc
```

### 3. GitHub 仓库设置
1. 访问仓库 Settings → Pages
2. 设置 Source: **GitHub Actions**
3. 确保仓库是公开的（GitHub Pages 免费版要求）

---

## 🔧 GitHub Actions 工作流配置

### 1. 创建工作流文件
创建文件：`.github/workflows/deploy-docs.yml`

```yaml
name: Deploy MkDocs to GitHub Pages

on:
  push:
    branches:
      - main
    paths:
      - 'docs/**'
      - 'mkdocs.yml'
      - '.github/workflows/deploy-docs.yml'
  workflow_dispatch:  # 允许手动触发

permissions:
  contents: write
  pages: write
  id-token: write

concurrency:
  group: "pages"
  cancel-in-progress: false

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'
          cache: 'pip'

      - name: Install dependencies
        run: |
          pip install mkdocs mkdocs-material
          pip install -r requirements.txt  # 如果有额外依赖

      - name: Build documentation
        run: mkdocs build --strict

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./site

  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

### 2. 工作流说明

| 步骤 | 说明 |
|------|------|
| **触发条件** | 推送到 main 分支，且 docs/ 目录或 mkdocs.yml 有变更 |
| **Python 环境** | 使用 Python 3.11，启用 pip 缓存加速 |
| **依赖安装** | 安装 mkdocs 和 mkdocs-material 主题 |
| **构建文档** | 执行 `mkdocs build` 生成静态站点到 `site/` 目录 |
| **上传产物** | 将构建产物上传到 GitHub Pages |
| **部署** | 自动部署到 GitHub Pages 环境 |

---

## 🛠️ 高级配置选项

### 1. 自定义域名（可选）
如果需要使用自定义域名：

1. **配置 CNAME 文件**：
   ```bash
   echo "docs.yourdomain.com" > docs/CNAME
   ```

2. **更新 mkdocs.yml**：
   ```yaml
   site_url: https://docs.yourdomain.com/
   ```

3. **DNS 配置**：
   - 添加 CNAME 记录：`docs → kingpy-tech.github.io`
   - 或在仓库 Settings → Pages 中设置 Custom domain

### 2. 多版本文档（可选）
如果需要版本化文档：

```yaml
# mkdocs.yml 添加插件
plugins:
  - mike:
      version_selector: true
      canonical_version: latest

# 工作流中添加版本部署步骤
- name: Deploy version
  run: |
    mike deploy --push --update-aliases 1.0 latest
    mike set-default --push latest
```

### 3. 预览构建（Pull Request）
添加 PR 预览工作流：

```yaml
name: Preview Documentation

on:
  pull_request:
    branches:
      - main
    paths:
      - 'docs/**'
      - 'mkdocs.yml'

jobs:
  preview:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install mkdocs mkdocs-material

      - name: Build docs
        run: mkdocs build

      - name: Upload preview
        uses: actions/upload-artifact@v4
        with:
          name: docs-preview
          path: ./site
```

---

## 🧪 本地测试

### 1. 本地构建测试
```bash
# 安装依赖
pip install mkdocs mkdocs-material

# 本地预览
mkdocs serve

# 构建测试
mkdocs build --strict
```

### 2. 验证构建产物
```bash
# 检查生成的站点结构
ls -la site/

# 验证 HTML 文件
find site/ -name "*.html" | head -5

# 检查链接有效性（需要安装 linkchecker）
pip install linkchecker
linkchecker site/index.html
```

---

## 🔍 故障排除

### 常见问题及解决方案

#### 1. 构建失败：主题未找到
**错误信息**：`ERROR   -  Config value 'theme': Unrecognised theme name 'material'`
**解决方案**：
```bash
pip install mkdocs-material
```

#### 2. 部署失败：权限不足
**错误信息**：`Permission denied`
**解决方案**：
- 检查仓库 Settings → Actions → General → Workflow permissions
- 设置为 "Read and write permissions"

#### 3. 页面 404：路径错误
**错误信息**：GitHub Pages 返回 404
**解决方案**：
- 检查 `mkdocs.yml` 中的 `site_url`
- 确保构建产物在 `site/` 目录
- 检查 GitHub Pages 设置中的 Source

#### 4. 样式丢失：CSS/JS 加载失败
**解决方案**：
- 检查 `mkdocs.yml` 中的 `site_url` 是否以 `/` 结尾
- 验证相对路径是否正确
- 检查浏览器控制台错误信息

---

## 📊 监控与维护

### 1. 工作流状态监控
- 访问仓库 Actions 标签页查看运行状态
- 设置通知：Settings → Notifications → Actions

### 2. 构建历史清理
GitHub Actions 会占用存储空间，建议定期清理：
```yaml
# 在工作流中添加清理步骤
- name: Cleanup old artifacts
  if: always()
  run: |
    gh api repos/${{ github.repository }}/actions/artifacts \
      --jq '.artifacts[] | select(.expired == false) | .id' \
      | xargs -I {} gh api repos/${{ github.repository }}/actions/artifacts/{} -X DELETE
```

### 3. 性能优化建议
1. **缓存依赖**：工作流中启用 pip 缓存
2. **增量构建**：只构建变更的文件（需要插件支持）
3. **并行构建**：大型文档可拆分构建任务

---

## 🔗 相关资源

### 官方文档
- [MkDocs 文档](https://www.mkdocs.org/)
- [MkDocs Material 主题](https://squidfunk.github.io/mkdocs-material/)
- [GitHub Pages 文档](https://docs.github.com/en/pages)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

### 实用插件
```yaml
plugins:
  - search  # 内置搜索
  - mkdocs-jupyter  # Jupyter Notebook 支持
  - mkdocs-awesome-pages-plugin  # 自动页面排序
  - mkdocs-minify-plugin  # 压缩 HTML/CSS/JS
  - mkdocs-redirects  # 页面重定向
```

### 示例配置
完整的 `mkdocs.yml` 示例：
```yaml
site_name: ERPNext 中国版文档
site_url: https://kingpy-tech.github.io/erpnext_china_opc/
repo_url: https://github.com/kingpy-tech/erpnext_china_opc
repo_name: kingpy-tech/erpnext_china_opc

theme:
  name: material
  palette:
    - scheme: default
      primary: teal
      accent: deep orange
  features:
    - navigation.tabs
    - navigation.sections
    - toc.integrate
    - search.suggest
    - search.highlight

markdown_extensions:
  - admonition
  - codehilite
  - toc:
      permalink: true
  - pymdownx.superfences
  - pymdownx.tabbed:
      alternate_style: true

nav:
  - 首页: index.md
  - ERPNext 指南:
    - 简介: erpnext/01_Introduction.md
    - 快速开始: erpnext/02_Quick_Start.md
    - 工作区简化: erpnext/06_Workspace_Simplification.md
  - 部署指南:
    - Docker 部署: deployment/01_Docker_Deployment.md
    - 生产环境: deployment/02_Production_Setup.md

extra:
  analytics:
    provider: google
    property: G-XXXXXXXXXX
```

---

## 🚀 快速开始清单

### 首次部署步骤
1. [ ] 确认 `mkdocs.yml` 配置正确
2. [ ] 创建 `.github/workflows/deploy-docs.yml`
3. [ ] 提交并推送到 main 分支
4. [ ] 检查 Actions 标签页中的工作流状态
5. [ ] 访问 `https://kingpy-tech.github.io/erpnext_china_opc/`

### 日常更新步骤
1. [ ] 更新 `docs/` 目录中的 Markdown 文件
2. [ ] 提交更改到 main 分支
3. [ ] 等待 GitHub Actions 自动构建部署
4. [ ] 验证更新内容已发布

### 验证清单
- [ ] 本地 `mkdocs serve` 运行正常
- [ ] 本地 `mkdocs build` 无错误
- [ ] GitHub Actions 工作流执行成功
- [ ] GitHub Pages 站点可正常访问
- [ ] 所有链接有效
- [ ] 搜索功能正常
- [ ] 移动端适配良好

---
*文档版本: v1.0*
*最后更新: 2026-03-16*
*适用项目: erpnext_china_opc*