# ERPNext 与微信生态集成指南

微信生态是中国企业数字化的核心入口。本文介绍如何将 ERPNext 与公众号、小程序、企业微信、微信支付深度集成，打通从审批通知到移动收款的完整业务链路。

---

## 一、微信生态概述

| 产品 | 核心能力 | ERP 集成价值 |
|------|----------|-------------|
| 企业微信 | 消息/审批/考勤 | 内部流程通知与审批 |
| 微信支付 | 收款/退款/对账 | 销售收款闭环 |
| 小程序 | 移动端应用 | 移动 ERP 入口 |
| 公众号 | 图文/客服/推送 | 客户服务与营销 |

集成架构采用「ERPNext → 中间件 → 微信 API」三层模型，中间件负责签名鉴权、消息队列与重试，避免在 Frappe 内直接耦合微信 SDK。

---

## 二、企业微信集成

### 2.1 消息通知

在 `hooks.py` 注册单据事件，触发企业微信机器人推送：

```python
# your_app/hooks.py
doc_events = {
    "Purchase Order": {
        "on_submit": "your_app.wecom.notify_po_submitted"
    },
    "Leave Application": {
        "on_submit": "your_app.wecom.notify_leave_submitted"
    }
}
```

```python
# your_app/wecom.py
import requests, frappe

WECOM_WEBHOOK = frappe.conf.get("wecom_webhook_url")

def notify_po_submitted(doc, method):
    msg = {
        "msgtype": "markdown",
        "markdown": {
            "content": (
                f"### 采购订单待审批\n"
                f"- 单号：**{doc.name}**\n"
                f"- 供应商：{doc.supplier}\n"
                f"- 金额：¥{doc.grand_total:,.2f}\n"
                f"- 提交人：{doc.owner}"
            )
        }
    }
    requests.post(WECOM_WEBHOOK, json=msg, timeout=5)
```

### 2.2 审批流对接

企业微信审批回调通过中间件转为 Frappe API 调用：

```python
# your_app/api.py
@frappe.whitelist(allow_guest=False)
def wecom_approval_callback(sp_no, status):
    """企业微信审批回调：status=2 同意，status=3 拒绝"""
    doc_name = frappe.db.get_value(
        "Purchase Order", {"wecom_sp_no": sp_no}, "name"
    )
    if not doc_name:
        return {"status": "not_found"}
    doc = frappe.get_doc("Purchase Order", doc_name)
    if status == "2":
        doc.submit()
    else:
        doc.add_comment("Comment", "企业微信审批已拒绝")
    return {"status": "ok"}
```

### 2.3 打卡考勤同步

通过企业微信「打卡 API」定时拉取考勤数据，写入 ERPNext Attendance：

```python
# your_app/tasks.py（配合 scheduler_events 每日执行）
def sync_wecom_attendance():
    from your_app.wecom import fetch_checkin_data
    records = fetch_checkin_data()  # 调用企业微信 /checkin/getcheckindata
    for r in records:
        frappe.get_doc({
            "doctype": "Employee Checkin",
            "employee": r["employee_id"],
            "time": r["checkin_time"],
            "log_type": "IN" if r["type"] == 1 else "OUT"
        }).insert(ignore_permissions=True)
```

---

## 三、微信支付集成

### 3.1 支付接口

推荐使用 `wechatpayv3` 库封装 V3 API：

```python
# your_app/wxpay.py
from wechatpayv3 import WeChatPay, WeChatPayType

wxpay = WeChatPay(
    wechatpay_type=WeChatPayType.NATIVE,
    mchid=frappe.conf.wxpay_mchid,
    private_key=frappe.conf.wxpay_private_key,
    cert_serial_no=frappe.conf.wxpay_cert_serial_no,
    apiv3_key=frappe.conf.wxpay_apiv3_key,
    appid=frappe.conf.wxpay_appid,
)

def create_payment(sales_invoice):
    code, msg = wxpay.pay(
        description=f"订单 {sales_invoice.name}",
        out_trade_no=sales_invoice.name,
        amount={"total": int(sales_invoice.grand_total * 100)},
        pay_type=WeChatPayType.NATIVE,
    )
    return msg  # 返回 code_url 生成二维码
```

