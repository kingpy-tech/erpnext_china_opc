import frappe
import csv
import os
import sys

def run(site_name):
    # 初始化 Frappe 上下文
    frappe.init(site=site_name)
    frappe.connect()
    
    print(f"🚀 开始在站点 {site_name} 自动安装 ERPNext China OPC 合规套件...")
    
    # 获取当前脚本所在目录的上一级目录（config_package）
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    
    # 1. 导入自定义翻译
    print("\n[1/3] 正在导入自定义翻译 (Account Categories等)...")
    translation_file = os.path.join(base_dir, 'translations', 'account_category_zh.csv')
    if os.path.exists(translation_file):
        with open(translation_file, mode='r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            count = 0
            for row in reader:
                source_text = row.get('Source Text')
                translated_text = row.get('Translated Text')
                if source_text and translated_text:
                    # 检查是否已存在
                    if not frappe.db.exists('Translation', {'source_text': source_text, 'language': 'zh'}):
                        doc = frappe.new_doc('Translation')
                        doc.language = 'zh'
                        doc.source_text = source_text
                        doc.translated_text = translated_text
                        doc.insert(ignore_permissions=True)
                        count += 1
            frappe.db.commit()
            print(f"✅ 成功导入 {count} 条新的自定义翻译。")
    else:
        print(f"⚠️ 找不到翻译文件: {translation_file}")
        
    # 2. 修改文档命名规则 (Naming Series)
    print("\n[2/3] 正在更新核心业务单据的 Naming Series (将前缀替换为动态公司缩写)...")
    series_to_update = {
        "Journal Entry": "{.company_abbr}-JV-.YYYY.-",
        "Sales Invoice": "{.company_abbr}-SINV-.YYYY.-",
        "Purchase Invoice": "{.company_abbr}-PINV-.YYYY.-",
        "Payment Entry": "{.company_abbr}-PAY-.YYYY.-"
    }
    
    updated_count = 0
    for doctype, new_series in series_to_update.items():
        if frappe.db.exists("DocType", doctype):
            # 获取原有的命名选项
            options = frappe.db.get_value("DocField", {"parent": doctype, "fieldname": "naming_series"}, "options")
            
            # 使用 Property Setter 来覆盖默认的 naming_series
            frappe.make_property_setter({
                'doctype': doctype,
                'doctype_or_field': 'DocField',
                'fieldname': 'naming_series',
                'property': 'options',
                'value': new_series + "\n" + (options or ""),
                'property_type': 'Text'
            }, is_system_generated=False)
            print(f" - {doctype}: 新增 {new_series}")
            updated_count += 1
            
    frappe.db.commit()
    print(f"✅ 成功更新 {updated_count} 个 DocType 的命名规则。")
            
    # 3. 提示导入科目表
    print("\n[3/3] 关于会计科目表 (Chart of Accounts)...")
    coa_file = os.path.join(base_dir, 'chart_of_accounts', 'erpnext_accounts_backup.csv')
    print("💡 科目表强依赖于 ERPNext 的建账向导和公司实例，无法直接底层硬插入。")
    print(f"👉 请在浏览器中进入 [Data Import] 模块，上传并导入以下文件完成最后一步：\n   {coa_file}")
    
    print("\n🎉 ERPNext China OPC 配置脚本执行完毕！请在浏览器中刷新页面（Reload）。")
    
    # 清理 Frappe 上下文
    frappe.destroy()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("❌ 错误: 请提供站点名称。")
        print("用法: /path/to/frappe-bench/env/bin/python install_opc_suite.py [你的站点名]")
        sys.exit(1)
    
    site = sys.argv[1]
    run(site)
