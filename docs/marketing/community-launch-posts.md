# 社区推广文案素材

> 本文件收录可直接用于社区发布的推广内容，按渠道分类整理。

---

## 一、ERPNext 中文论坛发帖

**标题**：分享一个 ERPNext 中国本土化踩坑包，欢迎一起折腾

---

大家好，

我是 kingpy-tech 团队的成员。过去一段时间，我们在用 ERPNext 给自己团队搭内部系统，踩了不少坑，也摸索出了一套相对顺手的本土化配置方案。今天把这些整理成了一个开源项目，想和社区分享，也希望能找到一起折腾的朋友。

**项目地址**：https://github.com/kingpy-tech/erpnext_china_opc

### 我们解决了哪些痛点？

ERPNext 本身是世界级的开源 ERP，功能强大，但对中国用户来说有几道坎绕不过去：

**1. 会计科目表不合规**

ERPNext 默认的科目表是按国际惯例设计的，和国内财政部发布的企业会计准则差距不小。我们针对高新技术企业认证场景，整理了一套符合国内规范的科目表，可以直接导入使用（`config_package/chart_of_accounts/`）。

**2. 汉化不完整、翻译质量参差**

官方中文翻译存在大量机翻痕迹，部分业务术语和国内习惯不符。我们维护了一个自定义翻译修正包，覆盖了财务、采购、销售等核心模块的常见术语（`config_package/translations/`）。

**3. 部署门槛高，文档散乱**

ERPNext 的官方文档对 Docker 多租户部署的说明比较简略，国内网络环境下还有镜像拉取的问题。我们整理了从零开始的完整部署攻略，包括 1Panel 面板安装、Docker 多租户双账套架构、沙盒回退玩法等，力求让没有运维背景的人也能跑起来。

**4. 工作区太复杂，上手难**

ERPNext 默认工作区模块繁多，对小微团队来说很多功能根本用不到，反而造成干扰。我们整理了一套工作区简化与权限配置方案，帮助团队快速聚焦核心业务。

### 项目现状

目前项目包含：

- 完整的部署与运维文档（从安装到备份恢复）
- 系统实施配置文档（科目表、翻译、工作区）
- 可直接导入的配置数据包
- Docker Compose 模板与自动化脚本
- GitHub Actions 自动构建的文档站：https://kingpy-tech.github.io/erpnext_china_opc/

### 欢迎参与

这个项目目前主要是我们自己在用、自己在维护，内容还很不完善。如果你也在折腾 ERPNext，不管是：

- 遇到了我们没覆盖到的坑，想补充文档
- 有更好的本土化配置方案想分享
- 发现了文档里的错误或过时内容
- 只是想部署试用、给个反馈

都非常欢迎。项目有完整的贡献指南（`CONTRIBUTING.md`），从修改一个错别字到开发新功能，都有对应的参与路径。

我们不追求大而全，只希望把真实踩过的坑记录清楚，让后来的人少走弯路。如果这个项目对你有帮助，或者你有任何想法，欢迎在 GitHub Issues 里聊，也可以直接提 PR。

**GitHub**：https://github.com/kingpy-tech/erpnext_china_opc  
**文档站**：https://kingpy-tech.github.io/erpnext_china_opc/

期待和大家一起把这个项目做得更好。

---

## 二、微信群 / 钉钉群推广消息

---

推荐一个 ERPNext 中国本土化开源项目 👇

**erpnext_china_opc** — 专为国内用户整理的 ERPNext 踩坑包与配置集合，包含：
✅ 符合国内会计准则的科目表（可直接导入）
✅ 中文汉化修正包（覆盖财务/采购/销售核心模块）
✅ Docker 多租户完整部署攻略（含 1Panel 方案）
✅ 工作区简化配置

完全免费开源，适合想低成本上 ERP 的小微团队。

GitHub：https://github.com/kingpy-tech/erpnext_china_opc
文档站：https://kingpy-tech.github.io/erpnext_china_opc/

欢迎 Star / 试用 / 提 Issue 🙌

---

## 三、GitHub README 徽章建议

在 README 顶部添加以下徽章，提升项目可信度与可见度。

### 推荐徽章

**1. GitHub Stars**
```markdown
[![GitHub Stars](https://img.shields.io/github/stars/kingpy-tech/erpnext_china_opc?style=flat-square&logo=github)](https://github.com/kingpy-tech/erpnext_china_opc/stargazers)
```

**2. License（MIT）**
```markdown
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://github.com/kingpy-tech/erpnext_china_opc/blob/main/LICENSE)
```

**3. GitHub Actions 构建状态**
```markdown
[![Docs Build](https://img.shields.io/github/actions/workflow/status/kingpy-tech/erpnext_china_opc/docs.yml?branch=main&style=flat-square&label=docs)](https://github.com/kingpy-tech/erpnext_china_opc/actions)
```

**4. GitHub Issues（欢迎参与）**
```markdown
[![GitHub Issues](https://img.shields.io/github/issues/kingpy-tech/erpnext_china_opc?style=flat-square)](https://github.com/kingpy-tech/erpnext_china_opc/issues)
```

**5. ERPNext 版本兼容标注**
```markdown
[![ERPNext](https://img.shields.io/badge/ERPNext-v15-orange?style=flat-square)](https://github.com/frappe/erpnext)
```

### 建议放置位置

在 README.md 的项目标题下方、正文之前，集中排列：

```markdown
# 🇨🇳 ERPNext 中国本土化踩坑与配置探索包

[![GitHub Stars](https://img.shields.io/github/stars/kingpy-tech/erpnext_china_opc?style=flat-square&logo=github)](https://github.com/kingpy-tech/erpnext_china_opc/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](https://github.com/kingpy-tech/erpnext_china_opc/blob/main/LICENSE)
[![Docs Build](https://img.shields.io/github/actions/workflow/status/kingpy-tech/erpnext_china_opc/docs.yml?branch=main&style=flat-square&label=docs)](https://github.com/kingpy-tech/erpnext_china_opc/actions)
[![GitHub Issues](https://img.shields.io/github/issues/kingpy-tech/erpnext_china_opc?style=flat-square)](https://github.com/kingpy-tech/erpnext_china_opc/issues)
[![ERPNext](https://img.shields.io/badge/ERPNext-v15-orange?style=flat-square)](https://github.com/frappe/erpnext)
```
