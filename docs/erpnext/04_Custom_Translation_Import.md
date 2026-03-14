# 04 自定义翻译 (Custom Translation) 导入指南

## 痛点切入
在 ERPNext 的使用中，我们会发现部分模块（例如 Accounting 财务模块下的 Account Category 科目类别）在官方的中文语言包中尚未完全汉化，界面上依然显示全英文（如 `Trade Receivables`）。
很多新手会尝试直接去修改系统的基础数据或底层代码来把它们改成中文，但这会带来严重后果：一旦系统进行版本升级，这些硬修改可能会被重置，或者导致系统更新失败。

## 我们的折腾解法
遵循 **“Frappe First”** 原则，我们绝不硬改底层代码。
Frappe 框架提供了原生的 **Translation（自定义翻译）** 功能。我们可以将这些尚未汉化的英文词汇收集起来，整理成 CSV 文件，然后通过 Data Import（数据导入）工具，统一导入到系统的自定义翻译库中。
这种方式的好处是：**与系统源码和预置数据完全解耦，随时可以随着版本更新，并且我们可以在 GitHub 上慢慢积累和完善这份翻译库。**

---

## 操作步骤

### 1. 准备翻译文件
在我们的合规套件目录下，已经为您准备好了一份初版的翻译文件：
`config_package/translations/account_category_zh.csv`

（注：为保留原有的英文语境以便对照系统文档，我们采用了中英对照的翻译方式，例如：将 `Trade Receivables` 翻译为 `Trade Receivables (应收账款)`。这满足了“不要改变原有英文的表述，只是作为翻译”的需求。）

### 2. 通过系统导入翻译
1. 登录 ERPNext 系统，在顶部全局搜索栏中搜索并打开 **Data Import (数据导入)**，点击右上方 **Add Data Import (新建)**。
2. **Document Type (文档类型)**：选择 `Translation` (翻译)。
3. **Import Type (导入类型)**：选择 `Insert New Records` (插入新记录)。
4. 点击右上角的 **Save (保存)**。
5. 点击 **Attach File (附加文件)**，上传我们的 `account_category_zh.csv` 文件。
6. 上传后，系统会自动将 CSV 的表头（Language, Source Text, Translated Text）与系统的字段进行映射。
7. 点击右上角的 **Start Import (开始导入)** 即可。

### 3. 刷新并使翻译生效
导入成功后，自定义翻译需要清空系统缓存才能在前端界面立刻生效。
- **界面操作**：点击 ERPNext 右上角的个人头像 -> 选择 **Reload (重新加载)**。
- 此时，再次进入 Account Category 等相关页面，你就会发现那些原本纯英文的词汇已经显示为包含中文的翻译了！

---

## 避坑指南
1. **精准匹配原则**：在 `Translation` 中，`Source Text` 必须和系统里显示的英文大小写、空格完全一模一样，否则系统在渲染界面时无法匹配到对应的翻译。
2. **避免重复翻译**：在导入前，最好确保系统原有的 Translation 列表里没有针对同一个词的其它中文翻译记录，否则可能发生冲突，导致生效的不是你期望的版本。
3. **Language Code**：在导入时，确保 `Language` 字段填写的是 `zh`（代表简体中文），而不是全拼 `Chinese`。我们在 CSV 模板中已经为您默认填好了 `zh`。
