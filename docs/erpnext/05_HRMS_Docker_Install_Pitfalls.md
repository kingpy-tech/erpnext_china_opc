# 05 Docker 环境下手动安装 HRMS 的七个坑

## 痛点切入

从 ERPNext v14 开始，HRMS（人力资源）模块从核心包中彻底拆分。对于"一人公司"来说，发工资、算个税是刚需，绕不开。

官方文档写的是一行 `bench get-app hrms && bench install-app hrms`，看起来很简单。但在 **Docker Compose 部署 + 国内网络** 的组合下，这条命令会连续触发至少 7 个不同的报错，每一个都能让你卡半天。

本文记录完整的排坑过程，供后来者参考。

---

## 环境说明

- ERPNext: `frappe/erpnext:latest` (Docker)
- 宿主机: 小米迷你主机，Ubuntu，局域网 IP `192.168.1.12`
- 面板: 1Panel，容器名 `erpnext-backend-1`

---

## 坑 1：`bench get-app` 拉不下来 GitHub 代码

**现象**：`bench get-app https://github.com/frappe/hrms` 卡住或报 `Connection timed out`。

**原因**：容器内直连 GitHub 被墙。

**解法**：用 `gitclone.com` 镜像加速：

```bash
docker exec erpnext-backend-1 bash -c \
  'bench get-app https://gitclone.com/github.com/frappe/hrms'
```

---

## 坑 2：`pip install` 装到了系统 Python，不是 bench 的 venv

**现象**：`pip install -e apps/hrms` 报 `pip install --user` 警告，或装完后 `bench install-app hrms` 仍报 `ModuleNotFoundError: No module named 'hrms'`。

**原因**：容器里有两套 Python：
- 系统 Python：`/usr/bin/python3`
- bench venv：`/home/frappe/frappe-bench/env/bin/python`

直接跑 `pip` 用的是系统 Python，bench 运行时用的是 venv，两者互不相通。

**解法**：必须用 venv 里的 pip：

```bash
docker exec erpnext-backend-1 \
  /home/frappe/frappe-bench/env/bin/pip install -e /home/frappe/frappe-bench/apps/hrms
```

---

## 坑 3：容器内代理环境变量残留，pip 连不上镜像源

**现象**：pip 报 `ProxyError` 或 `Connection refused`，即使你已经关了宿主机代理。

**原因**：之前为了拉 Docker 镜像，在 `docker-compose.yml` 里设置了 `HTTP_PROXY` / `HTTPS_PROXY` 环境变量，这些变量会被 pip 自动读取，导致 pip 也走代理，而代理此时已不可用。

**解法**：执行 pip 前先 unset：

```bash
docker exec erpnext-backend-1 bash -c \
  'unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy && \
   /home/frappe/frappe-bench/env/bin/pip install \
   -i https://pypi.tuna.tsinghua.edu.cn/simple \
   -e /home/frappe/frappe-bench/apps/hrms'
```

---

## 坑 4：`flit_core` 构建依赖在 venv 里缺失

**现象**：pip 报 `ModuleNotFoundError: No module named 'flit_core'` 或 `build backend 'flit_core.buildapi' failed`。

**原因**：hrms 用 `flit` 作为构建后端，但 bench venv 里没有预装 `flit_core`。

**解法**：先装构建依赖，再装 hrms：

```bash
# 先装 flit_core
docker exec erpnext-backend-1 bash -c \
  'unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy && \
   /home/frappe/frappe-bench/env/bin/pip install \
   -i https://pypi.tuna.tsinghua.edu.cn/simple flit_core'

# 再用 --no-build-isolation 跳过重复下载构建依赖
docker exec erpnext-backend-1 bash -c \
  'unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy && \
   /home/frappe/frappe-bench/env/bin/pip install \
   -i https://pypi.tuna.tsinghua.edu.cn/simple \
   --no-build-isolation \
   -e /home/frappe/frappe-bench/apps/hrms'
```

---

## 坑 5：`apps.txt` 里没有 hrms，bench 不认识这个 app

