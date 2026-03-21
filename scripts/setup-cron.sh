#!/bin/bash

# 存储技术知识库定时任务配置脚本
# 作者: 小Z (个人助手)
# 用途: 自动配置cron定时任务

set -e

# 配置变量
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KB_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$KB_DIR/logs"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查目录
check_directories() {
    log_info "检查目录结构..."
    
    if [ ! -d "$KB_DIR" ]; then
        log_error "知识库目录不存在: $KB_DIR"
        exit 1
    fi
    
    if [ ! -d "$LOG_DIR" ]; then
        log_info "创建日志目录: $LOG_DIR"
        mkdir -p "$LOG_DIR"
    fi
    
    if [ ! -f "$KB_DIR/scripts/simple-collector.py" ]; then
        log_error "信息收集脚本不存在: $KB_DIR/scripts/simple-collector.py"
        exit 1
    fi
    
    if [ ! -f "$KB_DIR/scripts/sync-to-github.sh" ]; then
        log_error "GitHub同步脚本不存在: $KB_DIR/scripts/sync-to-github.sh"
        exit 1
    fi
    
    log_success "目录检查完成"
}

# 生成cron配置
generate_cron_config() {
    log_info "生成cron配置..."
    
    CRON_FILE="/tmp/storage-kb-cron.$$"
    
    cat > "$CRON_FILE" << EOF
# ============================================
# 存储技术知识库自动化任务配置
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# 知识库目录: $KB_DIR
# ============================================

# 每天早晨8:00 - 收集存储技术信息
0 8 * * * cd $KB_DIR && python3 scripts/simple-collector.py >> $LOG_DIR/collection.log 2>&1

# 每天凌晨2:00 - 同步到GitHub
0 2 * * * cd $KB_DIR && ./scripts/sync-to-github.sh >> $LOG_DIR/sync.log 2>&1

# 每周日凌晨3:00 - 清理旧日志（保留7天）
0 3 * * 0 find $LOG_DIR -name "*.log" -mtime +7 -delete

# 每月1日凌晨4:00 - 生成月度报告
0 4 1 * * cd $KB_DIR && python3 scripts/generate-monthly-report.py >> $LOG_DIR/monthly.log 2>&1 2>/dev/null || true

# 每天中午12:00 - 检查系统状态（可选）
0 12 * * * cd $KB_DIR && ./scripts/check-status.sh >> $LOG_DIR/status.log 2>&1 2>/dev/null || true

# ============================================
# 注意:
# 1. 所有时间基于系统时区: $(date +%Z)
# 2. 日志文件保存在: $LOG_DIR
# 3. 如需修改时间，请调整分钟和小时
# ============================================
EOF
    
    echo "$CRON_FILE"
}

# 显示当前cron配置
show_current_cron() {
    log_info "当前cron配置:"
    echo "============================================"
    crontab -l 2>/dev/null || echo "（空）"
    echo "============================================"
}

# 安装cron配置
install_cron() {
    local cron_file="$1"
    
    log_info "安装cron配置..."
    
    # 备份现有配置
    BACKUP_FILE="$LOG_DIR/cron-backup-$(date +%Y%m%d-%H%M%S).txt"
    crontab -l 2>/dev/null > "$BACKUP_FILE" || true
    
    if [ -s "$BACKUP_FILE" ]; then
        log_info "已备份现有cron配置到: $BACKUP_FILE"
    fi
    
    # 安装新配置
    if crontab "$cron_file"; then
        log_success "cron配置安装成功"
    else
        log_error "cron配置安装失败"
        return 1
    fi
    
    # 清理临时文件
    rm -f "$cron_file"
}

# 验证cron服务
verify_cron_service() {
    log_info "验证cron服务状态..."
    
    if systemctl is-active cron >/dev/null 2>&1 || systemctl is-active crond >/dev/null 2>&1; then
        log_success "cron服务正在运行"
    else
        log_warning "cron服务未运行，尝试启动..."
        
        if command -v systemctl >/dev/null 2>&1; then
            if sudo systemctl start cron 2>/dev/null || sudo systemctl start crond 2>/dev/null; then
                log_success "cron服务启动成功"
            else
                log_error "无法启动cron服务"
                return 1
            fi
        else
            log_warning "无法自动启动cron服务，请手动启动"
        fi
    fi
}

