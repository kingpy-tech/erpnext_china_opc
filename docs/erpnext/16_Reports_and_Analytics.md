# ERPNext 报表与数据分析实战

ERPNext 内置了丰富的报表体系，从财务到库存、从销售到采购，覆盖企业日常经营的核心数据需求。本文梳理内置报表的使用方式、自定义报表的开发技巧、仪表盘搭建，以及与外部 BI 工具的集成方案。

---

## 一、内置报表

ERPNext 的报表入口统一在 **报表中心（Report Center）**，也可通过各模块菜单直接访问。

### 财务报表

| 报表名称 | 路径 |
|---|---|
| 资产负债表 | 会计 → 报表 → 资产负债表 |
| 利润与损失表 | 会计 → 报表 → 利润与损失表 |
| 现金流量表 | 会计 → 报表 → 现金流量表 |
| 总账 | 会计 → 报表 → 总账 |

财务报表支持按公司、会计期间、成本中心多维度筛选，并可对比多个会计期间的数据变化。

### 库存报表

- **库存余额**：实时查看各仓库的物料库存数量与估值
- **库存账龄分析**：识别滞销物料，辅助清库决策
- **物料移动明细**：追踪每笔入库/出库/调拨记录

### 销售报表

- **销售分析**：按客户、物料、销售员、地区多维汇总
- **销售漏斗**：从询价到交货的转化率追踪
- **客户应收账款**：账期管理与逾期预警

### 采购报表

- **采购分析**：按供应商、物料、采购员汇总
- **供应商应付账款**：付款计划与账期管理
- **采购价格历史**：辅助比价与谈判

---

## 二、自定义报表

当内置报表无法满足需求时，ERPNext 提供两种自定义报表类型。

### Query Report（SQL 查询报表）

适合熟悉 SQL 的用户，直接编写查询语句生成报表。

**创建步骤**：报表中心 → 新建 → 类型选 `Query Report`

```sql
-- 示例：统计本月各客户的销售金额
SELECT
    so.customer AS 客户,
    SUM(so.grand_total) AS 销售总额,
    COUNT(so.name) AS 订单数量
FROM `tabSales Order` so
WHERE
    so.docstatus = 1
    AND so.transaction_date BETWEEN %(from_date)s AND %(to_date)s
GROUP BY so.customer
ORDER BY 销售总额 DESC
```

在报表定义中添加过滤器字段（Filters），即可让用户在界面上动态传入 `from_date` / `to_date` 等参数。

### Script Report（Python 脚本报表）

适合需要复杂逻辑处理的场景，用 Python 控制数据获取与列定义。

```python
# report_name/report_name.py
import frappe

def execute(filters=None):
    columns = [
        {"label": "客户", "fieldname": "customer", "fieldtype": "Link", "options": "Customer", "width": 150},
        {"label": "销售额", "fieldname": "total", "fieldtype": "Currency", "width": 120},
    ]

    data = frappe.db.sql("""
        SELECT customer, SUM(grand_total) AS total
        FROM `tabSales Order`
        WHERE docstatus = 1
          AND transaction_date BETWEEN %(from_date)s AND %(to_date)s
        GROUP BY customer
    """, filters, as_dict=True)

    return columns, data
```

Script Report 支持在 `columns` 中定义字段类型、宽度、链接跳转，报表结果可直接点击跳转到对应单据。

---

## 三、仪表盘

### Dashboard（仪表盘）

路径：**首页 → 仪表盘** 或各模块的仪表盘入口。

每个仪表盘由多个 **图表（Chart）** 和 **数字卡片（Number Card）** 组成，支持拖拽排列布局。

### Number Card（数字卡片）

用于展示单一关键指标，例如"本月销售额"、"待处理采购订单数"。

配置要点：
- **文档类型**：选择数据来源的 DocType
- **聚合函数**：Count / Sum / Average / Min / Max
- **过滤条件**：支持动态日期过滤（本月、本季度等）

### Chart（图表）

支持折线图、柱状图、饼图、热力图等类型，数据源可以是报表或 DocType 字段聚合。

```json
// 图表配置示例（通过 API 创建）
{
  "chart_name": "月度销售趋势",
  "chart_type": "Line",
  "document_type": "Sales Invoice",
  "based_on": "posting_date",
  "value_based_on": "grand_total",
  "time_interval": "Monthly",
  "filters_json": "[['docstatus', '=', 1]]"
}
```

---

## 四、数据导出

ERPNext 所有列表视图和报表均支持多格式导出：

- **Excel / CSV**：点击报表右上角 **菜单 → 导出**，选择格式即可
- **PDF**：报表页面点击 **打印**，选择打印格式后另存为 PDF

通过 API 批量导出：

```python
import frappe
import pandas as pd

frappe.init(site="your-site.local")
frappe.connect()

data = frappe.db.get_all(
    "Sales Invoice",
    filters={"docstatus": 1},
    fields=["name", "customer", "grand_total", "posting_date"]
)

df = pd.DataFrame(data)
df.to_excel("sales_export.xlsx", index=False)
```

---

## 五、定时报表（邮件推送）

ERPNext 支持将报表定时发送到指定邮箱。

**配置路径**：报表页面 → 菜单 → **添加到邮件摘要**

或通过 **自动化（Automation）→ 自动邮件报表** 配置：

- 选择报表名称与过滤参数
- 设置收件人列表
- 配置发送频率（每日/每周/每月）
- 选择附件格式（Excel / PDF）

定时任务底层由 Frappe 的 **Scheduler** 驱动，确保 `bench scheduler` 服务正常运行：

```bash
bench --site your-site.local enable-scheduler
```

---

## 六、与 BI 工具集成

ERPNext 的数据存储在 MariaDB，可直接对接主流 BI 工具。

### Metabase

```yaml
# 连接配置
Database type: MySQL
Host: 127.0.0.1
Port: 3306
Database name: _your_site_name_  # 下划线替换点号
Username: frappe_ro              # 建议创建只读账号
```

建议为 BI 工具创建专用只读数据库账号，避免直接使用 root：

```sql
CREATE USER 'frappe_ro'@'%' IDENTIFIED BY 'strong_password';
GRANT SELECT ON `_your_site_name_`.* TO 'frappe_ro'@'%';
FLUSH PRIVILEGES;
```

### Grafana

通过 **MySQL Data Source** 插件连接，适合搭建实时运营监控大屏。配置方式与 Metabase 类似，连接信息填入 Grafana 数据源配置页即可。

### Power BI

使用 **MySQL Connector** 或通过 ERPNext REST API 获取数据：

```
GET /api/resource/Sales Invoice?filters=[["docstatus","=",1]]&fields=["name","customer","grand_total"]&limit=500
Authorization: token api_key:api_secret
```

Power BI 的 **Web 数据源** 可直接调用上述 API，配合 Power Query 进行数据清洗与建模。

---

## 小结

ERPNext 的报表体系从"开箱即用"到"深度定制"层次分明：内置报表满足日常需求，Script/Query Report 覆盖个性化场景，仪表盘提供实时可视化，定时推送解放人工汇报，BI 集成则打通企业数据中台的最后一公里。
