#!/bin/bash
# ------------------------------------------------------------------------
# ERPNext + HRMS 分离更新脚本 (红米服务器版)
# 目标：不再使用“集成打包镜像”方案，改为在同一 bench 中分别更新 erpnext 与 hrms。
# 要求：docker-compose 需要挂载 apps 卷，否则 hrms 仓库会在容器重建后丢失。
# ------------------------------------------------------------------------
set -euo pipefail

# ========== 可按需覆盖的环境变量 ==========
COMPOSE_DIR="${COMPOSE_DIR:-/opt/1panel/docker/compose/erpnext}"
ERPNEXT_BRANCH="${ERPNEXT_BRANCH:-version-16}"
HRMS_BRANCH="${HRMS_BRANCH:-version-16}"
ENABLE_BACKUP="${ENABLE_BACKUP:-0}"          # 1=先备份后升级
SITE_SCOPE="${SITE_SCOPE:-all}"              # all 或具体 site 名称
AUTO_IMPORT_TRANSLATIONS="${AUTO_IMPORT_TRANSLATIONS:-1}"   # 1=升级后自动导入翻译 CSV
TRANSLATION_DIR="${TRANSLATION_DIR:-$COMPOSE_DIR/translations}"
TRANSLATION_GLOB="${TRANSLATION_GLOB:-*_zh.csv}"

# 健康检查参数
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-180}"
CHECK_INTERVAL_SECONDS="${CHECK_INTERVAL_SECONDS:-3}"

cd "$COMPOSE_DIR"

validate_apps_volume_mounted() {
  local cfg
  cfg=$(docker compose config 2>/dev/null || true)
  if ! echo "$cfg" | grep -q '/home/frappe/frappe-bench/apps'; then
    echo "✗ 检测到 docker compose 未挂载 /home/frappe/frappe-bench/apps 持久化卷。"
    echo "  这会导致容器重建后 hrms 仓库丢失，无法满足‘分离更新’稳定性要求。"
    echo "  请先在 compose 配置中添加 apps 卷挂载，再重试。"
    echo "  示例："
    echo "    - apps:/home/frappe/frappe-bench/apps"
    exit 2
  fi
  echo "   ✓ 已检测到 apps 持久化卷挂载"
}

wait_compose_service_up() {
  local service="$1"
  local timeout="${2:-$MAX_WAIT_SECONDS}"
  local waited=0

  while [ "$waited" -lt "$timeout" ]; do
    if docker compose ps --status running "$service" 2>/dev/null | grep -q "$service"; then
      echo "   ✓ 服务已运行: $service"
      return 0
    fi
    sleep "$CHECK_INTERVAL_SECONDS"
    waited=$((waited + CHECK_INTERVAL_SECONDS))
  done

  echo "   ✗ 服务启动超时: $service (${timeout}s)"
  return 1
}

wait_http_200() {
  local url="$1"
  local timeout="${2:-$MAX_WAIT_SECONDS}"
  local waited=0

  while [ "$waited" -lt "$timeout" ]; do
    code=$(curl -sS -o /dev/null -w "%{http_code}" "$url" || true)
    if [ "$code" = "200" ]; then
      echo "   ✓ HTTP 200: $url"
      return 0
    fi
    sleep "$CHECK_INTERVAL_SECONDS"
    waited=$((waited + CHECK_INTERVAL_SECONDS))
  done

  echo "   ✗ HTTP 未就绪: $url (${timeout}s)"
  return 1
}

verify_homepage_assets() {
  local homepage="${1:-http://127.0.0.1:8080/}"
  local tmp_urls
  tmp_urls=$(mktemp)

  curl -sS "$homepage" \
    | tr '"' '\n' \
    | grep -E '^/assets/.*\.(js|css)$' \
    | sort -u > "$tmp_urls" || true

  if [ ! -s "$tmp_urls" ]; then
    echo "   ! 未从首页提取到 assets 链接，跳过该项校验"
    rm -f "$tmp_urls"
    return 0
  fi

  local failed=0
  while IFS= read -r u; do
    [ -z "$u" ] && continue
    code=$(curl -sS -o /dev/null -w "%{http_code}" "http://127.0.0.1:8080$u" || true)
    if [ "$code" != "200" ]; then
      echo "   ✗ 资源异常 ($code): $u"
      failed=1
    fi
  done < "$tmp_urls"

  rm -f "$tmp_urls"
  return "$failed"
}

