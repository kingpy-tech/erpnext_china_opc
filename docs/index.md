# 🇨🇳 ERPNext 中国一人公司 / 小微企业合规配置包

本项目 (`erpnext_china_opc`) 专为中国小微企业（特别是高新技术企业）和独立开发者定制的 ERPNext 合规开源配置方案。旨在通过 Frappe 原生的低代码/无代码能力，解决本地化部署与记账合规问题。

## 目录结构
- `/docs`: 详细的实施与配置操作攻略、最佳实践总结。
  - `01_ERPNext_Micro_Server_Install.md`: 微型服务器/家用小主机 Docker 标准安装指南。
  - `02_Chart_of_Accounts_Import.md`: 高新企业专属会计科目表集成导入指南。
  - `03_Document_Naming_Series.md`: 单据编号规则个性化定制指南 (ACC 替换为公司缩写)。
- `/config_package/chart_of_accounts`: 针对高企认证标准定制的会计科目表数据源 (`erpnext_accounts_backup.csv`，支持 ERPNext Data Import 直接导入)。
- `/config_package/custom_doctypes`: 预留用于后续导入自定义表单（如：股东名册等）的目录。
- `/config_package/setup_scripts`: 预留存放自动化配置与高级定制脚本的目录。

## 核心特色与实施原则 (Frappe First)
1. **服务器极简部署**：抛弃繁杂的源码安装，提供针对 HomeLab 等小主机的标准 Docker 部署避坑指南。
2. **高企会计科目预制**：内置研发支出（资本化支出、费用化支出、人员人工、直接投入等）等符合中国特色与高企申报标准的科目体系，且严格遵循中国复式记账法规范。
3. **品牌化与自动化单据编号**：倡导无代码配置思路，通过修改系统 Naming Series 的规则（或基于 `{company.abbr}` 动态变量），将标准呆板的前缀替换为专属公司标识（例如 `QP`）。

## 快速使用
建议依照 `docs/` 目录中的文档序号依次进行操作：
1. 先根据 `01` 号文档完成基础环境搭建。
2. 参照 `02` 号文档将 `chart_of_accounts` 下的 csv 数据导入系统，完成财务初始化。
3. 参照 `03` 号文档调整全局系统凭证的单据编号格式。

---
*Powered by 青皮（上海）信息科技有限公司*