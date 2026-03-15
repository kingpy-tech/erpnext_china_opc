# 贡献指南

> 欢迎加入 ERPNext 中国本土化项目！本文档将指导你如何参与贡献。

---

## 🎯 贡献前必读

### 1. 项目定位
- **目标**：让 ERPNext 真正适配中国企业需求，填补开源 ERP 在中国的“最后一公里”
- **范围**：财务合规、界面本地化、业务习惯适配、国内生态集成
- **原则**：拥抱 `Frappe First`，优先使用官方扩展机制，避免硬改核心代码

### 2. 贡献者类型
| 类型 | 适合人群 | 贡献方式 |
|------|----------|----------|
| **代码贡献者** | 开发者、学生、技术爱好者 | 提交 PR、修复 bug、开发新功能 |
| **文档贡献者** | 技术写作者、实施顾问 | 完善文档、翻译、教程撰写 |
| **测试贡献者** | QA、用户体验设计师 | 测试反馈、用户体验优化 |
| **社区贡献者** | 布道师、运营人员 | 回答问题、推广项目、生态连接 |

### 3. 行为准则
- **尊重**：尊重所有贡献者，无论经验高低
- **专业**：技术讨论对事不对人
- **耐心**：开源协作需要时间，请保持耐心
- **透明**：所有讨论在公开渠道进行（GitHub Issues/PRs）

---

## 🔄 贡献流程

### 1. Fork 仓库
1. 访问 https://github.com/kingpy-tech/erpnext_china_opc
2. 点击右上角 **Fork** 按钮
3. 等待 Fork 完成，你将拥有自己的副本

### 2. 本地开发环境准备
```bash
# 克隆你的 Fork
git clone https://github.com/你的用户名/erpnext_china_opc.git
cd erpnext_china_opc

# 添加上游仓库（便于同步更新）
git remote add upstream https://github.com/kingpy-tech/erpnext_china_opc.git

# 创建开发分支
git checkout -b feat/your-feature-name
```

### 3. 开发前检查
- [ ] 阅读相关文档（`docs/` 目录）
- [ ] 查看现有 Issues，避免重复工作
- [ ] 在 Issue 中留言说明你打算解决该问题（避免撞车）

---

## 📝 提交规范

### 1. Commit Message 格式
```
<type>(<scope>): <subject>

<body>

<footer>
```

**类型（type）**：
- `feat`: 新功能
- `fix`: bug 修复
- `docs`: 文档更新
- `style`: 代码格式（不影响功能）
- `refactor`: 重构（既不是新功能也不是 bug 修复）
- `test`: 测试相关
- `chore`: 构建过程或辅助工具的变动

**示例**：
```
feat(财务): 添加中国高新企业会计科目表导入功能

- 新增 Account.csv 数据文件
- 新增 Data Import 脚本
- 更新相关文档

Closes #123
```

### 2. 提交频率
- **小步提交**：每个 commit 解决一个明确的问题
- **及时提交**：完成一个逻辑单元后立即提交
- **避免大提交**：单个 PR 不超过 500 行代码变更

### 3. 代码风格
- **Python**：遵循 PEP 8，使用 Black 格式化
- **Markdown**：遵循 CommonMark 规范
- **YAML**：使用 2 空格缩进
- **Shell**：使用 ShellCheck 检查

---

## 🔧 PR（Pull Request）要求

### 1. 创建 PR 前
- [ ] 确保分支基于最新的 `main` 分支
- [ ] 运行 `git fetch upstream && git rebase upstream/main`
- [ ] 本地测试通过（如有相关测试）
- [ ] 更新相关文档

### 2. PR 标题格式
```
[类型] 简要描述
```
**示例**：
```
[feat] 添加微信支付集成模块
[fix] 修复发票打印模板金额显示问题
[docs] 更新 Docker 部署指南
```

### 3. PR 描述模板
```markdown
## 变更内容
- 做了什么
- 为什么做
- 如何验证

## 关联 Issue
Closes #123

## 测试说明
- [ ] 本地部署测试通过
- [ ] 文档已更新
- [ ] 不影响现有功能

## 截图（如适用）
![描述](图片链接)
```

### 4. PR 检查清单
- [ ] 代码符合项目风格
- [ ] 有相应的测试（如适用）
- [ ] 文档已更新
- [ ] Commit message 符合规范
- [ ] 没有引入新的警告或错误

---

## 👀 代码审查标准

### 1. 审查流程
1. **自动检查**：GitHub Actions 运行 CI 检查
2. **人工审查**：至少需要 1 名核心维护者批准
3. **合并**：审查通过后，由维护者 Squash and Merge

