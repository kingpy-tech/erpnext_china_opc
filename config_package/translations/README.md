# ERPNext 中英对照翻译补丁 (一人公司合规套件)

## 痛点与初衷
在使用 ERPNext 时，我们会发现官方的中文语言包虽然覆盖了大部分基础界面，但对于财务（Accounting）、税务等核心模块的很多专业词汇（例如：Account Category 科目类别）依然是全英文。

如果直接修改底层代码进行汉化，不仅门槛高，而且在未来系统升级时极易被覆盖或导致系统崩溃。
因此，我们坚持 **Frappe First (低代码/无代码)** 原则，采用原生的 **Translation (自定义翻译)** 功能。翻译采用 **纯中文译文** 策略（例如：将 `Trade Receivables` 翻译为 `应收账款`），不使用括号中英混排。

## 如何使用本补丁？

你可以直接通过 ERPNext 自带的数据导入工具，无损地将这些翻译应用到你的系统中。

### 1. 下载翻译文件
1. 在本目录中，找到你需要的翻译补丁文件，例如：[`account_category_zh.csv`](account_category_zh.csv)。
2. 点击文件，然后点击右上角的 **Raw (原始数据)** 或者 **Download (下载)** 按钮，将 CSV 文件保存到本地电脑。

### 2. 在 ERPNext 中导入
1. 登录你的 ERPNext 系统。
2. 在顶部全局搜索栏中搜索并进入 **Data Import (数据导入)** 列表，点击右上方的 **Add Data Import (新建)**。
3. **Document Type (文档类型)**：选择 `Translation` (翻译)。
4. **Import Type (导入类型)**：选择 `Insert New Records` (插入新记录)。 *(提示：如果后续你需要覆盖更新，可以选择 Update Records)*。
5. 点击右上角的 **Save (保存)**。
6. 点击表单中的 **Attach File (附加文件)**，将刚刚下载的 CSV 文件上传。
7. 系统会自动将 CSV 的表头（Language, Source Text, Translated Text）与字段进行匹配。
8. 点击右上角的 **Start Import (开始导入)**，等待进度条完成。

### 3. 刷新并使翻译生效
由于翻译内容会存在浏览器和系统缓存中，导入成功后需要强制刷新：
- 点击 ERPNext 界面右上角的 **个人头像** -> 选择 **Reload (重新加载)**。
- 此时，再次进入相应的模块页面，原本纯英文的词汇就会显示为友好的中文翻译了！

## 参与共建
如果你在使用过程中发现了其他未汉化的界面，欢迎一起参与完善这个补丁库！
1. 点击本仓库右上角的 **Fork**。
2. 在 CSV 文件末尾新增一行，严格按照以下格式录入：
   `zh,系统显示的纯英文,你的中文翻译`
   *(注意：标点符号均为英文半角，首字母大小写必须与系统原词完全一致)*
3. 提交 **Pull Request**。我们将持续合并，打造最适合中国小微企业的 ERPNext 翻译库！

## 与分离更新脚本联动（推荐，避免升级后丢翻译）

为了避免每次升级后忘记导入翻译，已在
`config_package/setup_scripts/auto_update_erpnext.sh`
中加入“升级后自动导入翻译 CSV（幂等）”能力。

### 默认行为
- `AUTO_IMPORT_TRANSLATIONS=1`（默认开启）
- `TRANSLATION_DIR=/opt/1panel/docker/compose/erpnext/translations`
- `TRANSLATION_GLOB=*_zh.csv`

脚本会在 `migrate` 之后、资源验收之前：
1. 扫描翻译目录下的 `*_zh.csv`
2. 对每个站点执行“仅不存在则插入”的导入（不会覆盖原英文业务字段）
3. 清理缓存并输出 `zh_count` 作为校验

### 使用示例

```bash
# 默认开启自动导入翻译
bash auto_update_erpnext.sh

# 临时关闭自动导入翻译
AUTO_IMPORT_TRANSLATIONS=0 bash auto_update_erpnext.sh

# 指定翻译目录和匹配规则
TRANSLATION_DIR=/opt/1panel/docker/compose/erpnext/translations \
TRANSLATION_GLOB='*_zh.csv' \
bash auto_update_erpnext.sh
```
