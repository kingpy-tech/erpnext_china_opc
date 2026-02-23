# 自动安装配置脚本

这里提供了一个基于 Python 的自动化脚本，旨在通过命令行一键完成 ERPNext China OPC 相关的基础配置，替代部分繁琐的网页端手动操作。

## 脚本功能

1. **导入自定义翻译**: 自动读取并导入 `config_package/translations/account_category_zh.csv` 中的词条（如将英文默认会计类别翻译成符合中国习惯的表述）。
2. **修改文档命名规则 (Naming Series)**: 批量将核心业务单据（日记账凭证、销售发票、采购发票、付款凭证）的前缀修改为动态公司缩写（`{.company_abbr}-XXX-.YYYY.-`）。
3. **提示科目表导入**: 引导最后一步通过网页导入会计科目表。

## 使用指引

你需要登录到你的 ERPNext 服务器（SSH 或终端），并在 `frappe-bench` 目录下使用 bench 环境的 python 运行此脚本。

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