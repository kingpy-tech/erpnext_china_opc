# ERPNext v15 → v16 升级指南

> 大白话版本：不是官方文档，是踩过坑之后写给自己人看的。

---

## 升级前必做：备份三件套

别跳过这步，出了问题你会后悔的。

```bash
# 1. 备份数据库（替换 your-site 为你的站点名）
bench --site your-site backup --with-files

# 2. 确认备份文件已生成
ls -lh ~/frappe-bench/sites/your-site/private/backups/

# 3. 把备份文件拷到安全的地方（外部存储或对象存储）
```

如果你用的是 1Panel，也可以直接在面板里触发快照，比命令行更省心。

---

## 正式升级：bench update

```bash
# 切到 frappe-bench 目录
cd ~/frappe-bench

# 拉取最新代码并迁移数据库
bench update --version 16

# 如果只想更新代码不跑迁移（不推荐，仅调试用）
# bench update --pull
```

> **注意**：`bench update --version 16` 会自动处理 Frappe 和 ERPNext 的版本切换，整个过程可能需要 10-30 分钟，取决于你的服务器性能。

---

## HRMS 同步升级

如果你装了 HRMS，必须跟着一起升，否则会有兼容性报错：

```bash
# 进入 HRMS 应用目录
cd ~/frappe-bench/apps/hrms

# 切换到 v16 分支
git checkout version-16
git pull

# 回到 bench 目录执行迁移
cd ~/frappe-bench
bench --site your-site migrate
```

---

## 常见报错处理

### 报错 1：`ModuleNotFoundError` 或依赖缺失

```bash
# 重新安装 Python 依赖
./env/bin/pip install -e apps/frappe
./env/bin/pip install -e apps/erpnext
```

### 报错 2：`PermissionError` 或文件权限问题

```bash
# 修复文件权限（frappe-user 替换为你的系统用户）
sudo chown -R frappe-user:frappe-user ~/frappe-bench
```

### 报错 3：`bench migrate` 卡住或报数据库错误

```bash
# 强制重跑迁移
bench --site your-site migrate --skip-failing

# 查看详细错误日志
bench --site your-site console
```

### 报错 4：前端资源没更新（页面样式乱了）

```bash
bench build --app frappe
bench build --app erpnext
```

---

## 升级后验证清单

升完别急着交差，跑一遍这个清单：

- [ ] 登录后台，确认版本号显示为 v16.x.x
- [ ] 打开「设置 → 关于」，Frappe 和 ERPNext 版本一致
- [ ] 随机打开几张单据（销售订单、采购订单、工资单），确认能正常加载
- [ ] 跑一次「工具 → 数据完整性检查」，无严重错误
- [ ] 确认自定义字段、自定义脚本、Print Format 没有丢失
- [ ] 如果有中文翻译补丁，重新导入一遍（参考 [04 自定义翻译补全指南](04_Custom_Translation_Import.md)）
- [ ] 检查定时任务（Scheduler）是否正常运行：`bench doctor`

---

## 一句话总结

升级 = 备份 → `bench update --version 16` → HRMS 跟进 → 验证清单过一遍。出了问题先看日志，`bench --site your-site console` 是你的好朋友。