# 测试定时任务
test_cron_jobs() {
    log_info "测试定时任务..."
    
    # 测试信息收集
    log_info "测试信息收集脚本..."
    if cd "$KB_DIR" && python3 scripts/simple-collector.py >> "$LOG_DIR/test-collection.log" 2>&1; then
        log_success "信息收集脚本测试成功"
    else
        log_error "信息收集脚本测试失败"
        return 1
    fi
    
    # 测试GitHub同步
    log_info "测试GitHub同步脚本..."
    if cd "$KB_DIR" && ./scripts/sync-to-github.sh >> "$LOG_DIR/test-sync.log" 2>&1; then
        log_success "GitHub同步脚本测试成功"
    else
        log_warning "GitHub同步脚本测试可能有警告，请检查日志"
    fi
    
    # 显示测试日志
    log_info "测试日志:"
    echo "--------------------------------------------"
    tail -5 "$LOG_DIR/test-collection.log" 2>/dev/null || echo "（无收集日志）"
    echo "--------------------------------------------"
    tail -5 "$LOG_DIR/test-sync.log" 2>/dev/null || echo "（无同步日志）"
    echo "--------------------------------------------"
}

# 显示配置摘要
show_config_summary() {
    log_info "定时任务配置摘要:"
    echo ""
    echo "📅 任务安排:"
    echo "  • 每天 08:00 - 收集存储技术信息"
    echo "  • 每天 02:00 - 同步到GitHub"
    echo "  • 每周日 03:00 - 清理旧日志"
    echo "  • 每月1日 04:00 - 生成月度报告"
    echo "  • 每天 12:00 - 检查系统状态"
    echo ""
    echo "📁 目录信息:"
    echo "  • 知识库目录: $KB_DIR"
    echo "  • 日志目录: $LOG_DIR"
    echo "  • 脚本目录: $KB_DIR/scripts"
    echo ""
    echo "📋 日志文件:"
    echo "  • 收集日志: $LOG_DIR/collection.log"
    echo "  • 同步日志: $LOG_DIR/sync.log"
    echo "  • 状态日志: $LOG_DIR/status.log"
    echo ""
    echo "🔧 管理命令:"
    echo "  • 查看定时任务: crontab -l"
    echo "  • 编辑定时任务: crontab -e"
    echo "  • 删除定时任务: crontab -r"
    echo ""
    echo "📞 故障排除:"
    echo "  • 查看cron日志: grep CRON /var/log/syslog"
    echo "  • 检查服务状态: systemctl status cron"
    echo "  • 手动测试脚本: ./scripts/simple-collector.py"
    echo ""
}

