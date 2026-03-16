# ERPNext 性能优化实战指南

在生产环境中，ERPNext 的性能问题往往来自多个层面的叠加。本文从诊断到调优，系统梳理各关键环节的优化策略。

---

## 1. 性能瓶颈诊断

### 慢查询定位

开启 MariaDB 慢查询日志，找出耗时 SQL：

```ini
# /etc/mysql/mariadb.conf.d/50-server.cnf
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
log_queries_not_using_indexes = 1
```

重启后用 `mysqldumpslow` 分析：

```bash
mysqldumpslow -s t -t 20 /var/log/mysql/slow.log
```

### 内存与 CPU 监控

```bash
# 实时查看 Frappe worker 资源占用
top -p $(pgrep -d',' -f "frappe worker")

# 内存快照
bench --site your-site.com execute frappe.utils.bench_helper.get_memory_usage
```

### 网络延迟排查

```bash
# 检查 Redis 连接延迟
redis-cli --latency -h 127.0.0.1 -p 11000

# 检查数据库连接数
mysql -e "SHOW STATUS LIKE 'Threads_connected';"
```

---

## 2. 数据库优化

### 索引策略

针对高频查询字段补充索引，以 `tabSales Invoice` 为例：

```sql
-- 按客户+状态查询发票
ALTER TABLE `tabSales Invoice`
  ADD INDEX idx_customer_status (customer, status);

-- 按日期范围查询
ALTER TABLE `tabSales Invoice`
  ADD INDEX idx_posting_date (posting_date);
```

> **注意**：索引过多会拖慢写入，建议只对 WHERE / ORDER BY 高频字段建索引。

### 查询优化

避免在 Frappe ORM 中使用 `get_all` 不加 `filters` 的全表扫描：

```python
# ❌ 危险：全表扫描
frappe.get_all("Sales Invoice")

# ✅ 正确：加过滤条件和字段限制
frappe.get_all(
    "Sales Invoice",
    filters={"status": "Unpaid", "posting_date": [">", "2024-01-01"]},
    fields=["name", "customer", "grand_total"],
    limit=100,
)
```

### 定期清理

```bash
# 清理过期日志（保留 90 天）
bench --site your-site.com execute \
  frappe.core.doctype.error_log.error_log.clear_error_logs \
  --kwargs '{"days": 90}'

# 清理活动日志
bench --site your-site.com execute \
  frappe.desk.doctype.activity_log.activity_log.clear_activity_logs \
  --kwargs '{"days": 90}'
```

---

## 3. Redis 缓存配置

Frappe 使用两个 Redis 实例：`cache`（端口 13000）和 `queue`（端口 11000）。

### 缓存策略

```bash
# bench/config/redis_cache.conf
maxmemory 512mb
maxmemory-policy allkeys-lru
```

### 缓存预热

站点重启后主动预热常用数据：

```python
# 在 bench console 中执行
import frappe
frappe.init(site="your-site.com")
frappe.connect()

# 预热翻译缓存
frappe.get_lang_dict("doctype", "Sales Invoice")

# 预热元数据缓存
frappe.get_meta("Sales Invoice")
```

### 缓存失效

```bash
# 清除全站缓存
bench --site your-site.com clear-cache

# 仅清除特定 DocType 缓存
bench --site your-site.com execute frappe.clear_document_cache \
  --kwargs '{"doctype": "Sales Invoice"}'
```

---

## 4. Nginx 优化

### 静态资源与 gzip

```nginx
# /etc/nginx/conf.d/erpnext.conf（关键片段）
gzip on;
gzip_types text/plain text/css application/javascript application/json;
gzip_min_length 1024;
gzip_comp_level 5;

# 静态资源长缓存
location ~* \.(js|css|png|jpg|woff2)$ {
    expires 30d;
    add_header Cache-Control "public, immutable";
}
```

### 缓存头配置

```nginx
# API 响应不缓存
location /api/ {
    add_header Cache-Control "no-store, no-cache";
    proxy_pass http://127.0.0.1:8000;
}
```

---

## 5. Frappe 应用优化

### 后台任务与队列

将耗时操作移入队列，避免阻塞请求：

```python
# 异步入队
frappe.enqueue(
    "myapp.tasks.heavy_report",
    queue="long",       # short / default / long
    timeout=600,
    site=frappe.local.site,
    doc_name="SO-0001",
)
```

### 定时任务

在 `hooks.py` 中合理分配定时任务频率：

```python
# hooks.py
scheduler_events = {
    "daily": [
        "myapp.tasks.sync_exchange_rate",   # 每日同步汇率
    ],
    "weekly": [
        "myapp.tasks.archive_old_logs",     # 每周归档日志
    ],
}
```

---

## 6. 监控与告警

### Supervisor 进程监控

```bash
# 查看所有 worker 状态
sudo supervisorctl status

# 重启单个 worker
sudo supervisorctl restart erpnext-worker-default:
```

### 日志分析

```bash
# 实时跟踪错误日志
tail -f /home/frappe/frappe-bench/logs/worker.error.log

# 统计最近 1 小时错误频率
awk '/ERROR/' /home/frappe/frappe-bench/logs/web.error.log | \
  grep "$(date +'%Y-%m-%d %H')" | wc -l
```

### 性能基准

定期用 `bench` 内置工具跑基准，记录响应时间趋势：

```bash
# 页面加载基准测试
bench --site your-site.com run-tests \
  --app frappe --module frappe.tests.test_perf
```

> **建议**：将基准数据写入 Grafana / Prometheus，设置 P95 响应时间 > 3s 触发告警。

---

## 小结

| 层级 | 核心手段 | 预期收益 |
|------|---------|---------|
| 数据库 | 慢查询 + 索引 + 定期清理 | 查询提速 50%+ |
| Redis | LRU 策略 + 缓存预热 | 重复请求命中率 >90% |
| Nginx | gzip + 静态缓存 | 带宽节省 60%+ |
| Frappe | 异步队列 + 合理调度 | 请求响应时间降低 |
| 监控 | Supervisor + 日志 + 基准 | 问题提前发现 |
