# 常见问题 FAQ

本文档收录 ERPNext 中国本土化部署与使用过程中的高频问题，分三类整理：**部署类**、**本土化类**、**升级类**。

---

## 一、部署类

### Q1：Docker 容器启动失败，日志显示 `connection refused` 或 `exit code 1`

**排查步骤：**

1. 查看具体报错容器：
   ```bash
   docker compose ps
   docker compose logs backend
   docker compose logs db
   ```
2. 最常见原因是 MariaDB 尚未就绪，`backend` 容器抢先启动。等待 30 秒后重试：
   ```bash
   docker compose restart backend
   ```
3. 检查 `docker-compose.yml` 中 `db` 服务的 `healthcheck` 是否配置正确，`backend` 是否依赖 `db` 的健康状态：
   ```yaml
   depends_on:
     db:
       condition: service_healthy
   ```
4. 若仍失败，清理旧数据卷后重建：
   ```bash
   docker compose down -v
   docker compose up -d
   ```

> ⚠️ `-v` 会删除所有数据卷，仅在全新初始化时使用。

---

### Q2：端口冲突，`8080` 端口已被占用

**排查步骤：**

1. 查找占用端口的进程：
   ```bash
   lsof -i :8080
   # 或
   ss -tlnp | grep 8080
   ```
2. 若是其他服务占用，修改 `docker-compose.yml` 中的端口映射：
   ```yaml
   ports:
     - "8081:8080"   # 改为 8081 对外暴露
   ```
3. 若使用 1Panel 面板，在「网站」→「反向代理」中同步修改目标端口。
4. 重启服务生效：
   ```bash
   docker compose up -d
   ```

---

### Q3：数据库连接失败，报错 `Can't connect to MySQL server`

**排查步骤：**

1. 确认 `db` 容器正在运行：
   ```bash
   docker compose ps db
   ```
2. 检查 `common_site_config.json` 中的数据库配置：
   ```bash
   docker compose exec backend cat /home/frappe/frappe-bench/sites/common_site_config.json
   ```
   确认 `db_host`、`db_port`（默认 `3306`）、`db_password` 与 `docker-compose.yml` 中的环境变量一致。
3. 手动测试连通性：
   ```bash
   docker compose exec backend bash -c "mysql -h db -u root -p<密码> -e 'show databases;'"
   ```
4. 若使用外部数据库，确认防火墙/安全组已放行 `3306` 端口，且 `bind-address` 不为 `127.0.0.1`。

---

### Q4：`bench new-site` 执行后浏览器访问显示 404 或空白页

**排查步骤：**

1. 确认站点名称与 `FRAPPE_SITE_NAME_HEADER` 环境变量一致（单租户模式）：
   ```yaml
   environment:
     FRAPPE_SITE_NAME_HEADER: mysite.local
   ```
2. 检查 `frontend` 容器是否正常运行：
   ```bash
   docker compose logs frontend
   ```
3. 强制重建前端静态资源：
   ```bash
   docker compose exec backend bench build --force
   docker compose restart frontend
   ```
4. 清除浏览器缓存后重试（Ctrl+Shift+R）。

---

## 二、本土化类

### Q5：界面中文翻译缺失，部分字段仍显示英文

**解决方案：**

1. 进入 ERPNext 后台：**设置 → 翻译 → 自定义翻译**。
2. 导入项目提供的翻译 CSV 文件：
   ```
   config_package/translations/account_category_zh.csv
   ```
3. 或使用自动化脚本批量导入（推荐）：
   ```bash
   docker compose exec backend bash << 'EOF'
   cd /home/frappe/frappe-bench
   bench --site mysite.local execute frappe.utils.install.import_custom_translations \
     --args "['../config_package/translations/account_category_zh.csv']"
   EOF
   ```
4. 导入后执行缓存清理：
   ```bash
   docker compose exec backend bench --site mysite.local clear-cache
   ```
5. 若仍有遗漏，可在「自定义翻译」中手动新增条目，格式为：`源语言文本 → 中文译文`。

---

### Q6：科目表导入失败，报错 `Duplicate entry` 或 `Parent account not found`

**排查步骤：**

1. 确认导入文件格式正确（使用项目提供的 `Account.csv`）：
   ```
   config_package/chart_of_accounts/Account.csv
   ```
2. 导入前确保公司已创建，且「默认科目表」选择了「中国 - 会计科目表」。
3. 若报 `Duplicate entry`，说明该科目已存在，可在导入设置中勾选「更新已有记录」。
4. 若报 `Parent account not found`，检查 CSV 中父科目名称是否与系统中已有科目完全一致（注意全角/半角空格）。
5. 建议在沙盒环境先行测试导入，确认无误后再在生产环境执行。

---

### Q7：增值税发票相关字段缺失或无法打印

**解决方案：**

