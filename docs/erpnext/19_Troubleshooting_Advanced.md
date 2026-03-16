# ERPNext 进阶排障手册：生产环境常见问题与解决方案

本文汇总生产环境中最常见的 ERPNext 故障场景，提供可直接执行的排障命令与解决思路。

---

## 1. 性能问题

### 慢查询诊断

```bash
# 开启 MariaDB 慢查询日志
mysql -u root -p -e "SET GLOBAL slow_query_log = 'ON'; SET GLOBAL long_query_time = 2;"

# 查看慢查询日志
tail -f /var/log/mysql/mysql-slow.log

# 用 bench 内置工具分析
bench --site your-site.com execute frappe.utils.doctor
```

### 内存泄漏排查

```bash
# 查看 worker 进程内存占用
ps aux --sort=-%mem | grep -E 'worker|gunicorn' | head -20

# 重启 worker 释放内存
bench restart
supervisorctl restart all
```

### CPU 飙升处理

```bash
# 定位高 CPU 进程
top -b -n 1 | grep -E 'worker|redis|mysql'

# 检查是否有失控的后台任务
bench --site your-site.com execute frappe.utils.background_jobs.get_jobs
```

---

## 2. 数据库问题

### 锁表诊断与解除

```bash
# 查看当前锁表情况
mysql -u root -p -e "SHOW PROCESSLIST;" | grep -i lock

# 查看 InnoDB 锁等待
mysql -u root -p -e "SELECT * FROM information_schema.INNODB_LOCKS\G"

# 强制终止阻塞进程（替换 <pid>）
mysql -u root -p -e "KILL <pid>;"
```

### 连接池耗尽

编辑 `common_site_config.json`，调整连接池参数：

```json
{
  "db_host": "localhost",
  "redis_cache": "redis://localhost:13000",
  "socketio_port": 9000,
  "db_pool_size": 20,
  "db_max_overflow": 10
}
```

```bash
bench restart
```

### 数据不一致修复

```bash
# 重建文档链接完整性
bench --site your-site.com migrate

# 修复损坏的单据状态
bench --site your-site.com execute frappe.utils.doctor --args "['--fix-missing-patched-files']"
```

---

## 3. 邮件问题

### SMTP 配置验证

在 ERPNext 后台 → 邮件域名 → 测试连接。若失败，用命令行验证：

```bash
# 测试 SMTP 连通性
python3 -c "
import smtplib
s = smtplib.SMTP_SSL('smtp.example.com', 465)
s.login('user@example.com', 'password')
print('SMTP OK')
s.quit()
"
```

### 邮件队列清理

```bash
# 查看积压队列
bench --site your-site.com execute frappe.email.queue.flush

# 清除失败邮件（谨慎操作）
bench --site your-site.com execute "frappe.db.sql" --args "['DELETE FROM \`tabEmail Queue\` WHERE status=\"Error\"']"
bench --site your-site.com execute frappe.db.commit
```

---

## 4. 打印问题

### PDF 生成失败

```bash
# 检查 wkhtmltopdf 是否安装
wkhtmltopdf --version

# 重新安装（Ubuntu）
apt-get install -y wkhtmltopdf xvfb

# 测试 PDF 生成
bench --site your-site.com execute frappe.utils.pdf.get_pdf --args "['<h1>Test</h1>']"
```

### 中文乱码修复

确认系统已安装中文字体：

```bash
fc-list | grep -i chinese
# 若无，安装字体
apt-get install -y fonts-wqy-zenhei fonts-wqy-microhei
fc-cache -fv
```

在打印模板的 CSS 中指定字体：

```css
body { font-family: "WenQuanYi Zen Hei", "Microsoft YaHei", sans-serif; }
```

---

## 5. 权限问题

### 角色冲突排查

```bash
# 检查用户的有效权限
bench --site your-site.com execute frappe.permissions.get_valid_perms --args "['Sales Invoice', 'your@user.com']"
```

常见原因：多角色叠加时，`If Owner` 条件与全局权限冲突。解决方案：在角色权限管理器中逐一检查 `Read/Write/Submit` 的条件设置。

### 字段不可见 / 操作被拒绝

1. 后台 → 角色权限管理器 → 搜索对应 DocType
2. 检查字段级权限（Field Level Permissions）
3. 清除权限缓存：

```bash
bench --site your-site.com clear-cache
bench --site your-site.com clear-website-cache
```

---

## 6. 升级问题

### 迁移失败回滚

```bash
# 查看迁移错误
bench --site your-site.com migrate 2>&1 | tee /tmp/migrate.log

# 从备份恢复（替换备份文件名）
bench --site your-site.com restore /home/frappe/backups/your-site_backup.sql.gz
```

### 依赖冲突处理

```bash
# 重建 Python 虚拟环境
cd /home/frappe/frappe-bench
pip install --upgrade pip
bench setup requirements

# 检查 app 版本兼容性
bench version
```

---

## 7. 日志分析

```bash
# 实时查看应用错误日志
tail -f /home/frappe/frappe-bench/logs/error.log

# 查看定时任务日志
tail -f /home/frappe/frappe-bench/logs/scheduler.log

# 查看后台 worker 日志
tail -f /home/frappe/frappe-bench/logs/worker.log

# 过滤关键错误
grep -E 'ERROR|CRITICAL|Traceback' /home/frappe/frappe-bench/logs/error.log | tail -50

# 统计错误频率（辅助定位高频问题）
grep 'ERROR' /home/frappe/frappe-bench/logs/error.log | awk '{print $1, $2}' | sort | uniq -c | sort -rn | head -20
```

---

> 遇到本文未覆盖的问题，可在 [GitHub Issues](https://github.com/kingpy-tech/erpnext_china_opc/issues) 提交，或参考 [ERPNext 官方论坛](https://discuss.frappe.io)。
