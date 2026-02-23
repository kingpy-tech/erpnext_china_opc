# 01 ERPNext 基础安装指南 (微型服务器 1Panel 编排篇)

## 痛点切入
很多“一人公司”创业者或独立开发者在初期希望用最低成本搭建自己的数字化后台，常常会选择高性价比的微型服务器/家用小主机作为 HomeLab 服务器。但 ERPNext (Frappe 框架) 的依赖极其复杂，传统的手动 `bench install` 经常因为环境问题失败。虽然纯 Docker 部署稳定，但纯命令行操作和后期运维对于非运维人员来说依然有一定门槛。

## 解决方案
**使用 1Panel 等现代 Linux 面板的“容器编排 (Docker Compose)”功能**进行可视化安装。1Panel 提供了友好的 Web 界面，我们只需提供一份标准的 `docker-compose.yml` 配置文件，即可一键启动整个 ERPNext 集群，并且可以在面板中直观地查看日志、管理容器状态。同时，我们将端口保持官方默认的 **8080** 端口映射，尽量减少非必要改动。

---

## 版本选择指南：latest
在开始安装前，我们需要决定使用的版本。本教程采用 **latest** 标签：
代表当前最新的正式版本，包含了最新的 UI 体验和底层代码重构。对于希望紧跟官方更新步伐、未来能更快体验新特性与功能迭代的“一人公司”和独立开发者，选择 latest 最新版是更具前瞻性的决定。
*注：虽然新大版本在初期可能伴随极少部分小众第三方插件的兼容适配期，但 ERPNext 的核心进销存与财务账务模块已经非常完善，完全适合作为主生产力工具。*

---

## 准备工作
1. 一台已安装 **1Panel 面板**的小主机（Ubuntu/Debian 系统）。
2. 在 1Panel 的“安全 -> 防火墙”中，确认已放行 **8080** 端口。
3. 获取服务器的局域网 IP（例如：`192.168.1.12`）。

## 安装步骤

### 1. 创建 1Panel 容器编排
1. 登录 1Panel 管理后台。
2. 左侧导航栏进入 **容器** -> **编排 (Compose)**。
3. 点击 **创建编排** 按钮。
4. **名称**：填写 `erpnext`
5. **路径**：保持默认即可。
6. **模式**：选择 **编辑**，将以下代码粘贴到文本框中。

> **注意**：请将下方代码中所有的 `192.168.1.12` 替换为您服务器的**实际局域网 IP 地址**。

```yaml
version: "3"

services:
  backend:
    image: frappe/erpnext:latest
    deploy:
      restart_policy:
        condition: on-failure
    environment:
      # 【关键配置】如遇国内网络拉取 GitHub 代码失败 (Connection timed out)，请开启以下代理
      # 前提：宿主机已运行代理软件(如 ShellCrash/Clash)，并开启了"允许局域网连接"
      # 请将 192.168.1.12 替换为你宿主机的真实 IP，7890 替换为代理端口
      # - HTTP_PROXY=http://192.168.1.12:7890
      # - HTTPS_PROXY=http://192.168.1.12:7890
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  configurator:
    image: frappe/erpnext:latest
    deploy:
      restart_policy:
        condition: none
    entrypoint:
      - bash
      - -c
    command:
      - >
        ls -1 apps > sites/apps.txt;
        bench set-config -g db_host db;
        bench set-config -g redis_cache "redis://redis-cache:6379";
        bench set-config -g redis_queue "redis://redis-queue:6379";
        bench set-config -g redis_socketio "redis://redis-socketio:6379";
        bench set-config -p socketio_port 9000;
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  db:
    image: mariadb:10.6
    healthcheck:
      test: mysqladmin ping -h localhost --password=admin
      interval: 1s
      retries: 15
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --skip-character-set-client-handshake
      - --skip-innodb-read-only-compressed
    environment:
      MYSQL_ROOT_PASSWORD: admin
    volumes:
      - db-data:/var/lib/mysql

  frontend:
    image: frappe/erpnext:latest
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - nginx-entrypoint.sh
    environment:
      BACKEND: backend:8000
      FRAPPE_SITE_NAME_HEADER: 192.168.1.12
      SOCKETIO: websocket:9000
      UPSTREAM_REAL_IP_ADDRESS: 127.0.0.1
      UPSTREAM_REAL_IP_HEADER: X-Forwarded-For
      UPSTREAM_REAL_IP_RECURSIVE: "off"
      PROXY_READ_TIMEOUT: 120
      CLIENT_MAX_BODY_SIZE: 50m
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs
    ports:
      - "8080:8080"

  queue-default:
    image: frappe/erpnext:latest
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - bench
      - worker
      - --queue
      - default
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  queue-long:
    image: frappe/erpnext:latest
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - bench
      - worker
      - --queue
      - long
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  queue-short:
    image: frappe/erpnext:latest
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - bench
      - worker
      - --queue
      - short
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  redis-queue:
    image: redis:6.2-alpine
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - redis-queue-data:/data

  redis-cache:
    image: redis:6.2-alpine
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - redis-cache-data:/data

  redis-socketio:
    image: redis:6.2-alpine
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - redis-socketio-data:/data

  scheduler:
    image: frappe/erpnext:latest
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - bench
      - schedule
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

  websocket:
    image: frappe/erpnext:latest
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - node
      - /home/frappe/frappe-bench/apps/frappe/socketio.js
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs

volumes:
  db-data:
  redis-queue-data:
  redis-cache-data:
  redis-socketio-data:
  sites:
  logs:
```

