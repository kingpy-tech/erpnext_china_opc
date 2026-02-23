# 一人公司 ERPNext Workspace 精简指南

## 痛点

ERPNext 默认安装后有 **29 个 Workspace**，涵盖制造、CRM、招聘、质量管理等大型企业模块。对于一人公司/独立开发者来说，这些模块 99% 用不到，每次打开侧边栏都像在逛超市——找个"开发票"的入口要翻半天。

## 解决方案

只保留 **8 个核心 Workspace**，隐藏其余 21 个。

### 保留清单

| Workspace | 用途 |
|---|---|
| Home | 首页仪表盘 |
| Selling | 销售/报价/合同 |
| Buying | 采购/费用报销 |
| Invoicing | 开票/应收应付 |
| Financial Reports | 资产负债表、利润表 |
| Salary Payout | 给自己发工资 |
| Projects | 项目管理（软件公司刚需）|
| ERPNext Settings | 系统设置 |

### 操作步骤

#### 方式1：REST API 批量隐藏（推荐）

```bash
# 1. 登录获取 cookie
curl -c cookies.txt "http://<your-site>:8080/api/method/login" \
  -d "usr=Administrator&pwd=<password>"

# 2. 批量隐藏
for ws in "Assets" "Build" "CRM" "Employee Lifecycle" \
  "Expense Claims" "HR" "Integrations" "Leaves" \
  "Manufacturing" "Overview" "Quality" "Recruitment" \
  "Shift & Attendance" "Stock" "Subcontracting" \
  "Support" "Tax & Benefits" "Users" "Website"; do
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$ws'))")
  curl -s -b cookies.txt -X PUT \
    "http://<your-site>:8080/api/resource/Workspace/$encoded" \
    -H "Content-Type: application/json" \
    -d '{"is_hidden": 1}'
  echo " -> Hidden: $ws"
done
```

#### 方式2：bench execute 直接更新（适合有链接验证错误的 Workspace）

某些 Workspace（如 `Performance`、`Welcome Workspace`）内部引用了不存在的 DocType，通过 API `PUT` 会触发 `_validate_links()` 报错。这时用 `bench execute` 直接走 SQL 更新：

```bash
# Performance 和 Welcome Workspace 需要用这种方式
docker exec <backend-container> bench --site <site-name> execute \
  frappe.db.set_value --args '["Workspace", "Performance", "is_hidden", 1]'

docker exec <backend-container> bench --site <site-name> execute \
  frappe.db.set_value --args '["Workspace", "Welcome Workspace", "is_hidden", 1]'
```

### 验证

```bash
# 查看当前可见的 Workspace
curl -s -b cookies.txt \
  "http://<your-site>:8080/api/resource/Workspace?fields=%5B%22name%22%2C%22is_hidden%22%5D&limit_page_length=100"
```

预期结果：8 个可见，21 个隐藏。

### 恢复

如果以后业务扩展需要某个模块，随时可以恢复：

```bash
# 通过 API 恢复
curl -s -b cookies.txt -X PUT \
  "http://<your-site>:8080/api/resource/Workspace/Stock" \
  -H "Content-Type: application/json" \
  -d '{"is_hidden": 0}'

# 或通过 bench
docker exec <backend> bench --site <site> execute \
  frappe.db.set_value --args '["Workspace", "Stock", "is_hidden", 0]'
```

## 避坑指南

1. **API 登录 cookie 有效期短**：如果批量操作中途报 403，重新登录获取 cookie 即可。
2. **Performance workspace 有 bug**：ERPNext 17 中 Performance workspace 引用了 `Energy Point Rule` 等 DocType，如果你没启用 Energy Point 功能，通过 API PUT 会报链接验证错误。用 `frappe.db.set_value`（纯 SQL）绕过。
3. **隐藏 ≠ 删除**：`is_hidden=1` 只是从侧边栏隐藏，数据和配置都还在。随时可以恢复。
4. **不要隐藏 Home**：Home 是默认落地页，隐藏后登录会白屏。
5. **Salary Payout vs HR**：一人公司只需要 Salary Payout（发工资），不需要完整的 HR 模块（招聘、绩效、考勤等）。
