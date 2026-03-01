#!/bin/bash
# ------------------------------------------------------------------------
# ERPNext 新版本检测并通知脚本 (红米服务器版)
# 用途：定期检测官方 GitHub Releases，如果发现新版本，可以通过 webhook 发送通知。
# ------------------------------------------------------------------------
set -e

# 当前部署的版本（这只是个记录，实际可以从 Docker 容器内部获取 `bench version`）
CURRENT_VERSION="v16.7.2"

# 获取官方的最新 Release 版本号
# 如果服务器无法直接访问 GitHub API，需要在这里设置代理 (例如: curl -x http://192.168.1.12:7890 ...)
LATEST_VERSION=$(curl -s "https://api.github.com/repos/frappe/erpnext/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')

echo "当前部署的版本是: $CURRENT_VERSION"
echo "官方最新的版本是: $LATEST_VERSION"

if [ "$CURRENT_VERSION" != "$LATEST_VERSION" ] && [ -n "$LATEST_VERSION" ]; then
    echo "发现新版本 ERPNext $LATEST_VERSION！建议寻找合适的维护窗口进行手动升级。"

    # 【可选】发送通知给你的手机或团队群聊
    # 例如：利用企业微信、钉钉或飞书的 Webhook 机器人，或者 Server 酱
    # 下面是一个示例（如果你有 Webhook 地址的话取消注释并替换）：
    #
    # WEBHOOK_URL="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY"
    # curl -H "Content-Type: application/json" -X POST -d "{\"msgtype\": \"text\", \"text\": {\"content\": \"[通知] 发现 ERPNext 新版本：$LATEST_VERSION (当前是 $CURRENT_VERSION)，请找时间手动运行 auto_update_erpnext.sh 升级！\"}}" $WEBHOOK_URL
    #
else
    echo "已经是最新版或获取失败，无需更新。"
fi
