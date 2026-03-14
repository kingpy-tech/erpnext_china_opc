# 01 ERPNext 基础安装指南 (微型服务器 1Panel 编排篇)

## 痛点切入
很多小微团队创业者或独立开发者在初期希望用最低成本搭建自己的数字化后台，常常会选择高性价比的微型服务器/家用小主机作为 HomeLab 服务器。但 ERPNext (Frappe 框架) 的依赖极其复杂，传统的手动 `bench install` 经常因为环境问题失败。虽然纯 Docker 部署稳定，但纯命令行操作和后期运维对于非运维人员来说依然有一定门槛。

## 我们的折腾解法
**使用 1Panel 等现代 Linux 面板的“容器编排 (Docker Compose)”功能**进行可视化安装。1Panel 提供了友好的 Web 界面，我们只需提供一份标准的 `config_package/setup_scripts/docker-compose.yml` 配置文件，即可一键启动整个 ERPNext 集群，并且可以在面板中直观地查看日志、管理容器状态。同时，我们将端口保持官方默认的 **8080** 端口映射，尽量减少非必要改动。

---

## 版本选择指南：v16 及底层依赖环境
在开始安装前，我们需要决定使用的版本。本教程的核心应用采用 **v16** 标签：
代表当前最新的正式版本，包含了最新的 UI 体验和底层代码重构。对于希望紧跟官方更新步伐、未来能更快体验新特性与功能迭代的小微团队和独立开发者，选择 v16 是更具前瞻性的决定。
*注：虽然新大版本在初期可能伴随极少部分小众第三方插件的兼容适配期，但 ERPNext 的核心进销存与财务账务模块已经非常完善，完全适合作为主生产力工具。*

**⚠️ 底层依赖镜像升级说明（针对 v16）：**
在许多老版本的网上教程中，数据库通常使用的是 `mariadb:10.6`，缓存使用的是 `redis:6.2-alpine`。但为了完美适配 ERPNext v16 及提升性能，我们在下方提供的 `docker-compose.yml` 中已将它们升级为官方推荐的较新版本：
- **MariaDB**：已升级为 `mariadb:10.11`。这是 MariaDB 的一个极其稳定的长期支持（LTS）版本，相比于老旧的 10.6，它对较新特性的支持更好，同时又比 11.x 系列拥有更好的老插件向下兼容性。
- **Redis**：已升级为 `redis:7-alpine`。Redis 7 增强了缓存管理和性能，更适配 v16 中更新过的 Python/Node.js 队列机制。

---

## 准备工作
1. 一台已安装 **1Panel 面板**的小主机（Ubuntu/Debian 系统）或云服务器（如腾讯云、阿里云）。
2. 在 1Panel 的“安全 -> 防火墙”中，确认已放行 **8080** 端口。
3. 获取服务器的 IP 或绑定的域名（如果你是云服务器，需要去云服务商控制台配置“安全组”，放行 8080 端口）。

### 如何找到并选择服务器的 IP？(单租户 vs 多租户架构)
在安装前，我们需要决定以什么地址来访问 ERPNext（这个地址将作为站点的 `Site Name`）。**Frappe 框架原生支持多租户架构，这意味着你可以运行一套容器代码，但根据你访问的地址不同，进入完全物理隔离的不同数据库。**

#### 强烈推荐的“内外网双账套多租户”方案：
如果你既希望**保护企业内部真实的业务数据**，又想**对外提供一个给客户随便折腾的试用系统**，你可以准备两个地址：
1. **内部生产账套（使用云服务器内网 IP，如 `10.0.0.2` 或内部专有域名 `internal.qingpy.cn`）**：高度安全，外部公网绝对无法访问。内部员工通过企业内部 VPN 或云专线连入内网后方可登录。在终端中输入 `ip addr` 即可查看你的内网 IP。
2. **外部试用账套（使用公网域名，如 `erp.qingpy.cn`）**：任何人通过公网均可访问，里面的数据可以随时清空重置，绝不会污染内部账套。
   *(注：如果要使用外部公网域名，请务必前往云解析服务商（如 DNSPod/阿里云解析），添加一条 A 记录，将 `erp` 指向你服务器的公网 IP。在解析生效前，可继续往后进行安装，但最终浏览器访问需等待解析生效。)*

