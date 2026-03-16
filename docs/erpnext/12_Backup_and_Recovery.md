# ERPNext 备份与灾难恢复实战指南

生产环境的数据安全是 ERP 系统运维的底线。本文覆盖从日常备份策略到灾难恢复演练的完整链路，帮助你在最短时间内恢复业务。

---

## 1. 备份策略设计

在制定备份策略前，先明确两个核心指标：

- **RPO（Recovery Point Objective）**：可接受的最大数据丢失时间窗口。生产环境建议 ≤ 1 小时。
- **RTO（Recovery Time Objective）**：从故障发生到业务恢复的最大允许时间。建议 ≤ 4 小时。

| 备份类型 | 频率 | 保留周期 | 适用场景 |
|----------|------|----------|----------|
| 全量备份 | 每日 1 次（凌晨） | 7 天本地 + 30 天云端 | 基线恢复 |
| 增量备份 | 每小时 | 24 小时 | 细粒度回滚 |
| 数据库快照 | 每 6 小时 | 3 天 | 数据库级恢复 |

---

## 2. bench backup 命令详解

`bench backup` 是 ERPNext 官方备份工具，会同时备份数据库和文件。

```bash
# 进入 bench 目录
cd /home/frappe/frappe-bench

# 备份单个 site（含附件）
bench --site your-site.com backup --with-files

# 备份并压缩
bench --site your-site.com backup --with-files --compress

# 备份所有 site
bench backup-all-sites --with-files

# 查看备份文件位置
ls -lh sites/your-site.com/private/backups/
```

备份文件命名格式：`20240316_080000-your-site-database.sql.gz`

---

## 3. 自动化备份：cron 定时任务

### 3.1 配置 cron

```bash
# 编辑 frappe 用户的 crontab
crontab -e -u frappe

# 每天凌晨 2 点全量备份（含文件）
0 2 * * * cd /home/frappe/frappe-bench && bench backup-all-sites --with-files >> /var/log/frappe-backup.log 2>&1

# 每小时增量数据库备份
0 * * * * cd /home/frappe/frappe-bench && bench backup-all-sites >> /var/log/frappe-backup.log 2>&1
```

### 3.2 上传至阿里云 OSS

```bash
# 安装 ossutil
wget https://gosspublic.alicdn.com/ossutil/1.7.14/ossutil64 -O /usr/local/bin/ossutil
chmod +x /usr/local/bin/ossutil

# 配置认证
ossutil config -e oss-cn-shanghai.aliyuncs.com -i <AccessKeyId> -k <AccessKeySecret>

# 同步备份目录到 OSS
ossutil sync /home/frappe/frappe-bench/sites/your-site.com/private/backups/ \
  oss://your-bucket/erpnext-backups/ --delete
```

### 3.3 上传至腾讯云 COS

```bash
# 安装 coscli
pip install coscmd

# 配置
coscmd config -a <SecretId> -s <SecretKey> -b your-bucket-1234567890 -r ap-shanghai

# 上传备份
coscmd upload -r /home/frappe/frappe-bench/sites/your-site.com/private/backups/ /erpnext-backups/
```

将上述命令加入 cron，在 `bench backup` 之后执行，实现备份完自动异地存储。

---

## 4. 数据库备份与恢复

### 4.1 MySQL 直接 dump

```bash
# 导出（推荐在低峰期执行）
mysqldump -u root -p \
  --single-transaction \
  --routines \
  --triggers \
  _your_site_com > /tmp/erpnext_$(date +%Y%m%d).sql

# 压缩
gzip /tmp/erpnext_$(date +%Y%m%d).sql
```

### 4.2 数据库恢复

```bash
# 解压
gunzip /tmp/erpnext_20240316.sql.gz

# 恢复到数据库
mysql -u root -p _your_site_com < /tmp/erpnext_20240316.sql

# 或使用 bench restore（推荐，会自动处理权限）
bench --site your-site.com restore /path/to/20240316_080000-your-site-database.sql.gz
```

---

## 5. 文件备份：sites 目录与附件

ERPNext 的关键文件目录：

```
frappe-bench/
├── sites/
│   └── your-site.com/
│       ├── site_config.json   # 站点配置（含数据库密码）
│       ├── private/
│       │   ├── backups/       # bench backup 输出目录
│       │   └── files/         # 私有附件
│       └── public/
│           └── files/         # 公开附件
└── apps/                      # 自定义应用代码
```

```bash
# 备份整个 sites 目录
tar -czf /tmp/sites_backup_$(date +%Y%m%d).tar.gz \
  /home/frappe/frappe-bench/sites/

# 备份自定义应用
tar -czf /tmp/apps_backup_$(date +%Y%m%d).tar.gz \
  /home/frappe/frappe-bench/apps/your_custom_app/
```

---

## 6. 灾难恢复演练

### 6.1 完整恢复流程

```bash
# Step 1：在新服务器安装 frappe-bench 环境
pip install frappe-bench
bench init frappe-bench --frappe-branch version-15

# Step 2：安装 ERPNext
cd frappe-bench
bench get-app erpnext --branch version-15
bench new-site your-site.com

# Step 3：从备份恢复数据库
bench --site your-site.com restore \
  /path/to/20240316_080000-your-site-database.sql.gz \
  --with-public-files /path/to/20240316_080000-your-site-files.tar \
  --with-private-files /path/to/20240316_080000-your-site-private-files.tar

# Step 4：迁移并重启
bench --site your-site.com migrate
bench restart
```

### 6.2 RTO/RPO 达标检查清单

- [ ] 备份文件可从 OSS/COS 正常下载
- [ ] 新环境 bench restore 无报错
- [ ] 关键业务数据（凭证、库存、客户）核对一致
- [ ] 用户可正常登录，权限无异常
- [ ] 定时任务（cron）在新环境重新配置

建议每季度执行一次完整恢复演练，确保 RTO ≤ 4 小时目标可达。

---

## 7. 注意事项

- `site_config.json` 含数据库明文密码，备份文件务必加密存储，OSS/COS bucket 设为私有访问。
- 异地备份保留策略：本地 7 天滚动删除，云端按月归档，保留最近 3 个月。
- 恢复前务必在测试环境验证备份完整性，避免"备份了但恢复不了"的假安全。
