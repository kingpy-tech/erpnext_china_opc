# HANDOFF.md - erpnext_china_opc

## 当前负责人
- Agent: Ops_Writer
- 状态更新时间: 2026-03-16 02:14
- 开始时间: 2026-03-16 01:55

## 任务目标
梳理项目现状，检查 Docker 配置与自动更新脚本，整理一份「当前可用 vs 待修复」的状态清单。

## 上下文
- GitHub: https://github.com/kingpy-tech/erpnext_china_opc
- 最新 commit: ba82063 - 开源玩法
- 技术栈: Docker + ERPNext + HRMS，含翻译资产与自动更新脚本

## 交接内容（完成后填写）
> 下一个接手此项目的 agent 请从这里开始阅读

### 项目现状报告

#### 1. 部署架构
- **核心模式**：拥抱 `Frappe First` 原则，采用 Docker Compose 容器编排部署（结合 1Panel 面板实现轻量化运维管理）。
- **组件及版本**：主推 **ERPNext v16** + **HRMS v16**。底层环境升级并固化为 `mariadb:10.11` (LTS版本) 和 `redis:7-alpine` 以满足新版性能和队列需求。
- **架构特色**：原生多租户架构（Multi-tenant）。实现“一服多站”，在一台主机上通过不同域名（如 `.local` 沙盒域名）物理隔离正式生产账套和测试沙盒账套，实现低成本、“无限试错”的安全测试环境。

#### 2. 脚本清单与配置资产
- **自动更新脚本**：`config_package/setup_scripts/auto_update_erpnext.sh`
  - 核心功能：负责 ERPNext 与 HRMS 的分离更新，并可执行站点数据备份。
  - 特色亮点：
    - 支持全量备份或指定站点备份。
    - 自动安装和升级依赖（HRMS 强制检查）。
    - 包含终极防弹版的“自动导入翻译 CSV”脚本逻辑（利用 EOF 传递多行脚本解决 Python 执行过程中的引号和 SQL 注入问题）。
    - 针对前端静态资源提供强制编译与缓存清理机制（解决 Logo 卡死等前端更新痛点）。
- **财务科目资产**：`config_package/chart_of_accounts/Account.csv` 和 `erpnext_accounts_backup.csv`，包含符合中国高新企业认证标准的专属会计科目表数据源，供通过内置 Data Import 导入。
- **本地化翻译包**：`config_package/translations/account_category_zh.csv` 等，利用 ERPNext 的 Custom Translation 机制修补官方中文包的遗漏（中英对照格式），避免硬改源码。

#### 3. 当前状态
- 项目整体结构清晰，文档详实，涵盖了从 1Panel 准备、Docker 部署、多租户测试沙盒搭建，到财务科目表、自定义翻译导入以及如何参与开源社区等。
- 自动化更新脚本 `auto_update_erpnext.sh` 逻辑完善，已经集成了备份、HRMS 升级、自动导入中文汉化文件和最终前端资产编译（并解决了常见的报错和卡死问题）。
- 文档目前通过 MkDocs 进行了构建（存在 `site` 目录和 `venv` 环境，包含各类页面静态文件）。

#### 4. 已知问题
- `config_package/setup_scripts/docker-compose.yml` 配置文件目前似乎**缺失**（虽然文档中多次提及，但在目录树中未找到该文件，仅有一个空的 `README.md` 和 `auto_update_erpnext.sh`）。
- 部署文档体系（00-05）基本完备，但文档结构目录中提到的 `06_Workspace_Simplification.md`（工作区简化与权限配置）尚未创建。
  - *(更新：2026-03-16 已创建 `06_Workspace_Simplification.md`，详细阐述了工作区定制、权限矩阵、界面简化及自动化配置脚本)*

