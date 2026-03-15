# 00 快速启动指南 (5 分钟跑起来)

> **目标读者**：第一次接触这个项目、想最快速度把 ERPNext 跑起来的你。
> 不需要读完所有文档，跟着这篇走，5 分钟内你就能看到登录页面。

---

## 前置条件（先确认这三件事）

| 条件 | 说明 |
|------|------|
| 操作系统 | Linux（Ubuntu 22.04 / Debian 12 推荐）或已安装 Docker Desktop 的 Mac/Windows |
| Docker | `docker -v` 能输出版本号即可 |
| Docker Compose | `docker compose version` 能输出版本号（注意是 `compose` 不是 `docker-compose`）|
| 端口 | **8080** 未被占用（`lsof -i :8080` 无输出即可）|
| 内存 | 至少 **4GB RAM**，推荐 8GB |

---

## 第一步：拿到配置文件

```bash
# 克隆仓库（或者直接下载 docker-compose.yml 也行）
git clone https://github.com/kingpy-tech/erpnext_china_opc.git
cd erpnext_china_opc
```

根目录下已经有一份现成的 `docker-compose.yml`，直接用就行，不需要改任何东西。

---

## 第二步：一键启动

```bash
docker compose up -d
```

这条命令会拉取所有镜像并在后台启动。**第一次拉镜像需要几分钟**，取决于你的网速。

> 💡 **国内网络慢？** 可以先配置 Docker 镜像加速（阿里云/腾讯云都有免费的镜像加速地址），或者挂代理拉取。

查看启动进度：

```bash
docker compose logs -f configurator
```

看到 `configurator` 容器退出（`exited with code 0`）就说明初始化完成了。

---

## 第三步：创建你的第一个站点

```bash
# 进入 backend 容器
docker compose exec backend bash

# 在容器内执行建站命令（把 mysite.localhost 换成你想要的域名或 IP）
bench new-site mysite.localhost \
  --mariadb-root-password admin \
  --admin-password admin \
  --install-app erpnext
```

> **说明**：
> - `mysite.localhost` 是站点名，本地测试直接用这个就行，浏览器访问时用它作为 Host。
> - `--mariadb-root-password admin` 对应 `docker-compose.yml` 里 `MYSQL_ROOT_PASSWORD: admin`。
> - `--admin-password admin` 是你登录 ERPNext 的初始密码，**生产环境请改成强密码**。
> - 安装 app 这一步需要几分钟，耐心等待。

完成后退出容器：

```bash
exit
```

---

## 第四步：打开浏览器

本地访问：

```
http://localhost:8080
```

> 如果你用的是 `mysite.localhost` 以外的站点名（比如真实域名），需要在浏览器请求头里带上对应的 Host，或者直接通过域名访问。
> 本地测试最简单的方式：在 `/etc/hosts` 里加一行 `127.0.0.1 mysite.localhost`，然后访问 `http://mysite.localhost:8080`。

**登录信息：**

| 字段 | 值 |
|------|----|
| 用户名 | `Administrator` |
| 密码 | `admin`（你在第三步设置的） |

---

## 常用命令速查

```bash
# 查看所有容器状态
docker compose ps

# 查看实时日志
docker compose logs -f

# 停止所有服务
docker compose down

# 重启所有服务
docker compose restart

# 进入 backend 容器（执行 bench 命令）
docker compose exec backend bash

# 查看已有站点列表
docker compose exec backend bench --site all list-apps
```

---

## 遇到问题？

### 容器一直重启 / 起不来

```bash
docker compose logs backend
docker compose logs db
```

看报错信息，90% 的问题是端口冲突或内存不足。

### 建站时报数据库连接错误

确认 `db` 容器已经健康运行：

```bash
docker compose ps db
# STATUS 应该显示 healthy
```

如果不是 `healthy`，等 30 秒再试，或者查看 `docker compose logs db`。

### 忘记 admin 密码

```bash
docker compose exec backend bash
bench --site mysite.localhost set-admin-password 新密码
exit
```

---

## 下一步

跑起来之后，建议按顺序阅读：

1. **[01_ERPNext_Micro_Server_Install.md](./01_ERPNext_Micro_Server_Install.md)** — 生产环境部署（1Panel + 多租户架构）
2. **[02_Advanced_Backup_Restore_Tenant.md](./02_Advanced_Backup_Restore_Tenant.md)** — 备份与恢复
3. **[03_Chart_of_Accounts_Import.md](./03_Chart_of_Accounts_Import.md)** — 导入中国财务科目表
4. **[04_Custom_Translation_Import.md](./04_Custom_Translation_Import.md)** — 导入中文汉化补丁

---

*文档维护：青皮科技 CTO | 更新时间：2026-03-16*
