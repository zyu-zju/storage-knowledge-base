# 安装和配置指南

## 🚀 快速开始

### 1. 环境要求
- Linux/macOS 系统
- Python 3.7+
- Git
- 基本的命令行操作知识

### 2. 一键安装脚本
```bash
# 下载安装脚本
curl -O https://raw.githubusercontent.com/yourusername/storage-knowledge-base/main/install.sh
chmod +x install.sh
./install.sh
```

## 📦 手动安装步骤

### 步骤1: 克隆仓库
```bash
# 克隆知识库到本地
git clone https://github.com/yourusername/storage-knowledge-base.git
cd storage-knowledge-base
```

### 步骤2: 安装Python依赖
```bash
# 创建虚拟环境（推荐）
python3 -m venv venv
source venv/bin/activate  # Linux/macOS
# 或 venv\Scripts\activate  # Windows

# 安装依赖
pip install -r requirements.txt
```

### 步骤3: 配置Git
```bash
# 设置Git用户信息
git config --global user.email "your-email@example.com"
git config --global user.name "Your Name"

# 配置远程仓库（如果需要推送到自己的GitHub）
git remote set-url origin https://github.com/yourusername/storage-knowledge-base.git
```

### 步骤4: 测试安装
```bash
# 测试信息收集
python3 scripts/simple-collector.py

# 测试GitHub同步
./scripts/sync-to-github.sh
```

## ⚙️ 配置说明

### 1. 基本信息配置
创建 `config/config.yaml`:
```yaml
user:
  name: "大Z"
  role: "企业级存储技术支持"
  interests:
    - "云存储"
    - "AI存储"
    - "存储性能优化"
    
schedule:
  collection_time: "08:00"
  sync_time: "02:00"
  
output:
  format: "markdown"
  directory: "./output"
```

### 2. 信息源配置
编辑 `config/sources.yaml`:
```yaml
# RSS源列表
rss_feeds:
  - name: "AWS Storage Blog"
    url: "https://aws.amazon.com/blogs/storage/feed/"
    category: "cloud"
    enabled: true
    
  - name: "Azure Storage Blog"
    url: "https://azure.microsoft.com/en-us/blog/topics/storage/"
    category: "cloud"
    enabled: true

# 网页爬虫配置
web_scrapers:
  - name: "StorageReview"
    url: "https://www.storagereview.com/"
    selectors:
      articles: "article"
      title: "h2 a"
    enabled: true
```

### 3. GitHub配置
编辑 `config/github.yaml`:
```yaml
repository: "https://github.com/yourusername/storage-knowledge-base"
branch: "main"
access_token: "${GITHUB_TOKEN}"  # 从环境变量读取
auto_push: true
commit_template: "自动更新: {date}"
```

## 🔧 高级配置

### 1. 使用环境变量
```bash
# 设置GitHub访问令牌
export GITHUB_TOKEN="your_github_token_here"

# 设置代理（如果需要）
export HTTP_PROXY="http://proxy.example.com:8080"
export HTTPS_PROXY="http://proxy.example.com:8080"
```

### 2. 配置定时任务
```bash
# 编辑crontab
crontab -e

# 添加以下内容:
# 每天早晨8点收集信息
0 8 * * * cd /path/to/storage-knowledge-base && python3 scripts/simple-collector.py >> logs/collection.log 2>&1

# 每天凌晨2点同步到GitHub
0 2 * * * cd /path/to/storage-knowledge-base && ./scripts/sync-to-github.sh >> logs/sync.log 2>&1

# 每周日清理旧日志
0 0 * * 0 find /path/to/storage-knowledge-base/logs -name "*.log" -mtime +7 -delete
```

### 3. 配置日志
创建 `config/logging.yaml`:
```yaml
version: 1
formatters:
  simple:
    format: '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    
handlers:
  file:
    class: logging.FileHandler
    filename: logs/application.log
    formatter: simple
    
  console:
    class: logging.StreamHandler
    formatter: simple
    
loggers:
  collector:
    level: INFO
    handlers: [file, console]
    
  syncer:
    level: INFO
    handlers: [file]
```

## 🐳 Docker部署

### 使用Docker Compose
```yaml
# docker-compose.yml
version: '3.8'
services:
  knowledge-base:
    build: .
    volumes:
      - ./data:/app/data
      - ./config:/app/config
      - ./logs:/app/logs
    environment:
      - GITHUB_TOKEN=${GITHUB_TOKEN}
    restart: unless-stopped
```

