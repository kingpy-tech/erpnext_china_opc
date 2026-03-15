# 金税系统对接技术指南

> 本文面向需要将 ERPNext 与金税系统（百旺、航天信息等）打通的技术实施者。覆盖背景、三种对接方案、代码示例和合规注意事项。

---

## 一、金税系统背景

**金税系统**（全称：增值税发票管理系统）是中国税务总局主导的法定增值税发票开具平台，所有增值税一般纳税人必须通过金税盘/税控盘开具增值税专用发票和普通发票。

主流服务商：

| 服务商 | 产品名称 | 特点 |
|--------|----------|------|
| 百旺金赋 | 百旺云开票 | 市占率高，REST API 文档较完整 |
| 航天信息 | 诺诺网 | 提供标准化 API，支持电子发票 |
| 税友软件 | 税友云 | 中小企业常用，本地盘为主 |

**核心数据流：**

```
ERPNext 销售发票
      ↓
  发票数据提取（商品名称、税率、金额、购方信息）
      ↓
  金税系统开票（生成发票代码 + 发票号码）
      ↓
  发票信息回写 ERPNext（发票代码、号码、校验码、开票时间）
```

**ERPNext 物料主数据必备字段：**

在「物料」DocType 中增加自定义字段 `tax_classification_code`（税收分类编码），开票时自动带入，避免手工填写出错。

---

## 二、三种对接方案

### 方案一：手工导出导入

**适用场景**：月开票量 < 50 张，无开发资源。

**流程：**

1. 在 ERPNext「销售发票列表」筛选待开票记录，导出 Excel
2. 按金税系统要求的模板格式整理数据（商品名称、规格、数量、单价、税率、购方信息）
3. 导入金税盘批量开票
4. 将开票结果（发票代码、号码、校验码）手工回填到 ERPNext 对应发票的自定义字段

**优点**：零开发成本，立即可用  
**缺点**：人工操作易出错，数据同步滞后

---

### 方案二：API 中间件

**适用场景**：月开票量较大，有基础 Python 开发能力。

**架构：**

```
ERPNext (Frappe hooks)
      ↓ on_submit 事件
  中间件服务（Python/Flask 或直接写 Frappe 自定义 App）
      ↓ REST API 调用
  金税服务商 API（百旺云 / 诺诺网）
      ↓ 回调 / 轮询
  写回 ERPNext 发票字段
```

**Frappe Hook 监听销售发票提交事件：**

在自定义 App 的 `hooks.py` 中注册事件：

```python
# your_app/hooks.py

doc_events = {
    "Sales Invoice": {
        "on_submit": "your_app.golden_tax.on_invoice_submit",
    }
}
```

**核心处理函数：**

