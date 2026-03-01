# 05 Docker 部署 ERPNext + HRMS：官方自定义镜像构建方法

> ⚠️ 状态说明（红米服务器当前策略）
>
> 本文档保留为历史参考。`redmi-lan` 当前已切换为 **ERPNext 与 HRMS 分离更新**，不再作为推荐路径使用“集成打包镜像”。
>
> 请优先使用：`docs/erpnext/07_ERPNext_HRMS_Separated_Update.md`

## 痛点切入

ERPNext v14 之后，HRMS（人力资源）模块从核心包彻底拆分。官方 Docker Hub 上的 `frappe/erpnext` 镜像**不含 HRMS**，直接 `bench install-app hrms` 在容器里行不通——因为 `apps/` 目录没有持久化，容器重启后一切归零。

正确的做法是：**在构建镜像阶段就把 hrms 打进去**，而不是在运行时手动安装。Frappe 官方提供了完整的自定义镜像构建方案。

---

## 官方方案：用 `frappe_docker` + `apps.json` 构建自定义镜像

### 第一步：克隆官方构建仓库

```bash
git clone https://github.com/frappe/frappe_docker
cd frappe_docker
```

### 第二步：准备 `apps.json`

`apps.json` 定义镜像里要包含哪些 app。对于"一人公司"场景，至少需要 erpnext + hrms：

```json
[
  {
    "url": "https://github.com/frappe/erpnext",
    "branch": "version-15"
  },
  {
    "url": "https://github.com/frappe/hrms",
    "branch": "version-15"
  }
]
```

> 注意：`branch` 要和你的 frappe 版本对应。查看当前版本：`docker exec <backend容器> bench version`

### 第三步：构建自定义镜像

```bash
export APPS_JSON_BASE64=$(base64 -w 0 apps.json)

docker build \
  --build-arg=FRAPPE_PATH=https://github.com/frappe/frappe \
  --build-arg=FRAPPE_BRANCH=version-15 \
  --build-arg=PYTHON_VERSION=3.11 \
  --build-arg=NODE_VERSION=18.18.2 \
  --build-arg=APPS_JSON_BASE64=$APPS_JSON_BASE64 \
  --tag=custom-erpnext:latest \
  --file=images/custom/Containerfile .
```

构建时间约 10-20 分钟（需要下载依赖）。

### 第四步：更新 `docker-compose.yml`

把所有用到 `frappe/erpnext:latest` 的地方换成你刚构建的镜像：

```yaml
# 修改前
image: frappe/erpnext:latest

# 修改后
image: custom-erpnext:latest
```

通常需要修改的服务：`backend`、`frontend`、`queue-long`、`queue-short`、`scheduler`、`websocket`。

### 第五步：重启服务

```bash
docker compose down
docker compose up -d
```

Configurator 容器会自动执行 `ls -1 apps > sites/apps.txt`，因为镜像里已经有 hrms，所以 `apps.txt` 会自动包含它。

### 第六步：安装 hrms 到 site

```bash
docker exec <backend容器名> bench --site <你的site名> install-app hrms
```

---

## 验证

```bash
# 确认 hrms 已安装
docker exec <backend容器名> bench --site <你的site名> list-apps

# 预期输出：
# frappe
# erpnext
# hrms
```

浏览器访问 ERPNext，顶部导航栏应出现「Payroll」和「HR」模块。

---

## 避坑指南

| 问题 | 原因 | 解法 |
|---|---|---|
| 构建时 GitHub 拉不下来 | 国内网络 | 在有代理的环境下构建，或用 CI/CD（GitHub Actions）构建后推送到私有 Registry |
| `bench install-app hrms` 报权限错误 | fixtures 数据 bug（已知问题） | 见 [frappe/hrms#1234](https://github.com/frappe/hrms/issues) |
| 容器重启后 hrms 消失 | 在运行时手动安装而非镜像内置 | 必须用本文的构建方式，不要在运行中的容器里 `pip install` |
| `base64 -w 0` 在 macOS 不支持 | macOS 的 base64 没有 `-w` 参数 | macOS 用 `base64 -i apps.json` 替代 |

---

## 国内网络的替代方案

如果构建环境无法访问 GitHub，有两个选项：

**选项 A：在有代理的机器上构建，推送到私有 Registry**

```bash
# 构建完成后推送到本地 Registry
docker tag custom-erpnext:latest 192.168.1.x:5000/custom-erpnext:latest
docker push 192.168.1.x:5000/custom-erpnext:latest
```

**选项 B：用 GitHub Actions 自动构建**

Frappe 官方 `frappe_docker` 仓库提供了完整的 GitHub Actions workflow 模板，fork 后修改 `apps.json`，push 即可触发构建并推送到 GitHub Container Registry（ghcr.io）。详见官方文档：[Custom Apps](https://github.com/frappe/frappe_docker/blob/main/docs/custom-apps.md)。