import_translation_csv_for_site() {
  local site="$1"
  local csv_file="$2"
  local csv_name
  csv_name=$(basename "$csv_file")

  echo "    - 导入翻译文件: $csv_name"
  docker compose cp "$csv_file" "backend:/tmp/$csv_name" >/dev/null

  docker compose exec -T \
    -e TARGET_SITE="$site" \
    -e CSV_FILE="/tmp/$csv_name" \
    backend bash -lc '
set -euo pipefail
cd /home/frappe/frappe-bench

python - <<"PY"
import csv
import os
from pathlib import Path

csv_path = Path(os.environ["CSV_FILE"])
sql_path = Path("/tmp/translation_upsert.sql")

rows = []
with csv_path.open("r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for r in reader:
        lang = (r.get("Language") or "").strip()
        src = (r.get("Source Text") or "").strip()
        dst = (r.get("Translated Text") or "").strip()
        if lang and src and dst:
            rows.append((lang, src, dst))

def esc(s: str) -> str:
    return s.replace("\\", "\\\\").replace("'", "\\'")

parts = ["START TRANSACTION;"]
for lang, src, dst in rows:
    parts.append(
        "INSERT INTO `tabTranslation` "
        "(`name`,`creation`,`modified`,`modified_by`,`owner`,`docstatus`,`idx`,`language`,`source_text`,`translated_text`) "
        "SELECT REPLACE(UUID(),\"-\",\"\"), NOW(), NOW(), \"Administrator\", \"Administrator\", 0, 0, "
        f"\"{esc(lang)}\", \"{esc(src)}\", \"{esc(dst)}\" "
        "FROM DUAL WHERE NOT EXISTS ("
        f"SELECT 1 FROM `tabTranslation` WHERE `language`=\"{esc(lang)}\" AND `source_text`=\"{esc(src)}\""
        ");"
    )
parts.append("COMMIT;")

sql_path.write_text("\n\n".join(parts) + "\n", encoding="utf-8")
print(f"      > valid_rows={len(rows)}")
PY

bench --site "$TARGET_SITE" mariadb < /tmp/translation_upsert.sql
'
}

echo "==========================================="
echo " 开始执行 ERPNext & HRMS 分离更新"
echo " 时间: $(date)"
echo " COMPOSE_DIR: $COMPOSE_DIR"
echo " ERPNEXT_BRANCH: $ERPNEXT_BRANCH"
echo " HRMS_BRANCH: $HRMS_BRANCH"
echo " SITE_SCOPE: $SITE_SCOPE"
echo " AUTO_IMPORT_TRANSLATIONS: $AUTO_IMPORT_TRANSLATIONS"
echo " TRANSLATION_DIR: $TRANSLATION_DIR"
echo " TRANSLATION_GLOB: $TRANSLATION_GLOB"
echo "==========================================="

echo "0) 预检查：验证 apps 持久化卷挂载..."
validate_apps_volume_mounted

if [ "$ENABLE_BACKUP" = "1" ]; then
  echo "1) 执行站点备份 (--with-files)..."
  if [ "$SITE_SCOPE" = "all" ]; then
    SITE_NAMES=$(docker compose exec -T backend bash -lc "ls -1 sites | grep -Ev 'apps.txt|assets|common_site_config.json'" || true)
    for SITE in $SITE_NAMES; do
      echo " -> 备份站点: $SITE"
      docker compose exec -T backend bench --site "$SITE" backup --with-files
    done
  else
    docker compose exec -T backend bench --site "$SITE_SCOPE" backup --with-files
  fi
else
  echo "1) 已跳过备份 (ENABLE_BACKUP=0)。"
fi

echo "2) 拉取官方基础镜像并确保服务启动..."
docker compose pull backend configurator frontend queue-default queue-long queue-short scheduler websocket

echo "   - 分阶段启动核心依赖服务..."
docker compose up -d db redis-cache redis-queue redis-socketio backend queue-default queue-long queue-short scheduler
wait_compose_service_up db
wait_compose_service_up redis-cache
wait_compose_service_up redis-queue
wait_compose_service_up redis-socketio
wait_compose_service_up backend

echo "   - 再启动 websocket/frontend，降低 DNS/依赖瞬态失败概率..."
docker compose up -d websocket frontend
wait_compose_service_up websocket
wait_compose_service_up frontend
wait_http_200 "http://127.0.0.1:8080/"

echo "3) 确保 hrms 仓库存在于 apps 目录 (若不存在则拉取)..."
docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench && if [ ! -d apps/hrms ]; then bench get-app --branch '$HRMS_BRANCH' hrms; else echo 'apps/hrms 已存在，跳过 get-app'; fi"
echo "   - 兜底确保 hrms 可被 Python 导入..."
docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench && ./env/bin/pip install -e apps/hrms && ./env/bin/python -c 'import hrms; print(hrms.__name__)'"

echo "4) 对 erpnext/hrms 显式切换到目标分支..."
docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench/apps/erpnext && git fetch --all --prune && git checkout '$ERPNEXT_BRANCH'"
docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench/apps/hrms && git fetch --all --prune && git checkout '$HRMS_BRANCH'"

echo "5) 分别更新 erpnext 与 hrms (不走集成镜像重打包)..."
docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench && bench update --pull --patch --build --apps erpnext --reset --no-backup"
docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench && bench update --pull --patch --build --apps hrms --reset --no-backup"

echo "6) 对站点执行 hrms 安装校验 + migrate + clear-cache..."
if [ "$SITE_SCOPE" = "all" ]; then
  SITE_NAMES=$(docker compose exec -T backend bash -lc "ls -1 sites | grep -Ev 'apps.txt|assets|common_site_config.json'" || true)
else
  SITE_NAMES="$SITE_SCOPE"
fi

for SITE in $SITE_NAMES; do
  echo " -> 处理站点: $SITE"

  INSTALLED_APPS=$(docker compose exec -T backend bench --site "$SITE" list-apps || true)
  if ! echo "$INSTALLED_APPS" | grep -q '^hrms$'; then
    echo "    - 站点未安装 hrms，开始安装..."
    docker compose exec -T backend bench --site "$SITE" install-app hrms
  else
    echo "    - hrms 已安装，跳过 install-app"
  fi

  docker compose exec -T backend bench --site "$SITE" migrate
  docker compose exec -T backend bench --site "$SITE" clear-cache
  docker compose exec -T backend bench --site "$SITE" clear-website-cache
done

echo "7) 可选：自动导入翻译 CSV（幂等，不改底层英文业务字段）..."
if [ "$AUTO_IMPORT_TRANSLATIONS" = "1" ]; then
  if [ -d "$TRANSLATION_DIR" ]; then
    mapfile -t CSV_FILES < <(find "$TRANSLATION_DIR" -maxdepth 1 -type f -name "$TRANSLATION_GLOB" | sort)
    if [ "${#CSV_FILES[@]}" -eq 0 ]; then
      echo "   ! 未找到翻译 CSV，跳过导入: $TRANSLATION_DIR/$TRANSLATION_GLOB"
    else
      for SITE in $SITE_NAMES; do
        echo " -> 站点翻译导入: $SITE"
        for CSV_FILE in "${CSV_FILES[@]}"; do
          import_translation_csv_for_site "$SITE" "$CSV_FILE"
        done

        docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench && bench --site '$SITE' clear-cache && bench --site '$SITE' clear-website-cache"
        echo "    - 导入后统计 zh 翻译数量"
        docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench && bench --site '$SITE' mariadb -e \"SELECT COUNT(*) AS zh_count FROM tabTranslation WHERE language='zh';\""
      done
    fi
  else
    echo "   ! 翻译目录不存在，跳过导入: $TRANSLATION_DIR"
  fi
else
  echo "   - 已关闭自动导入翻译 (AUTO_IMPORT_TRANSLATIONS=0)"
fi

echo "8) 资源一致性验收 (首页 200 + assets 200)..."
if ! verify_homepage_assets "http://127.0.0.1:8080/"; then
  echo "   - 检测到资源 404，执行一次最小化重建并重启前端链路..."
  docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench && bench build --apps frappe,erpnext,hrms"
  docker compose restart websocket frontend
  wait_compose_service_up websocket
  wait_compose_service_up frontend
  wait_http_200 "http://127.0.0.1:8080/"

  echo "   - 重建后再次验收资源..."
  verify_homepage_assets "http://127.0.0.1:8080/"
fi

echo "9) 当前版本检查..."
docker compose exec -T backend bench version || true

echo "==========================================="
echo " 分离更新完成！"
echo " 时间: $(date)"
echo "==========================================="
