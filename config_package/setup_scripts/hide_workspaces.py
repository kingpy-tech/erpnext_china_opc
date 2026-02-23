"""
hide_workspaces.py — 一人公司 Workspace 精简脚本

用法 (Docker 部署):
  # 方式1: 通过 REST API (推荐，无需进入容器)
  # 先登录获取 cookie，再逐个 PUT 隐藏

  # 方式2: 通过 bench execute (适合有链接验证错误的 Workspace)
  docker exec <backend> bench --site <site> execute \
    frappe.db.set_value --args '["Workspace", "<name>", "is_hidden", 1]'

保留的 8 个核心 Workspace:
  - Home: 首页仪表盘
  - Selling: 销售/报价/合同
  - Buying: 采购/费用
  - Invoicing: 开票/应收应付
  - Financial Reports: 财务报表
  - Salary Payout: 给自己发工资
  - Projects: 项目管理
  - ERPNext Settings: 系统设置

隐藏的 21 个 Workspace:
  Assets, Build, CRM, Employee Lifecycle, Expense Claims,
  HR, Integrations, Leaves, Manufacturing, Overview,
  Performance, Quality, Recruitment, Shift & Attendance,
  Stock, Subcontracting, Support, Tax & Benefits,
  Users, Website, Welcome Workspace
"""

# 一人公司需要保留的 Workspace
KEEP_VISIBLE = {
    "Home",
    "Selling",
    "Buying",
    "Invoicing",
    "Financial Reports",
    "Salary Payout",
    "Projects",
    "ERPNext Settings",
}

# 需要隐藏的 Workspace（完整列表）
HIDE_LIST = [
    "Assets", "Build", "CRM", "Employee Lifecycle",
    "Expense Claims", "HR", "Integrations", "Leaves",
    "Manufacturing", "Overview", "Performance", "Quality",
    "Recruitment", "Shift & Attendance", "Stock",
    "Subcontracting", "Support", "Tax & Benefits",
    "Users", "Website", "Welcome Workspace",
]