1. 确认已安装 `erpnext` 的中国本土化模块（`erpnext.regional.china`）。
2. 在「公司」设置中填写：
   - 纳税人识别号
   - 开户银行及账号
   - 注册地址及电话
3. 发票打印模板路径：**打印格式 → 搜索「Sales Invoice」→ 选择中文模板**。
4. 若打印格式缺失，可从社区下载或手动创建，参考字段：`tax_id`、`company_address`、`bank_account`。
5. 电子发票对接（百旺、航信等）需额外安装第三方 App，目前社区有 `erpnext_china` 等开源方案可参考。

---

### Q8：人民币大写金额显示不正确

**解决方案：**

1. 进入 **设置 → 系统设置**，确认「货币」设置为 `CNY`，「语言」设置为 `zh`。
2. 打印格式中使用 Jinja 模板调用大写函数：
   ```jinja
   {{ doc.grand_total | money_in_words }}
   ```
3. 若大写逻辑有误，可在 `frappe/utils/data.py` 中查看 `money_in_words` 函数，或通过自定义脚本覆盖。
4. 确认 `frappe` 版本 ≥ v15，旧版本的中文大写逻辑存在已知 bug。

---

## 三、升级类

### Q9：如何升级 ERPNext 版本（v15 → v16）

**升级步骤：**

1. **备份数据**（必须）：
   ```bash
   docker compose exec backend bench --site mysite.local backup --with-files
   ```
2. 拉取最新镜像：
   ```bash
   docker compose pull
   ```
3. 停止并重建容器：
   ```bash
   docker compose down
   docker compose up -d
   ```
4. 执行数据库迁移：
   ```bash
   docker compose exec backend bench --site mysite.local migrate
   ```
5. 重建前端资源：
   ```bash
   docker compose exec backend bench build --force
   docker compose restart frontend
   ```
6. 验证版本：
   ```bash
   docker compose exec backend bench version
   ```

> ⚠️ 跨大版本升级（如 v14 → v16）建议先升至 v15，再升至 v16，不要跳版本。

---

### Q10：HRMS 升级注意事项

**升级前检查：**

1. 确认 HRMS 版本与 ERPNext 版本匹配（两者需同为 v16）：
   ```bash
   docker compose exec backend bench version
   ```
2. 备份所有站点数据：
   ```bash
   docker compose exec backend bench --site all backup
   ```

**升级步骤：**

1. 拉取最新 HRMS 镜像（若使用自定义镜像，需重新构建）：
   ```bash
   docker compose pull
   docker compose up -d
   ```
2. 安装/更新 HRMS App：
   ```bash
   docker compose exec backend bench --site mysite.local install-app hrms
   # 若已安装，执行迁移即可
   docker compose exec backend bench --site mysite.local migrate
   ```
3. 检查薪资组件、假期类型等自定义配置是否完整保留。
4. 若升级后薪资计算结果异常，检查「薪资结构」中的公式是否兼容新版 Python 语法。

**常见升级报错：**

| 报错信息 | 原因 | 解决方案 |
|---|---|---|
| `ModuleNotFoundError: hrms` | HRMS 未正确安装 | 重新执行 `install-app hrms` |
| `Column already exists` | 迁移脚本重复执行 | 忽略，不影响功能 |
| `frappe.exceptions.ValidationError` | 数据格式不兼容 | 查看 `bench migrate` 详细日志定位具体字段 |

---

### Q11：升级后前端样式错乱或 JS 报错

**解决方案：**

1. 强制重建前端静态资源：
   ```bash
   docker compose exec backend bench build --force --production
   ```
2. 清理 Redis 缓存：
   ```bash
   docker compose exec backend bench --site mysite.local clear-cache
   docker compose exec backend bench --site mysite.local clear-website-cache
   ```
3. 重启所有服务：
   ```bash
   docker compose restart
   ```
4. 若问题仍存在，检查 `nginx` 配置是否有旧的静态资源缓存规则，必要时在 1Panel 中清理 CDN/代理缓存。

---

### Q12：升级后自定义翻译丢失

**原因：** 部分升级操作会重置 `Custom Translation` 表。

**解决方案：**

1. 升级前导出翻译备份：
   ```bash
   docker compose exec backend bench --site mysite.local export-fixtures
   ```
2. 升级完成后重新导入：
   ```bash
   docker compose exec backend bench --site mysite.local import-fixtures
   ```
3. 或直接重新导入项目翻译 CSV：
   ```
   config_package/translations/account_category_zh.csv
   ```

---

## 获取更多帮助

- 📖 [项目文档站](https://kingpy-tech.github.io/erpnext_china_opc/)
- 💬 [GitHub Issues](https://github.com/kingpy-tech/erpnext_china_opc/issues)
- 🌐 [ERPNext 官方论坛](https://discuss.erpnext.com)
- 📦 [Frappe Docker 官方文档](https://github.com/frappe/frappe_docker)
