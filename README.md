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

## 为什么参与这个项目？

> 我们不仅仅是在写代码，更是在推动一场 **开源本地化的实践运动**。

### 🎯 解决一个真实且迫切的社会问题
- **填补“最后一公里”空白**：ERPNext 是世界级的开源 ERP，但在中国缺失了关键的财务合规性、业务习惯和生态互联。
- **降低企业数字化门槛**：通过开源模式砍掉高昂的 License 费用，让中小企业也能用上世界级的 ERP 系统。
- **你的每一行代码**，都可能帮助一家中小企业省下数十万的软件采购成本。

### 🚀 你能获得什么？
- **硬核技术成长**：接触 Docker 容器编排、Python 后端（Frappe框架）、Vue 前端等全栈技术栈，学习复杂系统设计。
- **真实商业洞察**：通过解决本地化问题，深入理解中国企业的财务、税务、供应链等核心业务流程。
- **温暖社区归属**：这里没有 KPI，只有一群真心想做好一件事的技术爱好者互助成长。

### 🔧 如何参与？（无论经验高低）
- **代码贡献**：从修复文档错别字到开发本地化模块，总有适合你的任务。
- **文档与知识沉淀**：撰写教程、完善翻译、整理案例。
- **测试与反馈**：部署测试、提出用户体验改进建议。
- **社区运营**：回答新手问题、技术布道、生态连接。

### 📈 你的贡献将被认可
- **公开荣誉**：GitHub Contributors 列表、贡献者故事专访、专属证书。
- **成长支持**：核心维护者一对一指导、职业推荐、模块主导权机会。
- **商业机会**：实施顾问合作、培训讲师邀请、创业项目孵化。

### 🎁 快速开始
1. **探索**：浏览项目 GitHub，部署 Demo 环境，加入社区。
2. **选择任务**：查看 [Good First Issues](https://github.com/kingpy-tech/erpnext_china_opc/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) 或从你遇到的第一个困惑开始。
3. **提交 PR**：不要担心完美，我们的社区会帮你一起完善。

**我们相信，技术应该服务于人，而不是制造门槛。**  
如果你也认同“让每一家中国企业都能用上适合自己的、负担得起的数字化工具”这一愿景，欢迎加入我们！

*了解更多参与细节，请阅读完整的 [为什么要参与 ERPNext 中国本土化项目？](docs/WHY_CONTRIBUTE.md)*

## 快速开始

> 5 分钟跑起来，详细说明见 [docs/erpnext/00_Quick_Start.md](docs/erpnext/00_Quick_Start.md)

**前置条件**：Docker 已安装，端口 8080 未占用，内存 ≥ 4GB。

```bash
# 1. 克隆仓库
git clone https://github.com/kingpy-tech/erpnext_china_opc.git
cd erpnext_china_opc

# 2. 一键启动
docker compose up -d

# 3. 等待初始化完成（看到 configurator exited with code 0）
docker compose logs -f configurator

# 4. 创建站点
docker compose exec backend bash
bench new-site mysite.localhost \
  --mariadb-root-password admin \
  --admin-password admin \
  --install-app erpnext
exit

# 5. 浏览器访问
# http://localhost:8080  用户名: Administrator  密码: admin
```

常用命令速查：

```bash
docker compose ps          # 查看容器状态
docker compose logs -f     # 查看实时日志
docker compose down        # 停止所有服务
docker compose restart     # 重启所有服务
```

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