```python
# your_app/golden_tax.py

import frappe
import requests
import json


GOLDEN_TAX_API_URL = frappe.conf.get("golden_tax_api_url", "https://api.baiwang.com/v2/invoice")
GOLDEN_TAX_APP_KEY = frappe.conf.get("golden_tax_app_key", "")
GOLDEN_TAX_APP_SECRET = frappe.conf.get("golden_tax_app_secret", "")


def on_invoice_submit(doc, method):
    """销售发票提交时，自动推送到金税 API 开票"""
    # 仅处理需要开票的发票（可按自定义字段过滤）
    if doc.get("invoice_type") not in ("增值税专票", "增值税普票"):
        return

    payload = build_invoice_payload(doc)

    try:
        response = call_golden_tax_api(payload)
        write_back_invoice_info(doc, response)
    except Exception as e:
        frappe.log_error(
            title="金税开票失败",
            message=f"发票 {doc.name} 推送金税 API 失败：{str(e)}"
        )
        frappe.throw(f"金税开票失败，请检查错误日志：{str(e)}")


def build_invoice_payload(doc):
    """将 ERPNext 销售发票转换为金税 API 所需格式"""
    items = []
    for item in doc.items:
        items.append({
            "goodsName": item.item_name,
            "taxClassificationCode": frappe.db.get_value(
                "Item", item.item_code, "tax_classification_code"
            ) or "",
            "quantity": item.qty,
            "unitPrice": item.rate,
            "taxRate": _get_tax_rate(doc),
            "amount": item.net_amount,
            "taxAmount": item.tax_amount if hasattr(item, "tax_amount") else 0,
        })

    return {
        "invoiceType": "01" if doc.invoice_type == "增值税专票" else "04",
        "buyerName": doc.customer_name,
        "buyerTaxNo": doc.get("tax_id") or "",
        "buyerAddress": doc.get("customer_address") or "",
        "buyerBankAccount": doc.get("customer_bank_account") or "",
        "totalAmount": doc.grand_total,
        "totalTaxAmount": doc.total_taxes_and_charges,
        "items": items,
        "remark": doc.get("remarks") or "",
    }


def call_golden_tax_api(payload):
    """调用金税服务商 REST API"""
    headers = {
        "Content-Type": "application/json",
        "appKey": GOLDEN_TAX_APP_KEY,
        "appSecret": GOLDEN_TAX_APP_SECRET,
    }
    resp = requests.post(
        GOLDEN_TAX_API_URL,
        headers=headers,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        timeout=30,
    )
    resp.raise_for_status()
    result = resp.json()

    if result.get("code") != "0000":
        raise Exception(f"金税 API 返回错误：{result.get('message', '未知错误')}")

    return result.get("data", {})


def write_back_invoice_info(doc, api_response):
    """将金税返回的发票信息回写到 ERPNext"""
    frappe.db.set_value("Sales Invoice", doc.name, {
        "golden_tax_invoice_code": api_response.get("invoiceCode", ""),
        "golden_tax_invoice_no": api_response.get("invoiceNo", ""),
        "golden_tax_check_code": api_response.get("checkCode", ""),
        "golden_tax_issue_time": api_response.get("issueTime", ""),
        "golden_tax_status": "已开票",
    })
    frappe.db.commit()


def _get_tax_rate(doc):
    """从发票税务模板中提取税率"""
    for tax in doc.taxes:
        if tax.charge_type == "On Net Total":
            return abs(tax.rate)
    return 13  # 默认 13%
```

**site_config.json 配置（敏感信息不入代码）：**

```json
{
  "golden_tax_api_url": "https://api.baiwang.com/v2/invoice",
  "golden_tax_app_key": "your_app_key_here",
  "golden_tax_app_secret": "your_app_secret_here"
}
```

**Sales Invoice 需要的自定义字段清单：**

| 字段名 | 标签 | 类型 | 说明 |
|--------|------|------|------|
| `invoice_type` | 发票类型 | Select | 增值税专票 / 增值税普票 |
| `golden_tax_invoice_code` | 发票代码 | Data | 金税返回，20 位 |
| `golden_tax_invoice_no` | 发票号码 | Data | 金税返回，8 位 |
| `golden_tax_check_code` | 校验码 | Data | 专票无此字段，普票必填 |
| `golden_tax_issue_time` | 开票时间 | Datetime | 金税返回 |
| `golden_tax_status` | 开票状态 | Select | 待开票 / 已开票 / 开票失败 |

---

### 方案三：frappe-nest 集成

**适用场景**：企业有多个外部系统需要与 ERPNext 集成，希望统一管理集成逻辑。

**架构思路：**

