# ERPNext 自定义开发入门：从 Custom Field 到自定义 App

ERPNext 的自定义能力分为四个层级，从轻到重依次是：**Custom Field → Custom Form → Client/Server Script → Custom App**。本文按这条路径逐层讲解，帮你找到适合自己场景的切入点。

---

## 一、自定义层级概览

| 层级 | 适用场景 | 是否需要代码 |
|------|----------|-------------|
| Custom Field | 新增字段、调整布局 | 否 |
| Custom Form | 隐藏/只读字段、条件显示 | 否 |
| Client Script | 前端验证、字段联动 | 是（JS） |
| Server Script | 后端逻辑、定时任务 | 是（Python） |
| Custom App | 全新 DocType、复杂业务 | 是（Python/JS） |

---

## 二、Custom Field：字段类型与布局

进入 **设置 → 自定义 → 自定义字段**，选择目标 DocType 后即可添加字段。

常用字段类型：

- `Data` / `Int` / `Float` / `Currency` — 基础数据
- `Select` — 下拉选项，选项值用换行分隔
- `Link` — 关联其他 DocType
- `Table` — 子表（需先创建子 DocType）
- `Check` — 布尔开关

**表单布局**：使用 `Column Break` 和 `Section Break` 类型字段控制分栏与分区。

**权限控制**：在字段属性中勾选 `Read Only`、`Hidden`，或通过 **Depends On** 填写条件表达式（如 `eval:doc.status == "Draft"`）实现动态显示。

---

## 三、Client Script：前端逻辑

进入 **设置 → 自定义 → 客户端脚本**，绑定 DocType 后编写 JavaScript。

### 字段验证

```javascript
frappe.ui.form.on('Sales Order', {
    delivery_date: function(frm) {
        if (frm.doc.delivery_date < frm.doc.transaction_date) {
            frappe.msgprint('交货日期不能早于订单日期');
            frm.set_value('delivery_date', '');
        }
    }
});
```

### 字段联动与自动填充

```javascript
frappe.ui.form.on('Sales Order', {
    customer: function(frm) {
        if (frm.doc.customer) {
            frappe.db.get_value('Customer', frm.doc.customer, 'custom_credit_limit')
                .then(r => {
                    frm.set_value('custom_credit_limit', r.message.custom_credit_limit);
                });
        }
    }
});
```

---

## 四、Server Script：后端逻辑

进入 **设置 → 自定义 → 服务器脚本**，支持三种类型：

- **DocType Event**：绑定文档事件（`before_save`、`on_submit` 等）
- **API**：暴露自定义 REST 接口
- **Scheduler Event**：定时任务

### 触发器示例（on_submit）

```python
# DocType: Sales Order, Event: on_submit
if doc.custom_require_approval and not doc.custom_approved:
    frappe.throw("该订单需要审批后才能提交")

frappe.db.set_value('Customer', doc.customer, 'last_order_date', doc.transaction_date)
```

### 定时任务示例

```python
# Scheduler Event: Daily
overdue = frappe.db.get_all('Sales Order',
    filters={'status': 'To Deliver', 'delivery_date': ['<', frappe.utils.today()]},
    fields=['name', 'customer']
)
for order in overdue:
    frappe.sendmail(
        recipients=['sales@example.com'],
        subject=f'逾期订单提醒：{order.name}',
        message=f'客户 {order.customer} 的订单已逾期，请跟进。'
    )
```

---

## 五、自定义 App：完整开发流程

当业务逻辑复杂到无法用脚本承载时，创建独立 App 是正确选择。

### 初始化

```bash
cd /home/frappe/frappe-bench
bench new-app my_china_app
# 填写 App 名称、描述、作者等信息
bench --site mysite.local install-app my_china_app
```

### 目录结构

```
my_china_app/
├── my_china_app/
│   ├── __init__.py
│   ├── hooks.py          # 核心钩子配置
│   ├── modules.txt
│   └── my_module/
│       ├── doctype/
│       │   └── my_doctype/
│       │       ├── my_doctype.json   # 字段定义
│       │       └── my_doctype.py    # 控制器
│       └── __init__.py
└── setup.py
```

### 创建 DocType

```bash
bench --site mysite.local console
# 或直接在 UI：设置 → DocType → 新建
```

DocType 控制器示例：

```python
# my_doctype.py
import frappe
from frappe.model.document import Document

class MyDoctype(Document):
    def validate(self):
        if self.amount < 0:
            frappe.throw("金额不能为负数")

    def on_submit(self):
        self.create_gl_entries()
```

---

## 六、Hooks 机制

`hooks.py` 是自定义 App 的神经中枢：

```python
# hooks.py

# 文档事件钩子
doc_events = {
    "Sales Invoice": {
        "on_submit": "my_china_app.api.invoice.on_submit",
        "on_cancel": "my_china_app.api.invoice.on_cancel",
    }
}

# 定时任务
scheduler_events = {
    "daily": [
        "my_china_app.tasks.daily.run_daily_tasks"
    ],
    "hourly": [
        "my_china_app.tasks.hourly.sync_data"
    ]
}

# 覆盖白名单方法
override_whitelisted_methods = {
    "frappe.client.get_value": "my_china_app.overrides.custom_get_value"
}
```

---

## 七、最佳实践

**版本控制**：自定义 App 必须纳入 Git 管理；Custom Field/Script 可通过 **导出 Fixtures** 固化到代码仓库：

```python
# hooks.py
fixtures = [
    {"dt": "Custom Field", "filters": [["module", "=", "My China App"]]},
    "Client Script",
    "Server Script",
]
```

执行 `bench export-fixtures` 将配置导出为 JSON，随代码一起提交。

**测试**：使用 `bench run-tests --app my_china_app` 运行单元测试；关键业务逻辑务必覆盖 `validate` 和 `on_submit` 场景。

**升级兼容性**：

- 避免直接修改 ERPNext 核心文件，优先用 `override_whitelisted_methods` 或 `doc_events` 注入逻辑
- 升级前在测试站点执行 `bench migrate` 验证
- 关注 ERPNext 的 `CHANGELOG`，及时处理废弃 API

---

> 💡 **路径建议**：从 Custom Field 开始探索，业务稳定后再用 Client/Server Script 增强交互，最终有需要时才创建独立 App。循序渐进，避免过度工程化。
