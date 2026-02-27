#!/bin/bash
# ------------------------------------------------------------------------
# ERPNext + HRMS 自动更新脚本 (红米服务器版)
# 请务必在配置定时任务前，先手动运行一次以确保你的网络和代理能正常跑完。
# ------------------------------------------------------------------------
set -e

# 配置目录路径
COMPOSE_DIR="/opt/1panel/docker/compose/erpnext"
FRAPPE_DOCKER_DIR="$COMPOSE_DIR/frappe_docker"

echo "==========================================="
echo " 开始执行 ERPNext & HRMS 自动更新"
echo " 时间: $(date)"
echo "==========================================="

# 第一步：可选（非常重要）- 备份数据库
# docker compose -f $COMPOSE_DIR/docker-compose.yml exec backend bench --site <你的site名称> backup --with-files

# 第二步：进入 frappe_docker 目录，利用已经存放的配置文件重新构建新镜像
# 由于你的 apps_v16.json 中配置的是 v16.7.2 和 version-16 分支，
# docker build 时如果分支有最新 commit，会自动拉取最新代码打包。
# (如果想完全跟随最新 v16 稳定版，可将 apps_v16.json 里的 v16.7.2 改为 version-16 即可自动追最新的小版本)
echo "1. 正在获取最新代码并打包镜像 (erpnext-hrms:latest)..."
cd $FRAPPE_DOCKER_DIR
chmod +x build_custom_image_v16.sh
./build_custom_image_v16.sh

echo "2. 正在重启 Docker 服务..."
cd $COMPOSE_DIR
docker compose down
docker compose up -d

echo "3. 等待服务启动 (15秒)..."
sleep 15

# 第三步：数据迁移 (针对所有 site 自动执行 migrate)
# 如果有多个 site 且你只关注某一个，可以改为: exec backend bench --site site1.local migrate
echo "4. 正在执行数据库迁移 (migrate)..."
# docker exec 的方式获取所有站点名并依次迁移
SITE_NAMES=$(docker compose exec backend ls -1 sites | grep -v 'apps.txt\|assets\|common_site_config.json' || true)

for SITE in $SITE_NAMES; do
    echo " -> 迁移站点: $SITE"
    docker compose exec backend bench --site $SITE migrate
    docker compose exec backend bench --site $SITE clear-cache
done

echo "==========================================="
echo " 自动更新完成！"
echo " 时间: $(date)"
echo "==========================================="