# 创建监控脚本
create_monitoring_scripts() {
    log_info "创建监控脚本..."
    
    # 创建状态检查脚本
    cat > "$KB_DIR/scripts/check-status.sh" << 'EOF'
#!/bin/bash
# 存储技术知识库状态检查脚本

KB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$KB_DIR/logs"
STATUS_FILE="$LOG_DIR/system-status-$(date +%Y%m%d).txt"

echo "=== 存储技术知识库系统状态检查 ===" > "$STATUS_FILE"
echo "检查时间: $(date '+%Y-%m-%d %H:%M:%S')" >> "$STATUS_FILE"
echo "" >> "$STATUS_FILE"

# 检查目录
echo "📁 目录检查:" >> "$STATUS_FILE"
ls -la "$KB_DIR" >> "$STATUS_FILE" 2>&1
echo "" >> "$STATUS_FILE"

# 检查Git状态
echo "🔧 Git状态:" >> "$STATUS_FILE"
cd "$KB_DIR" && git status --short >> "$STATUS_FILE" 2>&1
echo "" >> "$STATUS_FILE"

# 检查日志文件
echo "📊 日志状态:" >> "$STATUS_FILE"
ls -lh "$LOG_DIR"/*.log 2>/dev/null | head -10 >> "$STATUS_FILE"
echo "" >> "$STATUS_FILE"

# 检查磁盘空间
echo "💾 磁盘空间:" >> "$STATUS_FILE"
df -h "$KB_DIR" >> "$STATUS_FILE" 2>&1
echo "" >> "$STATUS_FILE"

# 检查cron任务
echo "⏰ Cron任务:" >> "$STATUS_FILE"
crontab -l 2>/dev/null | grep -i "storage\|knowledge" >> "$STATUS_FILE" || echo "未找到相关cron任务" >> "$STATUS_FILE"
echo "" >> "$STATUS_FILE"

echo "=== 检查完成 ===" >> "$STATUS_FILE"

# 输出摘要
echo "状态检查完成，报告保存在: $STATUS_FILE"
cat "$STATUS_FILE" | tail -20
EOF
    
    chmod +x "$KB_DIR/scripts/check-status.sh"
    log_success "状态检查脚本创建完成"
    
    # 创建月度报告脚本模板
    cat > "$KB_DIR/scripts/generate-monthly-report.py" << 'EOF'
#!/usr/bin/env python3
"""
存储技术知识库月度报告生成脚本
模板文件，实际功能需要根据需求实现
"""

import os
import datetime
from pathlib import Path

def generate_monthly_report():
    """生成月度报告"""
    kb_dir = Path(os.path.expanduser("~/.openclaw/workspace/storage-knowledge-base"))
    report_dir = kb_dir / "月度报告"
    report_dir.mkdir(exist_ok=True)
    
    # 获取当前月份
    now = datetime.datetime.now()
    month_str = now.strftime("%Y年%m月")
    
    # 月度报告模板
    report_content = f"""# 存储技术知识库月度报告 - {month_str}

## 📊 月度统计

### 1. 内容增长
- **新增文档:** 待统计
- **总文档数:** 待统计
- **知识库大小:** 待统计
- **Git提交次数:** 待统计

### 2. 学习进展
- **重点学习主题:** 待总结
- **掌握的新技术:** 待总结
- **解决的问题:** 待总结
- **实践项目:** 待总结

### 3. 技术趋势
- **本月热点技术:** 待分析
- **重要行业动态:** 待整理
- **新兴工具推荐:** 待推荐
- **安全更新汇总:** 待汇总

## 📈 学习成果

### 已完成
1. 待填写本月完成的学习内容
2. 待填写掌握的新技能
3. 待填写的实践项目

### 进行中
1. 待填写正在学习的内容
2. 待填写的未完成项目
3. 待解决的技术问题

### 计划中
1. 待填写下月学习计划
2. 待填写的实践项目计划
3. 待研究的新技术方向

## 🔍 深度分析

### 技术深度
- **重点技术分析:** 待深入分析本月重点技术
- **架构理解:** 待总结对存储架构的新理解
- **性能优化:** 待总结性能优化经验

### 行业洞察
- **市场趋势:** 待分析存储市场变化
- **技术方向:** 待预测技术发展方向
- **职业发展:** 待规划个人成长路径

## 🎯 下月计划

### 学习目标
1. **技术深度:** 待设定下月技术学习目标
2. **实践项目:** 待规划下月实践项目
3. **认证考试:** 待安排相关认证学习

### 知识库建设
1. **内容完善:** 待规划知识库完善方向
2. **工具优化:** 待优化自动化工具
3. **质量提升:** 待提升内容质量

### 职业发展
1. **技能提升:** 待明确下月技能提升重点
2. **项目经验:** 待积累相关项目经验
3. **行业交流:** 待参与行业交流活动

## 📝 总结与建议

### 本月总结
待填写本月的总体学习总结和收获

### 改进建议
1. 待提出知识库系统的改进建议
2. 待优化学习方法和效率
3. 待调整学习计划和重点

### 下月展望
待展望下月的学习和发展目标

---

**报告生成时间:** {now.strftime('%Y-%m-%d %H:%M:%S')}
**知识库版本:** 待确定
**维护者:** 小Z (个人助手)
**用户:** 大Z (企业级存储技术支持专家)
"""

    # 保存报告
    report_file = report_dir / f"{month_str}-月度报告.md"
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write(report_content)
    
    print(f"月度报告模板已生成: {report_file}")
    print("注意: 这是一个模板文件，需要根据实际数据填充内容")

if __name__ == "__main__":
    generate_monthly_report()
EOF
    
    chmod +x "$KB_DIR/scripts/generate-monthly-report.py"
    log_success "月度报告脚本模板创建完成"
}

# 主函数
main() {
    log_info "开始配置存储技术知识库定时任务..."
    log_info "知识库目录: $KB_DIR"
    
    # 执行各个步骤
    check_directories
    verify_cron_service
    show_current_cron
    
    # 生成cron配置
    CRON_FILE=$(generate_cron_config)
    
    # 显示将要安装的配置
    log_info "将要安装的cron配置:"
    echo "============================================"
    cat "$CRON_FILE"
    echo "============================================"
    
    # 询问确认
    echo ""
    read -p "是否安装上述定时任务配置？(y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 测试脚本
        test_cron_jobs
        
        # 创建监控脚本
        create_monitoring_scripts
        
        # 安装cron配置
        install_cron "$CRON_FILE"
        
        # 显示最终配置
        show_current_cron
        
        # 显示配置摘要
        show_config_summary
        
        log_success "定时任务配置完成！"
        log_info "系统将在以下时间自动运行:"
        log_info "  • 每天 08:00 - 信息收集"
        log_info "  • 每天 02:00 - GitHub同步"
        
    else
        log_warning "用户取消安装"
        log_info "你可以手动编辑cron配置: crontab -e"
        log_info "或使用生成的配置文件: $CRON_FILE"
    fi
    
    # 清理
    rm -f "$CRON_FILE"
}

# 执行主函数
main "$@"