## 安装步骤

### 1. 创建 1Panel 容器编排
1. 登录 1Panel 管理后台。
2. 左侧导航栏进入 **容器** -> **编排 (Compose)**。
3. 点击 **创建编排** 按钮。
4. **名称**：填写 `erpnext`
5. **路径**：保持默认即可。
6. **模式**：选择 **编辑**，将以下代码粘贴到文本框中。

> **注意**：下方配置去除了 `FRAPPE_SITE_NAME_HEADER` 参数，以释放 Frappe 原生的多租户路由能力。它将根据你在浏览器中输入的地址，自动分配对应 Site。

```yaml
services:
  backend:
    image: frappe/erpnext:v16
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs
      - apps:/home/frappe/frappe-bench/apps

  configurator:
    image: frappe/erpnext:v16
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
      - apps:/home/frappe/frappe-bench/apps

  db:
    image: mariadb:10.11
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
    image: frappe/erpnext:v16
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - nginx-entrypoint.sh
    environment:
      BACKEND: backend:8000
      SOCKETIO: websocket:9000
      UPSTREAM_REAL_IP_ADDRESS: 127.0.0.1
      UPSTREAM_REAL_IP_HEADER: X-Forwarded-For
      UPSTREAM_REAL_IP_RECURSIVE: "off"
      PROXY_READ_TIMEOUT: 120
      CLIENT_MAX_BODY_SIZE: 50m
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs
      - apps:/home/frappe/frappe-bench/apps
    ports:
      - "8080:8080"

  queue-default:
    image: frappe/erpnext:v16
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
      - apps:/home/frappe/frappe-bench/apps

  queue-long:
    image: frappe/erpnext:v16
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
      - apps:/home/frappe/frappe-bench/apps

  queue-short:
    image: frappe/erpnext:v16
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
      - apps:/home/frappe/frappe-bench/apps

  redis-queue:
    image: redis:7-alpine
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - redis-queue-data:/data

  redis-cache:
    image: redis:7-alpine
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - redis-cache-data:/data

  redis-socketio:
    image: redis:7-alpine
    deploy:
      restart_policy:
        condition: on-failure
    volumes:
      - redis-socketio-data:/data

  scheduler:
    image: frappe/erpnext:v16
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - bench
      - schedule
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs
      - apps:/home/frappe/frappe-bench/apps

  websocket:
    image: frappe/erpnext:v16
    deploy:
      restart_policy:
        condition: on-failure
    command:
      - node
      - /home/frappe/frappe-bench/apps/frappe/socketio.js
    volumes:
      - sites:/home/frappe/frappe-bench/sites
      - logs:/home/frappe/frappe-bench/logs
      - apps:/home/frappe/frappe-bench/apps

volumes:
  db-data:
  redis-queue-data:
  redis-cache-data:
  redis-socketio-data:
  sites:
  logs:
  assets:
  apps:
```

