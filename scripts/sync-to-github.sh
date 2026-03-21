#!/bin/bash

# 存储技术知识库 GitHub 同步脚本
# 作者: 小Z (个人助手)
# 用途: 自动将知识库同步到 GitHub 仓库

set -e  # 遇到错误立即退出

# 配置变量
KNOWLEDGE_BASE_DIR="$HOME/.openclaw/workspace/storage-knowledge-base"
GIT_REPO_DIR="$KNOWLEDGE_BASE_DIR"
COMMIT_MESSAGE="自动更新: $(date '+%Y年%m月%d日 %H:%M:%S') 的存储技术知识库更新"

# 颜色输出函数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# 检查目录是否存在
check_directory() {
    if [ ! -d "$GIT_REPO_DIR" ]; then
        log_error "知识库目录不存在: $GIT_REPO_DIR"
        exit 1
    fi
}

# 初始化 Git 仓库（如果尚未初始化）
init_git_repo() {
    cd "$GIT_REPO_DIR"
    
    if [ ! -d ".git" ]; then
        log_info "初始化 Git 仓库..."
        git init
        git config user.email "assistant@openclaw.ai"
        git config user.name "小Z助手"
        log_success "Git 仓库初始化完成"
    else
        log_info "Git 仓库已存在"
    fi
}

# 检查远程仓库配置
check_remote() {
    cd "$GIT_REPO_DIR"
    
    if git remote | grep -q "origin"; then
        log_info "远程仓库已配置"
        return 0
    else
        log_warning "未配置远程仓库"
        log_info "请使用以下命令配置远程仓库:"
        echo "cd $GIT_REPO_DIR"
        echo "git remote add origin <你的GitHub仓库URL>"
        echo "git branch -M main"
        return 1
    fi
}

# 生成更新摘要
generate_update_summary() {
    cd "$GIT_REPO_DIR"
    
    log_info "生成更新摘要..."
    
    # 获取今日日期
    TODAY=$(date '+%Y-%m-%d')
    
    # 检查今日是否有新文件
    NEW_FILES=$(find . -type f -name "*.md" -newer "$GIT_REPO_DIR/.last_sync" 2>/dev/null || find . -type f -name "*.md")
    
    if [ -z "$NEW_FILES" ]; then
        log_warning "未发现新的Markdown文件"
        echo "## 更新摘要" > "$GIT_REPO_DIR/更新摘要.md"
        echo "本次更新未添加新内容。" >> "$GIT_REPO_DIR/更新摘要.md"
    else
        echo "## 更新摘要 - $TODAY" > "$GIT_REPO_DIR/更新摘要.md"
        echo "" >> "$GIT_REPO_DIR/更新摘要.md"
        echo "### 新增/修改的文件:" >> "$GIT_REPO_DIR/更新摘要.md"
        echo "" >> "$GIT_REPO_DIR/更新摘要.md"
        
        for file in $NEW_FILES; do
            # 跳过更新摘要文件本身
            if [ "$file" = "./更新摘要.md" ]; then
                continue
            fi
            echo "- $file" >> "$GIT_REPO_DIR/更新摘要.md"
        done
        
        echo "" >> "$GIT_REPO_DIR/更新摘要.md"
        echo "### 文件统计:" >> "$GIT_REPO_DIR/更新摘要.md"
        echo "" >> "$GIT_REPO_DIR/更新摘要.md"
        echo "- Markdown 文件总数: $(find . -name "*.md" | wc -l)" >> "$GIT_REPO_DIR/更新摘要.md"
        echo "- 目录总数: $(find . -type d | wc -l)" >> "$GIT_REPO_DIR/更新摘要.md"
        echo "- 知识库总大小: $(du -sh . | cut -f1)" >> "$GIT_REPO_DIR/更新摘要.md"
        
        log_success "更新摘要生成完成"
    fi
}

# 执行 Git 操作
perform_git_operations() {
    cd "$GIT_REPO_DIR"
    
    log_info "执行 Git 操作..."
    
    # 添加所有文件
    git add .
    
    # 检查是否有更改
    if git diff --cached --quiet; then
        log_warning "没有需要提交的更改"
        return 1
    fi
    
    # 提交更改
    git commit -m "$COMMIT_MESSAGE"
    
    # 推送到远程仓库（如果配置了远程仓库）
    if git remote | grep -q "origin"; then
        log_info "推送到远程仓库..."
        
        # 尝试推送，如果失败则尝试设置上游分支
        if ! git push -u origin main 2>/dev/null; then
            log_info "设置上游分支..."
            git branch -M main
            git push -u origin main
        fi
        
        log_success "推送完成"
    else
        log_warning "未配置远程仓库，更改仅保存在本地"
    fi
    
    # 更新最后同步时间
    date > "$GIT_REPO_DIR/.last_sync"
    
    return 0
}

# 生成同步报告
generate_sync_report() {
    cd "$GIT_REPO_DIR"
    
    log_info "生成同步报告..."
    
    REPORT_FILE="$GIT_REPO_DIR/同步报告-$(date '+%Y%m%d-%H%M%S').txt"
    
    echo "# 知识库同步报告" > "$REPORT_FILE"
    echo "生成时间: $(date '+%Y年%m月%d日 %H:%M:%S')" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## 同步状态" >> "$REPORT_FILE"
    if git remote | grep -q "origin"; then
        echo "- 远程仓库: 已配置" >> "$REPORT_FILE"
        echo "- 分支: $(git branch --show-current)" >> "$REPORT_FILE"
    else
        echo "- 远程仓库: 未配置" >> "$REPORT_FILE"
        echo "- 分支: $(git branch --show-current)" >> "$REPORT_FILE"
    fi
    echo "" >> "$REPORT_FILE"
    
    echo "## 文件统计" >> "$REPORT_FILE"
    echo "- Markdown 文件: $(find . -name "*.md" | wc -l) 个" >> "$REPORT_FILE"
    echo "- 目录: $(find . -type d | wc -l) 个" >> "$REPORT_FILE"
    echo "- 总大小: $(du -sh . | cut -f1)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    
    echo "## 最近提交" >> "$REPORT_FILE"
    git log --oneline -5 >> "$REPORT_FILE" 2>/dev/null || echo "暂无提交历史" >> "$REPORT_FILE"
    
    log_success "同步报告生成完成: $REPORT_FILE"
}

# 主函数
main() {
    log_info "开始同步存储技术知识库到 GitHub..."
    log_info "知识库目录: $KNOWLEDGE_BASE_DIR"
    log_info "提交信息: $COMMIT_MESSAGE"
    
    # 执行各个步骤
    check_directory
    init_git_repo
    check_remote
    generate_update_summary
    perform_git_operations
    generate_sync_report
    
    log_success "知识库同步流程完成!"
    
    # 显示下一步建议
    echo ""
    log_info "下一步建议:"
    echo "1. 如果需要推送到 GitHub，请先配置远程仓库:"
    echo "   cd $GIT_REPO_DIR"
    echo "   git remote add origin <你的GitHub仓库URL>"
    echo "   git branch -M main"
    echo "   git push -u origin main"
    echo ""
    echo "2. 可以设置定时任务自动执行此脚本:"
    echo "   crontab -e"
    echo "   # 添加以下行（每天凌晨2点执行）"
    echo "   0 2 * * * $GIT_REPO_DIR/scripts/sync-to-github.sh >> $GIT_REPO_DIR/sync.log 2>&1"
}

# 执行主函数
main "$@"