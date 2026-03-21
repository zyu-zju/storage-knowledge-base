#!/bin/bash

# 简单定时任务配置脚本

KB_DIR="$HOME/.openclaw/workspace/storage-knowledge-base"
LOG_DIR="$KB_DIR/logs"

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 创建cron配置
CRON_CONFIG="# 存储技术知识库自动化任务
# 配置时间: $(date '+%Y-%m-%d %H:%M:%S')

# 每天早晨8:00 - 收集存储技术信息
0 8 * * * cd $KB_DIR && python3 scripts/simple-collector.py >> $LOG_DIR/collection.log 2>&1

# 每天凌晨2:00 - 同步到GitHub
0 2 * * * cd $KB_DIR && ./scripts/sync-to-github.sh >> $LOG_DIR/sync.log 2>&1

# 每周日凌晨3:00 - 清理旧日志（保留7天）
0 3 * * 0 find $LOG_DIR -name \"*.log\" -mtime +7 -delete

# 每天中午12:00 - 检查系统状态
0 12 * * * cd $KB_DIR && [ -f scripts/check-status.sh ] && ./scripts/check-status.sh >> $LOG_DIR/status.log 2>&1 || true"

echo "将要配置的定时任务:"
echo "========================================"
echo "$CRON_CONFIG"
echo "========================================"
echo ""

# 备份现有配置
BACKUP_FILE="$LOG_DIR/cron-backup-$(date +%Y%m%d-%H%M%S).txt"
crontab -l 2>/dev/null > "$BACKUP_FILE"
if [ -s "$BACKUP_FILE" ]; then
    echo "✅ 已备份现有cron配置到: $BACKUP_FILE"
else
    rm -f "$BACKUP_FILE"
fi

# 安装新配置
echo "$CRON_CONFIG" | crontab -

if [ $? -eq 0 ]; then
    echo "✅ cron配置安装成功！"
    echo ""
    echo "📅 配置的定时任务:"
    echo "  1. 每天 08:00 - 信息收集"
    echo "  2. 每天 02:00 - GitHub同步"
    echo "  3. 每周日 03:00 - 日志清理"
    echo "  4. 每天 12:00 - 系统检查"
    echo ""
    echo "📁 日志目录: $LOG_DIR"
    echo "🔧 查看配置: crontab -l"
    echo "✏️  编辑配置: crontab -e"
    echo "🗑️  删除配置: crontab -r"
else
    echo "❌ cron配置安装失败"
    exit 1
fi