### 2. 启动并初始化站点 (双账套分离)
1. 在 1Panel 粘贴上述配置后，点击 **确认/部署**。等待几分钟让系统拉取镜像并启动所有容器。
2. 当所有容器状态显示为**运行中**后，需要初始化站点。通过以下命令进入 backend 容器，我们将利用 Frappe 多租户特性**创建两个独立的账套**：
   ```bash
   # 1. 进入容器 (假设容器名为 erpnext-backend-1)
   docker exec -it erpnext-backend-1 bash
   
   # --- 阶段一：创建【内部高安全生产账套】 ---
   # 这里使用你的云服务器内网 IP（示例为 10.0.0.2），数据库密码设为 admin
   bench new-site 10.0.0.2 --admin-password admin --db-root-password admin
   bench --site 10.0.0.2 install-app erpnext
   
   # 安装中国区刚需的 HRMS 模块到内部生产账套
   # ⚠️ 如果服务器在国内，极易出现 SSL timeout 报错。如果拉取失败，请参考下方“避坑指南”使用 GitHub 加速通道
   bench get-app hrms
   bench --site 10.0.0.2 install-app hrms
   # 将内部账套设为系统兜底默认值
   bench use 10.0.0.2

   # --- 阶段二：创建【外部公开试用账套】 ---
   # 这里使用你解析好的公网子域名
   bench new-site erp.qingpy.cn --admin-password admin --db-root-password admin
   bench --site erp.qingpy.cn install-app erpnext
   # 试用系统通常不需要处理真实的工资薪酬，这里可以选择不装 HRMS（装了也没坏处，若需安装命令同上）

   # 3. 退出容器
   exit
   ```

### 3. 分别登录系统与初始化向导
此时，你的双线隔离多租户系统已经完美搭建。
- **内部员工通道**：确保电脑已通过企业内部 VPN 或专线接入内网环境，浏览器访问 `http://10.0.0.2:8080`，这里的数据高度机密。
- **外部客户通道**：确保域名 DNS 解析已生效，浏览器访问 `http://erp.qingpy.cn:8080`，这里的数据可随时演示、清空。

用户名：`Administrator`
密码：`admin` (上面命令中设置的密码)

**首次登录向导 (Setup Wizard) 配置经验：**
- **语言设置缺陷提示（重要）**：当进入向导的第一步设置界面语言时，输入框内可能默认填有 `English`，导致你无法直接下拉找到或输入中文。**你必须先按退格键把输入框里的 `English` 删得干干净净**，然后再输入“中文”或者“zh”进行搜索并选择。这是 ERPNext 在 UI 交互上的一个小缺陷，或者可以先以 `English` 的设置进入系统再修改全局设置。
- **公司简称 (Company Abbreviation)**：强烈建议使用 2-3 个全大写英文字母（如 `QP`），因为这个简称会直接影响并显示在后续所有业务单据的默认命名前缀中。
- **会计科目表 (Chart of Accounts)**：建议选择 **Standard with Numbers**（带编号的标准科目表），这能保持良好的科目层级结构，也方便后续我们通过内置工具覆盖导入行业专属科目表。
- **样板数据**：如果是为了熟悉系统而进行的测试安装，可以在向导中勾选生成样板数据（Sample Data），这样系统会预置一些基础单据供测试流转。

---

## 避坑指南
- **云主机执行 Docker 报错权限不足（提示 `permission denied` ... `/var/run/docker.sock`）**：
  如果你使用的是腾讯云、阿里云等大厂的云服务器，通过默认的 `ubuntu` 或 `centos` 非 root 用户通过 SSH 登录，你在终端敲 `docker exec` 时极有可能被拒绝访问。
  **终极解决方法**：
  将当前非 root 用户加入到 docker 管理组，在终端依次执行两行命令：
  ```bash
  sudo usermod -aG docker $USER
  newgrp docker
  ```
  执行完毕后，你就可以畅通无阻地使用所有的 `docker` 命令了。
- **HRMS/App 前端打包失败 (提示 `socketio_port is not exported by common_site_config.json`)**：
  由于部分 Docker 环境的读写时序问题，在安装含前端框架（如 HRMS 的 Vite）的插件时，极易卡在 `bench build` 阶段并抛出此类报错。
  **终极解决方法**：
  进入 backend 容器内，手动为站点全局配置文件补齐端口变量，然后重新编译前端即可：
  ```bash
  # 1. 补齐全局变量
  bench set-config -g socketio_port 9000
  # 2. 重新编译前端（此时应该能看到绿色的打包成功提示）
  bench build --app hrms
  # 3. 编译成功后，继续执行安装到对应站点的命令
  ```
