# ERPNext Docker 容器化部署实战

容器化部署已成为现代应用交付的主流方式。本文介绍如何使用 Docker 和 Docker Compose 在国内环境中快速、稳定地部署 ERPNext。

---

## 一、Docker 部署优势

相比传统的 bench 裸机安装，容器化部署有三大核心优势：

- **环境一致性**：镜像封装了所有依赖（Python 版本、系统库、Node.js），开发、测试、生产环境完全一致，彻底消除"在我机器上能跑"的问题。
- **快速迁移**：整个站点打包为 Volume，迁移服务器只需 `docker compose down` → 拷贝数据目录 → `docker compose up`，30 分钟内完成。
- **资源隔离**：多个 ERPNext 实例运行在独立容器中，互不干扰，配合 Traefik 可实现多租户域名路由。

---

## 二、官方 Docker Compose 方案

Frappe 官方维护 [frappe_docker](https://github.com/frappe/frappe_docker) 仓库，提供生产就绪的 Compose 配置。

**核心服务组成：**

| 服务 | 说明 |
|------|------|
| `backend` | Gunicorn 应用服务器 |
| `frontend` | Nginx 静态资源 + 反向代理 |
| `queue-short/long` | RQ 任务队列 |
| `scheduler` | 定时任务 |
| `websocket` | Socket.IO 实时通信 |
| `db` | MariaDB 数据库 |
| `redis-cache/queue/socketio` | Redis 多实例 |

**最小化生产配置示例：**

```yaml
# docker-compose.yml
version: "3.8"

services:
  backend:
    image: frappe/erpnext:v15
    restart: unless-stopped
    environment:
      - DB_HOST=db
      - DB_PORT=3306
      - REDIS_CACHE=redis-cache:6379
      - REDIS_QUEUE=redis-queue:6379
      - SOCKETIO_PORT=9000
    volumes:
      - sites:/home/frappe/frappe-bench/sites
    depends_on:
      - db
      - redis-cache
      - redis-queue

  frontend:
    image: frappe/erpnext:v15
    restart: unless-stopped
    command: nginx-entrypoint.sh
    environment:
      - BACKEND=backend:8000
      - SOCKETIO=websocket:9000
      - FRAPPE_SITE_NAME_HEADER=$$host
    ports:
      - "8080:8080"
    volumes:
      - sites:/home/frappe/frappe-bench/sites

  websocket:
    image: frappe/erpnext:v15
    restart: unless-stopped
    command: node /home/frappe/frappe-bench/apps/frappe/socketio.js
    volumes:
      - sites:/home/frappe/frappe-bench/sites

  queue-short:
    image: frappe/erpnext:v15
    restart: unless-stopped
    command: bench worker --queue short,default
    volumes:
      - sites:/home/frappe/frappe-bench/sites

  scheduler:
    image: frappe/erpnext:v15
    restart: unless-stopped
    command: bench schedule
    volumes:
      - sites:/home/frappe/frappe-bench/sites

  db:
    image: mariadb:10.6
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=your_root_password
      - MYSQL_DATABASE=erpnext
    volumes:
      - db-data:/var/lib/mysql
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci

  redis-cache:
    image: redis:7-alpine
    restart: unless-stopped

  redis-queue:
    image: redis:7-alpine
    restart: unless-stopped

volumes:
  sites:
  db-data:
```

---

## 三、自定义镜像

官方镜像可直接使用，但国内场景通常需要定制：

**添加中文字体（解决 PDF 乱码）：**

```dockerfile
FROM frappe/erpnext:v15

USER root
RUN apt-get update && apt-get install -y fonts-wqy-zenhei fonts-wqy-microhei \
    && fc-cache -fv \
    && rm -rf /var/lib/apt/lists/*
USER frappe
```

**预装自定义 App：**

```dockerfile
FROM frappe/erpnext:v15

# 安装自定义 App（如 erpnext_china）
RUN bench get-app --branch main https://github.com/your-org/erpnext_china \
    && bench build --app erpnext_china
```

**常用环境变量：**

```bash
FRAPPE_SITE_NAME_HEADER=erp.example.com   # 站点域名
SKIP_ASSET_BUILDING=1                      # 跳过前端构建（加速启动）
```

---

## 四、数据持久化

**Volume 挂载策略：**

- `sites/` — 站点配置、上传文件、私有文件，**必须持久化**
- `db-data/` — MariaDB 数据文件，**必须持久化**
- 日志目录建议挂载到宿主机便于排查

**备份策略：**

```bash
# 每日自动备份（加入 crontab）
0 2 * * * docker exec <backend_container> bench --site erp.example.com backup --with-files

# 将备份文件同步到对象存储
0 3 * * * rclone sync /path/to/sites/erp.example.com/private/backups oss:your-bucket/erpnext-backups/
```

---

## 五、反向代理配置

**Traefik（推荐，自动 HTTPS）：**

在 `docker-compose.yml` 的 `frontend` 服务中添加 labels：

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.erpnext.rule=Host(`erp.example.com`)"
  - "traefik.http.routers.erpnext.entrypoints=websecure"
  - "traefik.http.routers.erpnext.tls.certresolver=letsencrypt"
  - "traefik.http.services.erpnext.loadbalancer.server.port=8080"
```

**Nginx 配置要点：**

```nginx
server {
    listen 443 ssl;
    server_name erp.example.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 120;
        client_max_body_size 50m;
    }
}
```

---

## 六、Kubernetes 简介

**适用场景：** 当单台服务器无法满足高并发需求，或需要自动扩缩容、滚动更新时，可迁移至 K8s。

Frappe 社区提供 [Helm Chart](https://helm.frappe.cloud)，支持：

- 多副本 Worker 水平扩展
- PVC 持久化存储
- Ingress 自动路由
- HPA 自动伸缩

```bash
helm repo add frappe https://helm.frappe.cloud
helm install erpnext frappe/erpnext \
  --set persistence.storageClass=standard \
  --set mariadb.auth.rootPassword=your_password
```

K8s 部署复杂度较高，建议先在 Docker Compose 环境稳定运行后再迁移。

---

## 七、国内镜像加速

Docker Hub 在国内访问不稳定，建议配置镜像加速：

**阿里云镜像加速（推荐）：**

登录 [阿里云容器镜像服务](https://cr.console.aliyun.com) → 镜像工具 → 镜像加速器，获取专属地址后：

```json
// /etc/docker/daemon.json
{
  "registry-mirrors": [
    "https://<your-id>.mirror.aliyuncs.com"
  ]
}
```

**腾讯云镜像加速：**

```json
{
  "registry-mirrors": [
    "https://mirror.ccs.tencentyun.com"
  ]
}
```

修改后执行 `sudo systemctl daemon-reload && sudo systemctl restart docker` 生效。

**将自定义镜像推送至国内仓库：**

```bash
# 推送到阿里云 ACR
docker tag frappe/erpnext:v15 registry.cn-shanghai.aliyuncs.com/your-ns/erpnext:v15
docker push registry.cn-shanghai.aliyuncs.com/your-ns/erpnext:v15
```

---

## 小结

Docker Compose 方案是国内中小企业部署 ERPNext 的最佳起点：配置简单、迁移方便、社区活跃。配合阿里云镜像加速和自定义中文字体镜像，可以在 1 小时内完成生产环境搭建。规模扩大后再考虑迁移至 Kubernetes。
