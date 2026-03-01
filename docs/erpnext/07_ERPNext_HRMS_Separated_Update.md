# 07 红米服务器：ERPNext 与 HRMS 分离更新方案（替代集成镜像）

> 适用场景：你当前在 `redmi-lan` 上使用的是“打包了 ERPNext+HRMS 的集成镜像”，且更新/稳定性出现问题，希望改为分别更新两个 app。

---

## 核心思路

不再走 `frappe_docker + apps.json` 的二次构建镜像方式，而是在现有 bench 内：

1. 保持官方基础镜像启动；
2. 确保 `apps/hrms` 仓库真实存在（持久化）；
3. 分别对 `erpnext` 与 `hrms` 执行 `bench update`；
4. 对站点执行 `migrate`。

这样你可以独立控制 ERPNext 和 HRMS 的更新节奏，问题定位也更清晰。

---

## 前提要求（非常关键）

必须保证 Docker Compose 对 bench 的 `apps` 目录做了持久化挂载。否则容器重建后 `apps/hrms` 会丢失。

建议至少确认以下卷已持久化（示意）：

```yaml
volumes:
  - sites:/home/frappe/frappe-bench/sites
  - logs:/home/frappe/frappe-bench/logs
  - apps:/home/frappe/frappe-bench/apps
```

---

## 已提供的自动化脚本

文件路径：

`config_package/setup_scripts/auto_update_erpnext.sh`

该脚本已改为“分离更新模式”，主要流程：

- 可选备份；
- 启动/拉取基础服务；
- 检查并拉取 `hrms` 仓库；
- 分别更新 `erpnext`、`hrms`；
- 自动检查各站点是否安装 hrms（未安装则安装）；
- 逐站点执行 migrate 和 clear-cache。

---

## 服务器执行步骤（推荐）

SSH 登录：

```bash
ssh redmi-lan
```

执行分离更新：

```bash
cd /opt/1panel/docker/compose/erpnext/frappe_docker
chmod +x /Users/shiny/Documents/Qingpi_Tech/Projects/erpnext_china_opc/config_package/setup_scripts/auto_update_erpnext.sh

# 全站点更新（不备份）
COMPOSE_DIR=/opt/1panel/docker/compose/erpnext \
ERPNEXT_BRANCH=version-16 \
HRMS_BRANCH=version-16 \
SITE_SCOPE=all \
ENABLE_BACKUP=0 \
bash /Users/shiny/Documents/Qingpi_Tech/Projects/erpnext_china_opc/config_package/setup_scripts/auto_update_erpnext.sh
```

如需先备份：把 `ENABLE_BACKUP=0` 改为 `ENABLE_BACKUP=1`。

---

## 验证命令

```bash
cd /opt/1panel/docker/compose/erpnext
docker compose exec backend bench version
docker compose exec backend bench --site <你的site> list-apps
```

预期至少包含：

- frappe
- erpnext
- hrms

---

## 回滚建议

若分离更新后异常：

1. 停止写入；
2. 用最近备份恢复站点；
3. 将 `ERPNEXT_BRANCH` / `HRMS_BRANCH` 固定到更稳定分支或具体 tag；
4. 再次执行脚本完成一致性修复。