- **安装 App 时 GitHub 拉取超时 (提示 `SSL connection timeout` 或 `git clone failed`)**：
  当你在容器内执行 `bench get-app hrms` 时，其实质是通过 `git clone` 去国外的 GitHub 拉取源代码。因为国内云服务器的连通性极差，很容易报错。
  **解决方法：** 使用国内合规的公益镜像加速通道（如 gitclone.com 或 Github 镜像加速站）。请不要只输 `hrms`，而是手动拼接带加速前缀的完整 URL。在容器内执行：
  ```bash
  # 尝试方案 A
  bench get-app https://gitclone.com/github.com/frappe/hrms.git
  
  # 若 A 失效，可尝试方案 B（使用一些主流加速反代）
  # bench get-app https://ghproxy.net/https://github.com/frappe/hrms.git
  ```
- **Docker 镜像拉取失败 (提示 `i/o timeout` 或 `403 Forbidden`)**：
  由于国内网络环境限制，直接拉取 Docker Hub 镜像常会遇到网络超时。但近期多数国内公开镜像源（如 `docker.1panel.live`）均已失效并返回 `403 Forbidden`。
  **终极解决方法**：
  1. **配置云厂商专属加速源**：最推荐的方法是登录你的云服务器控制台（如阿里云/腾讯云的容器镜像服务 ACR），获取系统免费为你分配的**专属加速器地址**。进入 1Panel 面板 -> **容器** -> **配置** -> **镜像加速**，清空所有无效地址，填入你的专属加速地址，保存并重启 Docker。
  2. **尝试第三方合规镜像源**：目前国内仍有少部分企业或机构（如 `docker.m.daocloud.io` 等）在提供公益加速，可以在 1Panel 中尝试添加配置。
  3. **离线导入（企业级绝对可靠方案）**：在有畅通外网环境的机器上，使用 `docker pull frappe/erpnext:v16` 下载镜像，然后通过 `docker save` 打包成 tar 文件，上传至这台服务器后执行 `docker load -i` 进行离线导入部署。
- **关于 8080 端口**：Frappe Docker 的官方 `frontend` 容器内部默认使用 Nginx 监听 8080 端口。我们在 `docker-compose.yml` 中直接使用 `ports: - "8080:8080"` 进行原样映射，这也是官方推荐的默认设置，减少不必要的配置麻烦。后续你可以通过 1Panel 的“网站”功能，将其反向代理到 443 并套上 HTTPS 证书。
- **防火墙拦截**：确保 1Panel 安全设置以及云服务商的安全组都已开放了 8080 端口的出站入站规则。
- **Site 名字严格匹配机制（"Sorry! We will be back soon" 的罪魁祸首）**：由于我们采用了无缝多租户架构（去掉了 `FRAPPE_SITE_NAME_HEADER`），因此 Frappe **严格根据你在浏览器地址栏敲的地址去寻找匹配的 Site**。如果你通过公网 IP `http://49.235.x.x:8080` 去访问，而你刚才 `bench new-site` 建的是域名或者内部 IP，Frappe 找不到 `49.235.x.x` 这个文件夹，就会报错。请务必用什么名字建的站，就敲什么名字去访问！
- **多租户修改隔离原则（必看架构常识）**：在此双账套架构下：
  - **在网页端的定制互不影响**：当你在内部账套（或试用账套）的网页后台添加“自定义字段（Custom Field）”、写客户端/服务端脚本、改表单样式时，这些修改实际上是写入了该账套专属的 **MariaDB 数据库**中。由于每个账套数据库物理隔离，你在网页上的操作**绝对不会污染**或影响其他账套。
  - **在服务器端的代码修改全局生效**：所有的租户共享着唯一的底层业务代码库（挂载的 `apps` 目录）。如果你通过 SSH 进入服务器，修改了底层的 `.py`、`.js` 源代码或者安装了一个新的 App，那么**所有账套都会同步获得这个更新**。
- **容器初始化时间**：如果在点击创建编排后发现访问报错，请不要着急，`db` 容器的初始化和首次拉取镜像可能需要几分钟。你可以在 1Panel 的容器日志中观察进度。