### 2. 启动并初始化站点
1. 在 1Panel 粘贴上述配置后，点击 **确认/部署**。等待几分钟让系统拉取镜像并启动所有容器。
2. 当所有容器状态显示为**运行中**后，需要初始化站点。你可以通过 1Panel 的终端执行，或者 SSH 连接到服务器执行。
3. 假设你的 Compose 项目名称叫 `erpnext`，通过以下命令进入 backend 容器并初始化（请将 `192.168.1.12` 替换为你的实际 IP）：
   ```bash
   # 注意：以下命令必须进入 erpnext-backend-1 容器内部执行！
   # 宿主机上没有 bench 命令，如果执行报错 'command not found'，请检查是否已进入容器。

   # 1. 进入容器 (假设容器名为 erpnext-backend-1)
   docker exec -it erpnext-backend-1 bash
   
   # 2. 创建新站点 (进入容器后执行)
   # 站名保持与 IP 一致，设置管理员密码为 admin
   bench new-site 192.168.1.12 --admin-password admin --db-root-password admin
   
   # 3. 安装 ERPNext 应用
   bench --site 192.168.1.12 install-app erpnext

   # 4. 【重要】安装 HRMS (人力资源) 等独立拆分的应用
   # 从 v14 开始，HRMS、Payments 等模块已从 ERPNext 核心中拆分，需单独安装。
   # 对于中国小微企业，发工资和个税申报是刚需，因此强烈建议安装。
   bench get-app hrms
   bench --site 192.168.1.12 install-app hrms
   
   # 5. 将其设为默认站点
   bench use 192.168.1.12

   # 6. 退出容器
   exit
   ```

### 3. 登录系统与初始化向导
完成上述步骤后，打开浏览器访问：
`http://192.168.1.12:8080`

用户名：`Administrator`
密码：`admin` (上面命令中设置的密码)

**首次登录向导 (Setup Wizard) 配置经验：**
- **公司简称 (Company Abbreviation)**：强烈建议使用 2-3 个全大写英文字母（如 `QP`），因为这个简称会直接影响并显示在后续所有业务单据的默认命名前缀中。
- **会计科目表 (Chart of Accounts)**：建议选择 **Standard with Numbers**（带编号的标准科目表），这能保持良好的科目层级结构，也方便后续我们通过内置工具覆盖导入高新企业专属科目表。
- **样板数据**：如果是为了熟悉系统而进行的测试安装，可以在向导中勾选生成样板数据（Sample Data），这样系统会预置一些基础单据供测试流转。

---

## 避坑指南
- **Docker 镜像拉取失败 (提示 `i/o timeout` 或 `403 Forbidden`)**：
  由于国内网络环境限制，直接拉取 Docker Hub 镜像常会遇到网络超时。但近期多数国内公开镜像源（如 `docker.1panel.live`）均已失效并返回 `403 Forbidden`。
  **终极解决方法**：
  如果你的服务器上安装了代理工具（如 **ShellCrash** 或 Clash 等）：
  1. 请进入 1Panel 面板 -> **容器** -> **配置** -> **镜像加速**，**清空所有之前添加的无效加速地址**（如 docker.1panel.live），保存并重启 Docker。
  2. 确保你的 ShellCrash 开启了**透明代理/局域网接管**，并且运行正常。
  3. 此时 Docker 守护进程会直接通过 ShellCrash 代理去拉取官方 `docker.io` 镜像，速度飞快且不再受限。
- **关于 8080 端口**：Frappe Docker 的官方 `frontend` 容器内部默认使用 Nginx 监听 8080 端口。我们在 `docker-compose.yml` 中直接使用 `ports: - "8080:8080"` 进行原样映射，这也是官方推荐的默认设置，减少不必要的配置麻烦。
- **防火墙拦截**：确保 1Panel 安全设置以及服务器本身（如 Ubuntu 的 `ufw` 或云服务商的安全组）都已开放了 8080 端口的出入站规则。
- **Site 名字匹配**：Frappe 框架基于 HTTP Host 头来定位站点。我们在 `frontend` 的环境变量中写死了 `FRAPPE_SITE_NAME_HEADER: 192.168.1.12`，这会强制所有访问路由到你的 IP 站点。如果不按此设置，系统会返回 `Sorry! We will be back soon`。
- **容器初始化时间**：如果在点击创建编排后发现访问报错，请不要着急，`db` 容器的初始化和首次拉取镜像可能需要几分钟。你可以在 1Panel 的容器日志中观察进度。
