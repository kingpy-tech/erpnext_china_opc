# ERPNext 安全加固实战指南

> 本文面向已完成 ERPNext 基础部署的运维人员，系统梳理访问控制、网络防护、账号安全、数据保护、API 管控、审计合规等核心安全维度，并提供可直接落地的配置示例。

---

## 1. 访问控制

### 角色权限

ERPNext 基于角色（Role）的权限体系是第一道防线。遵循最小权限原则，按岗位创建角色，避免直接使用 Administrator。

```python
# 通过 Frappe 控制台批量检查高权限角色
import frappe
users = frappe.get_all("Has Role", filters={"role": "System Manager"}, fields=["parent"])
print([u.parent for u in users])
```

### 字段级权限

对薪资、银行账号等敏感字段启用字段级权限（Field Level Permission）：

1. 进入 **自定义 → 自定义字段**，找到目标字段
2. 勾选 **只读** 或设置 **权限级别（Permlevel）**为 `1`
3. 在 **角色权限管理器** 中，为对应角色设置 Permlevel 1 的读/写权限

### 文档级权限

使用 **用户权限（User Permission）** 限制用户只能访问特定公司/部门的单据：

```
设置路径：设置 → 用户权限
示例：限制销售员只能查看自己负责的客户
  允许类型：Customer
  用户：sales.rep@example.com
  值：客户A
```

---

## 2. 网络安全

### HTTPS 强制跳转

在 Nginx 配置中强制 HTTP → HTTPS 跳转，并启用 HSTS：

```nginx
server {
    listen 80;
    server_name erp.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name erp.example.com;
    ssl_certificate     /etc/ssl/certs/erp.crt;
    ssl_certificate_key /etc/ssl/private/erp.key;
    ssl_protocols       TLSv1.2 TLSv1.3;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
}
```

### 防火墙配置

使用 `ufw` 仅开放必要端口：

```bash
ufw default deny incoming
ufw allow 22/tcp    # SSH（建议改为非标准端口）
ufw allow 443/tcp   # HTTPS
ufw allow 80/tcp    # HTTP（仅用于跳转）
ufw enable
```

### IP 白名单

在 `site_config.json` 中限制管理后台访问来源：

```json
{
  "allow_cors": "",
  "admin_ip_whitelist": ["192.168.1.0/24", "100.84.176.0/24"]
}
```

---

## 3. 账号安全

### 强密码策略

在 **系统设置** 中配置密码策略：

```
最小密码长度：12
必须包含：大写字母、小写字母、数字、特殊字符
密码有效期：90 天
历史密码不可重用：5 次
```

### 双因素认证（2FA）

```
设置路径：系统设置 → 双因素认证
推荐方式：OTP App（Google Authenticator / Authy）
强制范围：所有 System Manager 和 Accounts Manager 角色用户
```

### 登录审计

ERPNext 默认记录登录日志，可通过以下方式查询：

```python
# 查询最近 7 天的登录记录
import frappe
from frappe.utils import add_days, today
logs = frappe.get_all(
    "Activity Log",
    filters={"operation": "Login", "creation": [">", add_days(today(), -7)]},
    fields=["user", "creation", "ip_address", "status"]
)
```

---

## 4. 数据安全

### 数据库加密

MariaDB 启用静态加密（Encryption at Rest）：

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf
[mysqld]
plugin-load-add = file_key_management
file_key_management_filename = /etc/mysql/encryption/keyfile
innodb_encrypt_tables = ON
innodb_encrypt_log = ON
```

### 敏感字段脱敏

对手机号、身份证等字段在展示层做脱敏处理：

```python
def mask_phone(phone):
    """138****8888"""
    return phone[:3] + "****" + phone[-4:] if phone and len(phone) >= 7 else "***"
```

### 数据备份策略

```bash
# 每日自动备份并上传至对象存储
bench --site erp.example.com backup --with-files
# 建议保留策略：本地 7 天，远端 90 天
# 结合 12_Backup_and_Recovery.md 中的完整方案执行
```

---

## 5. API 安全

### API Key 管理

```
生成路径：用户设置 → API Access → 生成 API Key
原则：
  - 每个集成系统使用独立的专用账号
  - 定期轮换（建议 90 天）
  - 不使用 Administrator 账号的 API Key
```

### 速率限制

在 `common_site_config.json` 中配置：

```json
{
  "rate_limit": {
    "limit": 300,
    "window": 60
  }
}
```

### CORS 配置

仅允许受信任域名跨域请求：

```json
{
  "allow_cors": "https://app.example.com"
}
```

---

## 6. 审计日志

### 操作记录

启用文档变更追踪：

```
设置路径：自定义 → 文档类型 → 目标 DocType → 勾选"追踪变更"
重点追踪：Journal Entry、Payment Entry、Employee、User
```

### 异常告警

配置登录失败告警（通过 Frappe 通知或外部 SIEM）：

```python
# hooks.py 中注册登录失败钩子
on_login_failed = "myapp.security.on_login_failed"

# security.py
def on_login_failed(login_manager):
    user = login_manager.user
    frappe.sendmail(
        recipients=["security@example.com"],
        subject=f"[告警] 账号 {user} 登录失败",
        message=f"IP: {frappe.local.request_ip}"
    )
```

### 合规报告

定期导出审计日志用于合规检查：

```bash
bench --site erp.example.com execute frappe.utils.data.export_csv \
  --args '["Activity Log", {}]' > audit_$(date +%Y%m).csv
```

---

## 7. 中国合规

### 等保 2.0

ERPNext 部署需满足等保二级及以上要求的核心控制点：

| 控制域 | 要求 | 对应措施 |
|--------|------|----------|
| 身份鉴别 | 双因素认证 | 启用 OTP 2FA |
| 访问控制 | 最小权限 | 角色+用户权限体系 |
| 安全审计 | 操作日志留存 ≥ 6 个月 | Activity Log + 定期归档 |
| 入侵防范 | 登录失败锁定 | 系统设置中配置尝试次数 |
| 数据完整性 | 传输加密 | TLS 1.2+ 强制 HTTPS |

### 数据安全法合规

- 数据分类分级：在自定义字段中标注数据级别（一般/重要/核心）
- 数据出境：涉及跨境传输需完成安全评估，API 集成需审查数据流向
- 重要数据处理活动需记录并定期审查

### 个人信息保护法（PIPL）

- 员工、客户的手机号、身份证、银行卡号属于个人信息，需最小化采集
- 在系统设置中配置数据保留期限，到期自动脱敏或删除
- 提供数据主体权利响应机制（查询、更正、删除）

---

## 小结

安全加固是持续过程，建议每季度执行一次安全审查，重点检查：用户权限是否存在越权、API Key 是否按期轮换、备份是否可正常恢复、审计日志是否完整留存。结合 [12_Backup_and_Recovery.md](12_Backup_and_Recovery.md) 和 [06_Workspace_Simplification.md](06_Workspace_Simplification.md) 可构建更完整的安全体系。
