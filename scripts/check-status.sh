#!/bin/bash

# 存储技术知识库状态检查脚本
# 每天中午12:00自动运行

KB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$KB_DIR/logs"
STATUS_FILE="$LOG_DIR/system-status-$(date +%Y%m%d).txt"

echo "=== 存储技术知识库系统状态检查 ===" > "$STATUS_FILE"
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S %Z')" >> "$STATUS_FILE"
echo "系统时间: $(date)" >> "$STATUS_FILE"
echo "" >> "$STATUS_FILE"

# 1. 系统信息
echo "🖥️  系统信息:" >> "$STATUS_FILE"
echo "主机名: $(hostname)" >> "$STATUS_FILE"
echo "用户: $(whoami)" >> "$STATUS_FILE"
echo "时区: $(date +%Z)" >> "$STATUS_FILE"
echo "" >> "$STATUS_FILE"

# 2. 知识库目录状态
echo "📁 知识库目录状态:" >> "$STATUS_FILE"
echo "知识库路径: $KB_DIR" >> "$STATUS_FILE"
echo "目录大小: $(du -sh "$KB_DIR" | cut -f1)" >> "$STATUS_FILE"
echo "文件数量: $(find "$KB_DIR" -type f | wc -l)" >> "$STATUS_FILE"
echo "目录数量: $(find "$KB_DIR" -type d | wc -l)" >> "$STATUS_FILE"
echo "" >> "$STATUS_FILE"

# 3. Git状态
echo "🔧 Git仓库状态:" >> "$STATUS_FILE"
cd "$KB_DIR"
echo "当前分支: $(git branch --show-current 2>/dev/null || echo '未初始化')" >> "$STATUS_FILE"
echo "远程仓库: $(git remote get-url origin 2>/dev/null || echo '未配置')" >> "$STATUS_FILE"
echo "最后提交: $(git log -1 --format="%H %ad %s" --date=short 2>/dev/null || echo '无提交历史')" >> "$STATUS_FILE"
echo "未提交更改: $(git status --short 2>/dev/null | wc -l) 个文件" >> "$STATUS_FILE"
echo "" >> "$STATUS_FILE"

# 4. 日志状态
echo "📊 日志文件状态:" >> "$STATUS_FILE"
if [ -d "$LOG_DIR" ]; then
    echo "日志目录: $LOG_DIR" >> "$STATUS_FILE"
    echo "日志文件数量: $(find "$LOG_DIR" -name "*.log" -type f | wc -l)" >> "$STATUS_FILE"
    echo "日志总大小: $(du -sh "$LOG_DIR" | cut -f1)" >> "$STATUS_FILE"
    
    # 显示最新的日志文件
    echo "" >> "$STATUS_FILE"
    echo "最新的日志文件:" >> "$STATUS_FILE"
    find "$LOG_DIR" -name "*.log" -type f -exec ls -lh {} \; 2>/dev/null | head -5 >> "$STATUS_FILE"
else
    echo "日志目录不存在: $LOG_DIR" >> "$STATUS_FILE"
fi
echo "" >> "$STATUS_FILE"

# 5. 定时任务状态
echo "⏰ 定时任务状态:" >> "$STATUS_FILE"
CRON_COUNT=$(crontab -l 2>/dev/null | grep -c "storage-knowledge-base")
if [ "$CRON_COUNT" -gt 0 ]; then
    echo "已配置 $CRON_COUNT 个相关定时任务" >> "$STATUS_FILE"
    crontab -l 2>/dev/null | grep -A2 -B2 "storage-knowledge-base" >> "$STATUS_FILE"
else
    echo "未找到相关定时任务" >> "$STATUS_FILE"
fi
echo "" >> "$STATUS_FILE"

# 6. 脚本状态
echo "🛠️  脚本状态:" >> "$STATUS_FILE"
SCRIPTS=("simple-collector.py" "sync-to-github.sh" "check-status.sh")
for script in "${SCRIPTS[@]}"; do
    if [ -f "$KB_DIR/scripts/$script" ]; then
        echo "✅ $script: 存在且可执行" >> "$STATUS_FILE"
    else
        echo "❌ $script: 不存在" >> "$STATUS_FILE"
    fi
done
echo "" >> "$STATUS_FILE"