**现象**：`bench install-app hrms` 报 `App hrms not found`。

**原因**：`bench get-app` 正常流程会自动把 app 名写入 `sites/apps.txt`，但如果是手动克隆代码或中途出错，这一步可能被跳过。

**解法**：手动追加：

```bash
docker exec erpnext-backend-1 bash -c \
  'echo hrms >> /home/frappe/frappe-bench/sites/apps.txt'
```

---

## 坑 6：`Leave Application` 权限冲突导致 migrate 失败

**现象**：`bench install-app hrms` 在执行 migrate 时报：

```
frappe.exceptions.ValidationError: 
Row #X: DocPerm cannot have Amend without Create permission
```

**原因**：hrms 的 `Leave Application` DocType 的 fixtures 里，`Leave Approver` 角色在 level 0 设置了 `amend=1` 但 `create=0`，Frappe 的权限校验器拒绝这种组合。

**解法**：用 `bench mariadb` 直接修数据库：

```bash
docker exec erpnext-backend-1 bash -c \
  'cd /home/frappe/frappe-bench && \
   bench --site 192.168.1.12 mariadb -e \
   "UPDATE tabDocPerm SET \`create\`=1 \
    WHERE \`amend\`=1 AND \`create\`=0 \
    AND parent=\"Leave Application\""'
```

修完再重跑 `bench install-app hrms`。

---

## 坑 7：残留的 `.pth` 文件权限冲突

**现象**：pip 报 `ERROR: Could not install packages due to an OSError: [Errno 13] Permission denied: '/usr/local/lib/python3.14/site-packages/hrms.pth'`。

**原因**：之前用 root 身份跑过一次 pip，留下了一个 root 所有的 `.pth` 文件，现在 frappe 用户无法覆盖。

**解法**：用 root 删掉残留文件：

```bash
docker exec --user root erpnext-backend-1 \
  rm -f /usr/local/lib/python3.14/site-packages/hrms.pth
```

---

## 完整正确流程（一次过版）

```bash
# 1. 拉代码（用 gitclone 镜像）
docker exec erpnext-backend-1 bash -c \
  'bench get-app https://gitclone.com/github.com/frappe/hrms'

# 2. 清代理 + 装构建依赖 + 装 hrms 到 venv
docker exec erpnext-backend-1 bash -c \
  'unset HTTP_PROXY HTTPS_PROXY http_proxy https_proxy ALL_PROXY all_proxy && \
   /home/frappe/frappe-bench/env/bin/pip install \
   -i https://pypi.tuna.tsinghua.edu.cn/simple flit_core && \
   /home/frappe/frappe-bench/env/bin/pip install \
   -i https://pypi.tuna.tsinghua.edu.cn/simple \
   --no-build-isolation \
   -e /home/frappe/frappe-bench/apps/hrms'

# 3. 确认 apps.txt 有 hrms
docker exec erpnext-backend-1 bash -c \
  'grep -q hrms /home/frappe/frappe-bench/sites/apps.txt || \
   echo hrms >> /home/frappe/frappe-bench/sites/apps.txt'

# 4. 安装到 site
docker exec erpnext-backend-1 bash -c \
  'bench --site 192.168.1.12 install-app hrms'
```

如果第 4 步报 `Amend without Create` 权限错误，先跑坑 6 的 SQL 修复，再重试第 4 步。

---

## 避坑总结

| 坑 | 根因 | 一句话解法 |
|---|---|---|
| GitHub 拉不下来 | 国内网络 | 用 gitclone.com 镜像 |
| 装到系统 Python | 两套 Python 共存 | 用 venv 里的 pip |
| pip 走代理失败 | compose 环境变量残留 | unset 代理变量 |
| flit_core 缺失 | venv 没有构建依赖 | 先单独装 flit_core |
| bench 不认识 hrms | apps.txt 未更新 | 手动 echo hrms >> apps.txt |
| 权限校验失败 | fixtures 数据 bug | bench mariadb 直接修 |
| .pth 权限冲突 | root 残留文件 | docker exec --user root 删除 |
