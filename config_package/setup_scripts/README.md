# 自动安装与更新脚本说明

这里提供 ERPNext China OPC 在红米服务器上的基础配置与更新脚本。

## 重要策略变更（已生效）

- **已停用**“ERPNext+HRMS 集成打包镜像”方案；
- **改为**在同一 bench 内对 `erpnext` 与 `hrms` **分别更新**；
- `build_custom_image_v16.sh` 已废弃，仅保留提示用途；
- 日常升级统一使用 `auto_update_erpnext.sh`。

参考文档：`docs/erpnext/07_ERPNext_HRMS_Separated_Update.md`

## 脚本功能

1. **分离更新 ERPNext 与 HRMS**：`auto_update_erpnext.sh`
   - 拉取基础服务并分阶段启动；
   - 确保 `apps/hrms` 存在并可导入；
   - 分别执行：
     - `bench update --apps erpnext ...`
     - `bench update --apps hrms ...`
   - 逐站点 `migrate / clear-cache`；
   - 可选自动导入翻译 CSV（幂等）。
2. **检测 ERPNext 新版本**：`check_erpnext_updates.sh`
3. **初始化 OPC 配置**：`install_opc_suite.py`
   - 导入自定义翻译（会计类别）；
   - 调整核心单据命名规则；
   - 引导网页导入会计科目表。

## 使用指引

你可以登录 ERPNext 服务器（SSH），按需执行以下脚本：

### A. 分离更新（推荐）

```bash
ssh redmi-lan

COMPOSE_DIR=/opt/1panel/docker/compose/erpnext \
ERPNEXT_BRANCH=version-16 \
HRMS_BRANCH=version-16 \
SITE_SCOPE=all \
ENABLE_BACKUP=0 \
bash /Users/shiny/Documents/Qingpi_Tech/Projects/erpnext_china_opc/config_package/setup_scripts/auto_update_erpnext.sh
```

> 若需先备份，设置 `ENABLE_BACKUP=1`。

### B. OPC 初始化配置脚本

在 `frappe-bench` 目录下用 bench 环境 Python 运行：

### 执行步骤

1. 将本仓库的内容克隆或上传到你的 ERPNext 服务器上。
2. 进入你的 `frappe-bench` 目录：
   ```bash
   cd /你的/路径/frappe-bench
   ```
3. 使用 bench 虚拟环境的 Python 执行本脚本，并传入你的站点名称（例如 `site1.local` 或你的真实域名）：
   ```bash
   ./env/bin/python /本仓库的绝对路径/config_package/setup_scripts/install_opc_suite.py [你的站点名称]
   ```

**示例命令**：
假设本代码库放置在 `/opt/erpnext_china_opc`，并且你的站点名叫 `opc.kingpy.com`，则执行：
```bash
./env/bin/python /opt/erpnext_china_opc/config_package/setup_scripts/install_opc_suite.py opc.kingpy.com
```

### 预期结果
执行后，脚本将连接到你的站点数据库并自动插入上述记录。请在执行完毕后，登录到 ERPNext 并在右上角点击**重新加载 (Reload)** 以清除前端缓存。