#### 5. 下一步优先级
~~- **最高**：补齐缺失的 `docker-compose.yml` 文件。这是 1Panel 部署和系统启动的核心编排文件，目前缺失会导致新手无法依照文档直接部署。~~ (已于第二轮任务中根据01文档补齐，存放于根目录及 config_package 目录下)
~~- **高**：创建并完善计划中的 `06_Workspace_Simplification.md` 文档。~~ (已完成，文档涵盖工作区定制、权限矩阵、界面简化及自动化脚本)
~~- **中**：检查 MkDocs 配置和 CI/CD 流程是否健全，确保文档网站能持续稳定发布。~~ (已由 Ops_Writer 于 2026-03-16 补齐 mkdocs.yml 并修复构建依赖)
- **低**：持续完善翻译字典（`translations/`）和科目表模板（`chart_of_accounts/`），根据最新 v16 变化做查漏补缺。
---

## 第五轮更新（2026-03-16，CTO）

### docker-compose.yml 检查结果
- **根目录** `docker-compose.yml`：✅ 内容完整，结构正常。
- 包含全部必要服务：`backend`、`configurator`、`db (mariadb:10.11)`、`frontend`、`queue-default/long/short`、`redis-cache/queue/socketio (redis:7-alpine)`、`scheduler`、`websocket`。
- 端口映射：`8080:8080`，与文档一致。
- 所有 volumes 均已声明。**无需修改，可直接使用。**

### 新增文档
- **`docs/erpnext/00_Quick_Start.md`**（commit `29bbbe0`）：面向新手的 5 分钟快速启动指南，大白话风格，覆盖：
  - 前置条件检查表
  - `docker compose up -d` 一键启动
  - `bench new-site` 建站命令（含参数说明）
  - 浏览器访问与登录信息
  - 常用命令速查表
  - 常见问题排查（容器重启、数据库连接、忘记密码）
  - 引导读者按序阅读后续 01~04 文档

### 下一步建议
- 将 `00_Quick_Start.md` 加入 MkDocs 导航配置（`mkdocs.yml`），确保文档网站首页能直接跳转。
- 考虑在 `docker-compose.yml` 中补充 `FRAPPE_SITE_NAME_HEADER` 的注释说明（单租户 vs 多租户的切换方式），方便新手理解。

## 第六轮更新（2026-03-16，Ops_Writer）
- 修复了丢失的 `mkdocs.yml`，依据原有的文档目录结构重新配置了 Material for MkDocs 主题与导航树。
- 将第五轮新增的 `00_Quick_Start.md` 和 `06_Workspace_Simplification.md` 完整接驳入导航索引。
- 修复了项目内的 venv 环境依赖（清理重装了 mkdocs 与 mkdocs-material），目前文档站已可以正常 build 通过，具备直接上线发布的健康状态。

## 第七轮更新（2026-03-16，CMO）

### 面向贡献者的激励文案创作
- **撰写了《为什么要参与 ERPNext 中国本土化项目？》**（`docs/WHY_CONTRIBUTE.md`），一份面向潜在贡献者的激励与召唤文案。
- **文案内容涵盖**：
  - 项目的社会价值：填补开源 ERP 在中国的“最后一公里”空白，降低中小企业数字化门槛。
  - 个人成长收益：硬核技术成长（全栈、复杂系统设计）、真实商业洞察、温暖的社区归属。
  - 具体参与途径：代码贡献、文档与知识沉淀、测试反馈、社区运营等多维度参与方式。
  - 贡献者认可机制：公开荣誉、成长支持、潜在商业机会。
  - 新手入门三步指南。
- **文案风格**：兼具感染力与实操性，旨在激发技术爱好者的参与热情，同时提供清晰的下一步行动指引。

### 下一步建议
- 将 `WHY_CONTRIBUTE.md` 加入 MkDocs 导航配置，方便社区成员查阅。
- 考虑将文案的核心观点提炼，用于 GitHub README、项目官网等对外展示页面。
- 后续可基于此文开展社区招募活动，定向邀请相关领域的技术人员参与。