[frappe-nest](https://github.com/kingpy-tech) 是青皮科技正在探索的统一集成层，核心思路是：

```
ERPNext
   ↕ Frappe REST API / Webhooks
frappe-nest（集成编排层）
   ↕ 适配器（Adapter）
外部系统（金税、微信支付、钉钉、物流等）
```

金税对接在 frappe-nest 中作为一个独立 Adapter 实现：

```python
# frappe_nest/adapters/golden_tax_adapter.py

class GoldenTaxAdapter:
    """金税系统适配器（百旺云 / 诺诺网通用接口）"""

    def __init__(self, config: dict):
        self.api_url = config["api_url"]
        self.app_key = config["app_key"]
        self.app_secret = config["app_secret"]

    def issue_invoice(self, invoice_data: dict) -> dict:
        """开具发票，返回发票代码和号码"""
        raise NotImplementedError("子类实现具体服务商逻辑")

    def query_invoice(self, invoice_code: str, invoice_no: str) -> dict:
        """查询发票状态"""
        raise NotImplementedError


class BaiwangAdapter(GoldenTaxAdapter):
    """百旺云适配器"""

    def issue_invoice(self, invoice_data: dict) -> dict:
        # 百旺云具体实现
        ...


class NuonuoAdapter(GoldenTaxAdapter):
    """诺诺网适配器"""

    def issue_invoice(self, invoice_data: dict) -> dict:
        # 诺诺网具体实现
        ...
```

**当前状态**：frappe-nest 集成方案仍在规划阶段，后续会有专项文档跟进。现阶段推荐使用方案二（API 中间件）。

---

## 三、注意事项与合规要求

### 数据合规

1. **税收分类编码必填**：金税系统要求每个商品/服务必须有对应的税收分类编码（19 位数字），与税务总局税收分类目录对应。建议在 ERPNext 物料主数据中维护此字段，开票时自动带入，避免手工填写出错或被税务稽查。

2. **价税分离**：中国增值税发票是价税分离格式（不含税金额 + 税额 = 含税金额），ERPNext 默认支持，但要确认「公司设置」中「含税价格」选项与实际开票习惯一致。

3. **发票作废与红冲**：已开具的发票如需作废，必须通过金税系统操作，ERPNext 侧同步更新状态。红字发票（负数发票）需要先在金税系统申请红字信息表，再开具红字发票，ERPNext 对应的退货/贷项凭证需与红字发票号码关联。

4. **电子发票**：2024 年起全面推行全电发票（数电票），不再需要税控盘，通过电子税务局或服务商 API 直接开具。建议新接入的企业直接对接全电发票 API，跳过税控盘方案。

### 安全要求

1. **API 密钥管理**：`app_key` 和 `app_secret` 必须存放在 `site_config.json` 或环境变量中，严禁硬编码进代码仓库。

2. **HTTPS 传输**：所有与金税 API 的通信必须走 HTTPS，禁止明文 HTTP。

3. **日志脱敏**：错误日志中不得记录完整的购方税号、银行账号等敏感信息，必要时做掩码处理。

4. **幂等处理**：网络超时时可能触发重试，需在中间件侧做幂等校验（以 ERPNext 发票编号为唯一键），避免重复开票。

### 测试建议

1. 金税服务商通常提供沙盒环境（测试环境），开发阶段务必使用沙盒，避免在生产环境产生无效发票。
2. 上线前用小额真实发票做端到端验证，确认发票代码、号码、校验码能正确回写 ERPNext。
3. 模拟网络超时、API 返回错误等异常场景，验证错误处理和日志记录是否正常。

---

## 小结

| 方案 | 开发成本 | 适用规模 | 推荐指数 |
|------|----------|----------|----------|
| 手工导出导入 | 零 | 小微企业（< 50 张/月） | ⭐⭐ |
| API 中间件 | 中（1-3 天） | 中小企业（50-500 张/月） | ⭐⭐⭐⭐⭐ |
| frappe-nest 集成 | 高（规划中） | 多系统集成场景 | ⭐⭐⭐（待成熟） |

大多数企业从**方案二**起步是最务实的选择：开发量可控，自动化程度高，出了问题也容易排查。

有问题欢迎在 [GitHub Issues](https://github.com/kingpy-tech/erpnext_china_opc/issues) 提，或加入社区讨论。
