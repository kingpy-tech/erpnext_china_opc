# 项目当前状态快照 (Project Status)

> 面向外部贡献者的项目现状一览。最后更新：2026-03-16

---

## ✅ 已完成功能

### 部署与基建
- Docker Compose 多租户架构（主库 + 沙盒隔离）
- 1Panel 面板安装指南
- 沙盒快照回退玩法（无限回档）

### 本土化配置
- 高新企业专属会计科目表（CSV 导入包）
- 中文汉化修正包（自定义翻译导入）
- 工作区简化与权限配置方案

### 文档与自动化
- MkDocs Material 文档站，在线地址：https://kingpy-tech.github.io/erpnext_china_opc/
- GitHub Actions 自动部署（push to main → 自动构建发布）
- 完整的快速开始指南（5 分钟跑起来）

---

## 📚 文档覆盖率

| 文档 | 状态 |
|------|------|
| `00_Quick_Start.md` | ✅ 完整 |
| `00_ERPNext_Preparation_1Panel.md` | ✅ 完整 |
| `01_ERPNext_Micro_Server_Install.md` | ✅ 完整 |
| `02_Advanced_Backup_Restore_Tenant.md` | ✅ 完整 |
| `03_Chart_of_Accounts_Import.md` | ✅ 完整 |
| `04_Custom_Translation_Import.md` | ✅ 完整 |
| `06_Workspace_Simplification.md` | ✅ 完整 |
| `WHY_CONTRIBUTE.md` | ✅ 完整 |
| `GITHUB_PAGES_SETUP.md` | ✅ 完整 |

---

## 🚀 如何本地运行

**前置条件**：Docker 已安装，端口 8080 未占用，内存 ≥ 4GB。

```bash
# 克隆仓库
git clone https://github.com/kingpy-tech/erpnext_china_opc.git
cd erpnext_china_opc

# 一键启动
docker compose up -d

# 等待初始化（看到 configurator exited with code 0）
docker compose logs -f configurator

# 创建站点
docker compose exec backend bash
bench new-site mysite.localhost \
  --mariadb-root-password admin \
  --admin-password admin \
  --install-app erpnext
exit

# 浏览器访问 http://localhost:8080
# 用户名: Administrator  密码: admin
```

**本地预览文档站**：

```bash
pip install mkdocs-material
mkdocs serve
# 访问 http://127.0.0.1:8000
```

---

## 🤝 如何参与贡献

1. **Fork 仓库** → 创建功能分支 → 提交 PR
2. **Good First Issues**：查看 [标签列表](https://github.com/kingpy-tech/erpnext_china_opc/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22)
3. **文档贡献**：修改 `docs/` 目录下的 Markdown 文件，push 后自动发布
4. **配置包贡献**：在 `config_package/` 下添加新的本土化配置资产

贡献类型不限：代码、文档、翻译、测试反馈、社区运营均欢迎。

---

## 📋 已知待办

- [ ] `05_xxx.md` 文档序号存在跳号（04 → 06），待补充第 05 篇
- [ ] HRMS 模块本土化配置文档尚未完成
- [ ] 微信支付 / 支付宝对接方案（规划中）
- [ ] 电子发票（e-fapiao）集成探索
- [ ] 自动更新脚本（`update_erpnext.sh`）需补充错误处理与回滚逻辑
- [ ] GitHub Pages 首次启用需在仓库 Settings → Pages 手动选择 `gh-pages` 分支

---

*Powered by 青皮（上海）信息科技有限公司*