### 3.2 退款与对账

```python
def refund_payment(payment_entry):
    wxpay.refund(
        out_trade_no=payment_entry.reference_no,
        out_refund_no=f"RF-{payment_entry.name}",
        amount={"refund": int(payment_entry.paid_amount * 100), "total": int(payment_entry.paid_amount * 100)},
        reason="客户申请退款"
    )

def reconcile_daily(date_str):
    """拉取微信账单与 ERPNext Payment Entry 逐笔核对"""
    code, bill = wxpay.trade_bill(bill_date=date_str, bill_type="ALL")
    # 解析 CSV 账单，与 frappe.db.get_list("Payment Entry") 比对
```

---

## 四、小程序集成

小程序作为移动端 ERP 入口，通过 Frappe REST API 与后端通信。

**核心场景：**

- **扫码入库**：扫描物料条码 → 调用 `/api/method/your_app.api.stock_entry_by_scan`，自动创建 Stock Entry
- **移动审批**：小程序拉取待审批列表 → 展示详情 → 调用 `/api/resource/Purchase Order/{name}` 提交审批动作
- **登录鉴权**：微信 `code` → 后端换取 `openid` → 映射 ERPNext User → 返回 JWT

```python
@frappe.whitelist(allow_guest=True)
def wx_login(code):
    import requests
    resp = requests.get(
        "https://api.weixin.qq.com/sns/jscode2session",
        params={"appid": frappe.conf.wx_appid, "secret": frappe.conf.wx_secret,
                "js_code": code, "grant_type": "authorization_code"}
    ).json()
    openid = resp.get("openid")
    user = frappe.db.get_value("User", {"wx_openid": openid}, "name")
    if not user:
        frappe.throw("未绑定账号，请联系管理员")
    frappe.local.login_manager.login_as(user)
    return {"token": frappe.generate_hash(user, 20)}
```

---

## 五、公众号集成

**客户服务**：通过公众号客服消息 API，在销售订单状态变更时主动推送模板消息给客户微信。

**营销推送**：结合 ERPNext CRM 客户分组，批量调用「订阅消息」接口发送促销通知（需用户授权订阅）。

```python
def send_order_template_msg(customer_openid, order_name, status):
    payload = {
        "touser": customer_openid,
        "template_id": frappe.conf.wx_template_order_status,
        "data": {
            "thing1": {"value": order_name},
            "phrase2": {"value": status},
        }
    }
    access_token = get_access_token()  # 缓存至 Redis，7200s 刷新
    requests.post(
        f"https://api.weixin.qq.com/cgi-bin/message/template/send?access_token={access_token}",
        json=payload, timeout=5
    )
```

---

## 六、技术实现：Frappe Hooks + 微信 API + 中间件架构

```
ERPNext (Frappe)
    │  doc_events / scheduler_events
    ▼
your_app/wecom.py & wxpay.py   ← 业务逻辑层
    │  HTTP / SDK
    ▼
中间件（可选：Redis Queue + Worker）
    │  签名 / 重试 / 限流
    ▼
微信 API（企业微信 / 微信支付 / 公众号）
```

敏感配置（AppID、Secret、私钥）统一存放于 `site_config.json`，通过 `frappe.conf.get()` 读取，禁止硬编码。

---

## 七、注意事项

- **API 频率限制**：企业微信机器人每分钟 20 条；公众号模板消息每日有配额上限，批量推送需错峰。
- **access_token 管理**：公众号/小程序 token 有效期 7200s，必须集中缓存（Redis），多进程环境下避免并发刷新。
- **回调安全**：所有微信回调接口需验证签名（`msg_signature` 或 V3 支付签名），拒绝未签名请求。
- **数据合规**：用户 openid、手机号等个人信息需加密存储，不得明文写入 ERPNext 标准字段日志。
- **沙箱测试**：微信支付提供沙箱环境，上线前务必完成完整支付→退款→对账流程验证。