# 7. 今日日报状态
echo "📰 今日日报状态:" >> "$STATUS_FILE"
TODAY=$(date +%Y-%m-%d)
DAILY_REPORT="$KB_DIR/01-每日简报/$TODAY-存储技术日报.md"
if [ -f "$DAILY_REPORT" ]; then
    echo "✅ 今日日报已生成: $(basename "$DAILY_REPORT")" >> "$STATUS_FILE"
    echo "文件大小: $(du -h "$DAILY_REPORT" | cut -f1)" >> "$STATUS_FILE"
    echo "生成时间: $(stat -c %y "$DAILY_REPORT" 2>/dev/null | cut -d'.' -f1)" >> "$STATUS_FILE"
else
    echo "❌ 今日日报未生成" >> "$STATUS_FILE"
    echo "预期文件: $DAILY_REPORT" >> "$STATUS_FILE"
fi
echo "" >> "$STATUS_FILE"

# 8. 磁盘空间
echo "💾 磁盘空间状态:" >> "$STATUS_FILE"
df -h "$KB_DIR" >> "$STATUS_FILE" 2>&1
echo "" >> "$STATUS_FILE"

# 9. 系统负载
echo "⚡ 系统负载:" >> "$STATUS_FILE"
uptime >> "$STATUS_FILE" 2>&1
echo "" >> "$STATUS_FILE"

# 10. 网络连接（GitHub）
echo "🌐 GitHub连接测试:" >> "$STATUS_FILE"
if timeout 5 ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "✅ SSH连接GitHub正常" >> "$STATUS_FILE"
else
    echo "❌ SSH连接GitHub失败" >> "$STATUS_FILE"
fi

# 测试HTTPS连接
if timeout 5 curl -s https://github.com > /dev/null; then
    echo "✅ HTTPS访问GitHub正常" >> "$STATUS_FILE"
else
    echo "❌ HTTPS访问GitHub失败" >> "$STATUS_FILE"
fi
echo "" >> "$STATUS_FILE"

# 11. 建议和警告
echo "⚠️  系统检查结果:" >> "$STATUS_FILE"

# 检查GitHub同步
LAST_SYNC=$(find "$LOG_DIR" -name "sync.log" -type f -exec tail -1 {} \; 2>/dev/null | grep -o "自动更新.*" || echo "未知")
if [[ "$LAST_SYNC" == *"成功"* ]] || [[ "$LAST_SYNC" == *"SUCCESS"* ]]; then
    echo "✅ GitHub同步正常" >> "$STATUS_FILE"
else
    echo "❌ GitHub同步可能有问题" >> "$STATUS_FILE"
    echo "最后同步: $LAST_SYNC" >> "$STATUS_FILE"
fi

# 检查日报生成
if [ -f "$DAILY_REPORT" ]; then
    REPORT_AGE=$(( $(date +%s) - $(stat -c %Y "$DAILY_REPORT" 2>/dev/null || echo 0) ))
    if [ "$REPORT_AGE" -lt 86400 ]; then  # 24小时内
        echo "✅ 日报生成正常（24小时内）" >> "$STATUS_FILE"
    else
        echo "⚠️  日报可能过期（超过24小时）" >> "$STATUS_FILE"
    fi
else
    echo "❌ 日报未生成" >> "$STATUS_FILE"
fi

# 检查磁盘空间
DISK_USAGE=$(df "$KB_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "⚠️  磁盘空间不足: ${DISK_USAGE}%" >> "$STATUS_FILE"
elif [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠️  磁盘空间紧张: ${DISK_USAGE}%" >> "$STATUS_FILE"
else
    echo "✅ 磁盘空间充足: ${DISK_USAGE}%" >> "$STATUS_FILE"
fi
echo "" >> "$STATUS_FILE"

echo "=== 检查完成 ===" >> "$STATUS_FILE"

# 输出摘要到控制台
echo "✅ 状态检查完成"
echo "📄 详细报告: $STATUS_FILE"
echo ""
echo "📋 检查摘要:"
echo "  系统时间: $(date '+%H:%M:%S')"
echo "  知识库大小: $(du -sh "$KB_DIR" | cut -f1)"
echo "  今日日报: $(if [ -f "$DAILY_REPORT" ]; then echo "✅ 已生成"; else echo "❌ 未生成"; fi)"
echo "  GitHub同步: $(if [[ "$LAST_SYNC" == *"成功"* ]]; then echo "✅ 正常"; else echo "⚠️  需检查"; fi)"
echo "  定时任务: $CRON_COUNT 个"
echo "  磁盘使用: ${DISK_USAGE}%"

# 如果有严重问题，显示警告
if [ ! -f "$DAILY_REPORT" ] || [ "$DISK_USAGE" -gt 90 ]; then
    echo ""
    echo "⚠️  警告: 发现需要关注的问题，请查看详细报告"
fi