### 2. 审查重点
| 维度 | 检查项 |
|------|--------|
| **功能正确性** | 是否解决了问题？是否有副作用？ |
| **代码质量** | 是否可读？是否遵循最佳实践？ |
| **测试覆盖** | 是否有相应测试？测试是否充分？ |
| **文档更新** | 相关文档是否同步更新？ |
| **向后兼容** | 是否影响现有功能？是否需要数据迁移？ |

### 3. 常见反馈类型
- **需要修改**：有明确问题需要修复
- **建议改进**：可以更好，但不是必须
- **疑问**：需要更多解释或讨论
- **通过**：可以合并

### 4. 如何回应审查
1. **感谢**：感谢审查者的时间和建议
2. **回应**：对每条评论做出回应
3. **修改**：根据建议修改代码
4. **标记**：修改完成后标记为“已解决”
5. **重新请求审查**：点击“Re-request review”

---

## 🧪 测试要求

### 1. 测试类型
| 类型 | 范围 | 要求 |
|------|------|------|
| **单元测试** | 单个函数/类 | 新功能必须包含 |
| **集成测试** | 模块间交互 | 复杂功能建议包含 |
| **端到端测试** | 完整业务流程 | 核心功能建议包含 |
| **文档测试** | 代码示例 | 所有公开 API 必须包含 |

### 2. 测试工具
- **Python**：pytest
- **前端**：Jest（如适用）
- **API**：requests + pytest
- **数据库**：SQLite 测试数据库

### 3. 测试运行
```bash
# 运行所有测试
pytest

# 运行特定测试
pytest tests/test_finance.py

# 带覆盖率报告
pytest --cov=src tests/
```

---

## 📚 文档要求

### 1. 文档类型
| 文档 | 位置 | 要求 |
|------|------|------|
| **功能文档** | `docs/erpnext/` | 新功能必须包含 |
| **API 文档** | 代码注释 | 所有公开 API 必须包含 |
| **部署文档** | `docs/` | 配置变更必须更新 |
| **贡献指南** | `CONTRIBUTING.md` | 流程变更必须更新 |

### 2. 文档标准
- **准确性**：与实际代码一致
- **完整性**：覆盖所有使用场景
- **可读性**：语言简洁，结构清晰
- **可搜索**：包含适当的关键词

### 3. 文档更新流程
1. 代码变更时同步更新文档
2. 提交时包含文档变更
3. PR 描述中说明文档更新情况

---

## 🚀 快速开始贡献

### 1. 寻找第一个 Issue
- **Good First Issue**：标记为 `good-first-issue` 的 Issue
- **文档改进**：修复错别字、补充示例
- **测试补充**：为现有功能添加测试

### 2. 简单贡献示例
```bash
# 1. Fork 并克隆
git clone https://github.com/你的用户名/erpnext_china_opc.git

# 2. 创建分支
git checkout -b docs/fix-typo

# 3. 修改文档
vim docs/erpnext/01_Introduction.md

# 4. 提交
git add .
git commit -m "docs(介绍): 修复错别字"

# 5. 推送并创建 PR
git push origin docs/fix-typo
# 然后在 GitHub 创建 Pull Request
```

### 3. 获取帮助
- **GitHub Issues**：技术问题讨论
- **GitHub Discussions**：一般性讨论
- **微信群**：实时交流（联系维护者获取加入方式）

---

## 📊 贡献者权益

### 1. 贡献者等级
| 等级 | 要求 | 权益 |
|------|------|------|
| **初级贡献者** | 1-2 个合并的 PR | GitHub Contributors 列表 |
| **活跃贡献者** | 5+ 个合并的 PR | 代码审查权限、专属徽章 |
| **核心贡献者** | 重大贡献 + 社区认可 | Maintainer 权限、项目决策权 |

### 2. 认可方式
- **GitHub Contributors**：永久记录
- **贡献者故事**：优秀贡献者专访
- **推荐信**：职业发展支持
- **商业机会**：实施顾问、培训讲师优先邀请

---

## 🔗 相关资源

### 1. 项目文档
- [项目介绍](docs/WHY_CONTRIBUTE.md) - 为什么参与这个项目
- [快速开始](docs/erpnext/00_Quick_Start.md) - 5分钟部署指南
- [技术架构](docs/erpnext/01_ERPNext_Micro_Server_Install.md) - 详细技术说明

### 2. 外部资源
- [ERPNext 官方文档](https://frappeframework.com/docs)
- [Frappe Framework](https://github.com/frappe/frappe)
- [Docker 文档](https://docs.docker.com/)

### 3. 沟通渠道
- **GitHub Issues**：功能请求、bug 报告
- **GitHub Discussions**：一般性讨论
- **微信群**：实时交流（需联系维护者）

---
*最后更新：2026-03-16*
*维护者：ERPNext 中国本土化项目团队*
