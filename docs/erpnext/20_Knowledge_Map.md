# ERPNext 中国化实践知识图谱：20 篇文档完整导读

## 引言：本知识库的定位与价值

本知识库由青皮科技（Qingpi Tech）在真实生产环境中持续沉淀，记录了 ERPNext 从零部署到深度中国化落地的完整实战路径。20 篇文档覆盖部署运维、本土化配置、功能深度、开发集成、安全合规五大主题，是国内目前最系统的 ERPNext 中文实践指南之一。

无论你是刚接触 ERPNext 的新手，还是正在生产环境中排障的运维工程师，或是需要对接金税、微信的开发者，都能在这里找到直接可用的参考。

---

## 五大主题分类

### 1. 部署与运维

从单机安装到 Docker 容器化，覆盖完整的生命周期管理。

| 篇目 | 文档 |
|------|------|
| 01 | [基础安装与多租户隔离](01_ERPNext_Micro_Server_Install.md) |
| 02 | [沙盒实验室与快照回退](02_Advanced_Backup_Restore_Tenant.md) |
| 03 | [高新企业科目表导入](03_Chart_of_Accounts_Import.md) |
| 04 | [自定义翻译补全指南](04_Custom_Translation_Import.md) |
| 11 | [性能优化实战指南](11_Performance_Optimization.md) |
| 12 | [备份与灾难恢复指南](12_Backup_and_Recovery.md) |
| 18 | [Docker 容器化部署实战](18_Docker_Deployment.md) |

### 2. 中国本土化

针对中国企业的税务、发票、翻译、开源协作等核心场景。

| 篇目 | 文档 |
|------|------|
| 05 | [优雅参与开源社区](05_OpenSource_Contribution_and_Fork.md) |
| 06 | [工作区简化与权限配置](06_Workspace_Simplification.md) |
| 07 | [ERPNext v16 升级指南](07_ERPNext_v16_Upgrade.md) |
| 08 | [中国本土化深度指南](08_China_Localization_Deep_Dive.md) |
| 09 | [金税系统对接技术指南](09_Golden_Tax_Integration.md) |

### 3. 功能深度

多公司管理、工作流审批、报表分析等企业级功能的完整配置指南。

| 篇目 | 文档 |
|------|------|
| 13 | [多公司与多站点管理](13_Multi_Company_Setup.md) |
| 15 | [工作流与审批配置](15_Workflow_and_Approval.md) |
| 16 | [报表与数据分析](16_Reports_and_Analytics.md) |

### 4. 开发与集成

自定义 App 开发、微信生态对接，适合有开发能力的团队。

| 篇目 | 文档 |
|------|------|
| 10 | [微信生态集成指南](10_WeChat_Integration.md) |
| 14 | [自定义开发入门](14_Custom_Development.md) |

### 5. 安全与合规

等保 2.0、数据安全法、PIPL 合规，以及生产环境排障。

| 篇目 | 文档 |
|------|------|
| 17 | [安全加固实战指南](17_Security_Hardening.md) |
| 19 | [进阶排障手册](19_Troubleshooting_Advanced.md) |

---

## 推荐阅读路径

**🟢 新手路径**（首次接触 ERPNext）

`00_Quick_Start` → `01` → `06` → `08` → `FAQ`

**🔧 运维路径**（负责服务器与稳定性）

`01` → `02` → `11` → `12` → `18` → `19`

**💻 开发路径**（需要二次开发或系统集成）

`05` → `14` → `10` → `09` → `17`

**📊 业务路径**（财务/HR/采购等业务人员）

`03` → `04` → `08` → `13` → `15` → `16`

---

## 贡献指南

欢迎通过以下方式参与共建：

1. **提交 PR**：Fork 本仓库，在 `docs/erpnext/` 下新增或修改文档，提交 Pull Request 至 `main` 分支。
2. **反馈问题**：在 [GitHub Issues](https://github.com/kingpy-tech/erpnext_china_opc/issues) 提交 Bug 报告或功能建议，请附上 ERPNext 版本号和复现步骤。
3. **文档规范**：新文档请参考仓库根目录的 `CONTRIBUTING.md` 中的格式要求，保持与现有文档风格一致。

---

## 联系青皮科技

- **GitHub**：[github.com/kingpy-tech](https://github.com/kingpy-tech)
- **项目仓库**：[erpnext_china_opc](https://github.com/kingpy-tech/erpnext_china_opc)
- **Issues**：欢迎在仓库 Issues 区留言，我们会尽快回复

> 本知识库持续更新，欢迎 Star ⭐ 关注最新进展。
