#!/bin/bash
# ------------------------------------------------------------------------
# ERPNext + HRMS 分离更新脚本 (红米服务器 - QP 终极完美版)
# ------------------------------------------------------------------------
set -euo pipefail

COMPOSE_DIR="${COMPOSE_DIR:-/opt/1panel/docker/compose/erpnext}"
ERPNEXT_BRANCH="${ERPNEXT_BRANCH:-v16.8.2}"
HRMS_BRANCH="${HRMS_BRANCH:-v16}"
ENABLE_BACKUP="${ENABLE_BACKUP:-0}"
SITE_SCOPE="${SITE_SCOPE:-all}"
AUTO_IMPORT_TRANSLATIONS="${AUTO_IMPORT_TRANSLATIONS:-1}"
TRANSLATION_DIR="${TRANSLATION_DIR:-$COMPOSE_DIR/translations}"
TRANSLATION_GLOB="${TRANSLATION_GLOB:-*_zh.csv}"

cd "$COMPOSE_DIR"

import_translation_csv_for_site() {
  local site="$1"
  local csv_file="$2"
  local csv_name
  csv_name=$(basename "$csv_file")

  echo "    - 导入翻译文件: $csv_name"
  docker compose cp "$csv_file" "backend:/tmp/$csv_name" >/dev/null

  # 🚀 终极防弹版：使用 EOF 传递多行脚本，彻底解决 Bash 引号冲突
  docker compose exec -T \
    -e TARGET_SITE="$site" \
    -e CSV_FILE="/tmp/$csv_name" \
    backend bash << 'EOF'
set -euo pipefail
cd /home/frappe/frappe-bench

python - << "PY"
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
    # 彻底解决单双引号的 SQL 注入和转义问题
    return s.replace("\\", "\\\\").replace("'", "\\'").replace('"', '\\"')

parts = ["START TRANSACTION;"]
for lang, src, dst in rows:
    parts.append(
        "INSERT INTO `tabTranslation` "
        "(`name`,`creation`,`modified`,`modified_by`,`owner`,`docstatus`,`idx`,`language`,`source_text`,`translated_text`) "
        "SELECT REPLACE(UUID(),'-',''), NOW(), NOW(), 'Administrator', 'Administrator', 0, 0, "
        f"'{esc(lang)}', '{esc(src)}', '{esc(dst)}' "
        "FROM DUAL WHERE NOT EXISTS ("
        f"SELECT 1 FROM `tabTranslation` WHERE `language`='{esc(lang)}' AND `source_text`='{esc(src)}'"
        ");"
    )
parts.append("COMMIT;")

sql_path.write_text("\n\n".join(parts) + "\n", encoding="utf-8")
print(f"      > valid_rows={len(rows)}")
PY

bench --site "$TARGET_SITE" mariadb < /tmp/translation_upsert.sql
EOF
}

echo "==========================================="
echo " 开始执行 ERPNext & HRMS 分离更新"
echo " 时间: $(date)"
echo " COMPOSE_DIR: $COMPOSE_DIR"
echo "==========================================="

if [ "$ENABLE_BACKUP" = "1" ]; then
  echo "1) 执行站点备份..."
  if [ "$SITE_SCOPE" = "all" ]; then
    SITE_NAMES=$(docker compose exec -T backend bash -lc "ls -1 sites | grep -Ev 'apps.txt|apps.json|assets|common_site_config.json'" || true)
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

echo "2) 确保服务启动..."
docker compose up -d db redis-cache redis-queue redis-socketio backend queue-default queue-long queue-short scheduler
sleep 15
docker compose up -d websocket frontend
sleep 5

echo "3) 确保 hrms 源码与 Python 依赖..."
# 加上 --skip-assets 避免在这里触发错误的编译
docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench && if [ ! -d apps/hrms ]; then bench get-app --skip-assets --branch '$HRMS_BRANCH' hrms; else echo 'apps/hrms 已存在'; fi"
docker compose exec -T backend bash -lc "cd /home/frappe/frappe-bench && ./env/bin/pip install -e apps/hrms"

echo "   - 🚀 登记造册：更新 apps.txt (解决 404/Not in apps.txt 报错)..."
docker compose exec -T backend bash -c "ls -1 apps > sites/apps.txt"

echo "4) (已跳过分支切换，官方镜像自带版本)..."

echo "5) (已跳过 bench update，由下一步 migrate 接管)..."

echo "6) 对站点执行 hrms 安装校验与 migrate..."
if [ "$SITE_SCOPE" = "all" ]; then
  # 🚀 这里的 grep 已经加入了 apps.json 过滤
  SITE_NAMES=$(docker compose exec -T backend bash -lc "ls -1 sites | grep -Ev 'apps.txt|apps.json|assets|common_site_config.json'" || true)
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
    echo "    - hrms 已安装，执行 migrate..."
  fi
  docker compose exec -T backend bench --site "$SITE" migrate
done

echo "7) 可选：自动导入翻译 CSV..."
if [ "$AUTO_IMPORT_TRANSLATIONS" = "1" ]; then
  if [ -d "$TRANSLATION_DIR" ]; then
    mapfile -t CSV_FILES < <(find "$TRANSLATION_DIR" -maxdepth 1 -type f -name "$TRANSLATION_GLOB" | sort)
    for SITE in $SITE_NAMES; do
      for CSV_FILE in "${CSV_FILES[@]}"; do
        import_translation_csv_for_site "$SITE" "$CSV_FILE"
      done
    done
  fi
fi

echo "8) 最终资产编译与缓存清理 (解决 Logo 卡死)..."
echo "   - 补全 socketio 配置..."
docker compose exec -T backend bench set-config -g socketio_port 9000
echo "   - 强制编译前端资产 (可能耗时 1-2 分钟)..."
docker compose exec -T backend bash -c "export PATH=\$PATH:/usr/local/bin:/usr/bin && cd /home/frappe/frappe-bench && bench build --force"
docker compose exec -T backend bench clear-cache

echo "9) 🚀 终极重启：刷新内存数据..."
docker compose restart backend frontend websocket queue-default queue-short queue-long scheduler

echo "==========================================="
echo " 🎉 QP ERPNext & HRMS 升级彻底完成！"
echo "==========================================="