### 构建Docker镜像
```bash
# 构建镜像
docker build -t storage-knowledge-base .

# 运行容器
docker run -d \
  --name storage-kb \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/config:/app/config \
  -e GITHUB_TOKEN="your_token" \
  storage-knowledge-base
```

## 🔐 安全配置

### 1. GitHub令牌管理
```bash
# 创建GitHub Personal Access Token
# 访问: https://github.com/settings/tokens
# 权限: repo (完全控制仓库)

# 安全存储令牌
echo "export GITHUB_TOKEN=your_token_here" >> ~/.bashrc
source ~/.bashrc
```

### 2. 文件权限设置
```bash
# 设置适当的文件权限
chmod 600 config/*.yaml
chmod 700 scripts/*.sh
chmod 755 scripts/*.py
```

### 3. 备份配置
```bash
# 备份重要配置文件
tar -czf config-backup-$(date +%Y%m%d).tar.gz config/
```

## 🚨 故障排除

### 常见问题

#### 1. Python依赖安装失败
```bash
# 升级pip
python3 -m pip install --upgrade pip

# 使用国内镜像源
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

#### 2. Git推送失败
```bash
# 检查远程仓库配置
git remote -v

# 更新远程仓库URL
git remote set-url origin https://github.com/yourusername/storage-knowledge-base.git

# 强制推送（谨慎使用）
git push -f origin main
```

#### 3. 定时任务不执行
```bash
# 检查cron服务状态
systemctl status cron

# 查看cron日志
grep CRON /var/log/syslog

# 测试脚本手动执行
cd /path/to/storage-knowledge-base && ./scripts/sync-to-github.sh
```

#### 4. 网络连接问题
```bash
# 测试网络连接
curl -I https://github.com

# 设置代理
export http_proxy=http://proxy.example.com:8080
export https_proxy=http://proxy.example.com:8080
```

## 📈 性能优化

### 1. 数据库缓存
```bash
# 安装SQLite用于缓存
sudo apt-get install sqlite3  # Ubuntu/Debian

# 初始化缓存数据库
python3 scripts/init_cache.py
```

### 2. 并发收集
```yaml
# config/performance.yaml
concurrent:
  max_workers: 5
  timeout: 30
  retry_attempts: 3
```

### 3. 内存优化
```yaml
# config/memory.yaml
limits:
  max_articles_per_day: 100
  cache_size_mb: 100
  log_rotation_days: 7
```

## 🔄 更新和维护

### 1. 更新知识库
```bash
# 拉取最新代码
git pull origin main

# 更新依赖
pip install -r requirements.txt --upgrade

# 重启服务
./scripts/restart.sh
```

### 2. 数据清理
```bash
# 清理旧日志
./scripts/cleanup_logs.sh

# 优化数据库
./scripts/optimize_db.sh

# 备份数据
./scripts/backup_data.sh
```

### 3. 监控状态
```bash
# 查看运行状态
./scripts/check_status.sh

# 查看日志
tail -f logs/application.log

# 查看统计信息
./scripts/show_stats.sh
```

## 🆘 获取帮助

### 1. 查看文档
```bash
# 查看完整文档
cat docs/*.md

# 查看命令行帮助
./scripts/sync-to-github.sh --help
python3 scripts/simple-collector.py --help
```

### 2. 报告问题
```bash
# 收集调试信息
./scripts/debug_info.sh

# 查看错误日志
cat logs/error.log
```

### 3. 社区支持
- GitHub Issues: https://github.com/yourusername/storage-knowledge-base/issues
- 文档网站: https://yourusername.github.io/storage-knowledge-base/
- 邮件支持: support@example.com

---

## 🎉 安装完成！

恭喜！你已经成功安装和配置了存储技术知识库自动化系统。

### 下一步:
1. **测试系统:** 运行 `./scripts/test_all.sh`
2. **配置自动化:** 设置定时任务
3. **开始使用:** 查看生成的第一份日报
4. **自定义:** 根据需求调整配置

### 验证安装:
```bash
# 运行完整测试
./scripts/verify_installation.sh

# 检查所有组件
./scripts/check_components.sh
```

如有问题，请参考故障排除部分或提交Issue。

---

**版本:** v1.0.0  
**最后更新:** 2026-03-21  
**维护者:** 小Z (个人助手)