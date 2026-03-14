# 🇨🇳 ERPNext 中国本土化踩坑与配置探索包

本项目 (`erpnext_china_opc`) 是我们在探索和试用 ERPNext 过程中的一份实战踩坑记录与配置分享。
我们是一群对 ERP 系统感兴趣的折腾玩家，希望能通过 Frappe 原生的低代码/无代码能力，顺便解决一下自己团队在本地化部署与记账合规上遇到的痛点。
欢迎大家一起来试用、折腾和玩耍，交流进步，也希望能用这些开源经验顺便助力一下你的小微团队或独立业务！

## 目录结构
- `/docs/erpnext`: 详细的实施与配置操作攻略、踩坑与最佳实践总结。
  - **部署与基建阶段**
    - `00_ERPNext_Preparation_1Panel.md`: 前置准备篇（1Panel 面板安装指南）。
    - `01_ERPNext_Micro_Server_Install.md`: 基础安装指南（Docker 多租户双账套架构部署）。
    - `02_Advanced_Backup_Restore_Tenant.md`: 高级运维篇（沙盒实验室搭建、快照回退玩法）。
  - **系统实施与配置阶段**
    - `03_Chart_of_Accounts_Import.md`: 高新企业专属会计科目表集成导入指南。
    - `04_Custom_Translation_Import.md`: 自定义翻译与汉化包导入指南。
    - `06_Workspace_Simplification.md`: 工作区简化与权限配置。
- `/config_package/chart_of_accounts`: 针对高企认证标准定制的会计科目表数据源 (`erpnext_accounts_backup.csv`)。
- `/config_package/translations`: 存放自动化导入的中文汉化修正包。
- `/config_package/setup_scripts`: 存放核心的 `docker-compose.yml` 模板及自动化脚本。

## 我们的探索与原则 (Frappe First)
1. **拥抱容器与多租户玩法**：记录了如何通过 1Panel + Docker Compose 实现不折腾环境的极速部署。利用 Frappe 原生的多租户魔法，在一台便宜的云主机上完美隔离“内部主库”与供我们随便乱造的“测试沙盒”。
2. **详尽的实战避坑笔记**：被国内网络限速、Docker 权限卡脖子、Vite 前端打包报错折磨后的血泪史，以及我们探索出的“无感克隆数据到沙盒”的无限回档玩法。
3. **顺手做点本土化配置**：分享了一些我们自己团队在用的符合中国习惯的设置，比如带研发支出的高企会计科目预制、一些翻译修正包与界面简化方案。

## 快速使用
建议严格依照 `docs/erpnext/` 目录中的文档序号依次进行探索：
1. 先根据 `00` 和 `01` 号文档完成云服务器环境搭建与多租户架构初始化。
2. 参照 `02` 号文档，建立属于自己的私有测试沙盒并打好快照（建立防废机制）。
3. 参照 `03`、`04` 等后续文档，在沙盒中安全地进行财务科目、翻译等初始化数据的导入演练。

---
*Powered by 青皮（上海）信息科技有限公司*
