# GitHub配置指南

## 🎯 问题：需要输入用户名和密码

运行 `./scripts/sync-to-github.sh` 时出现：
```
[INFO] 推送到远程仓库...
Username for 'https://github.com': zyu-zju
Password for 'https://zyu-zju@github.com':
```

这是因为GitHub的HTTPS认证方式。

## 🔑 解决方案（三选一）

### 方案A: 使用SSH方式（推荐，一劳永逸）

#### 步骤1: 生成SSH密钥
```bash
# 生成新的SSH密钥（如果还没有）
ssh-keygen -t ed25519 -C "zyu-zju@github.com"
# 提示1: 保存位置，直接按Enter使用默认 (~/.ssh/id_ed25519)
# 提示2: 设置密码，可以直接按Enter不设置
```

#### 步骤2: 添加公钥到GitHub
```bash
# 查看公钥
cat ~/.ssh/id_ed25519.pub
# 复制全部输出内容（以 ssh-ed25519 开头）
```

1. 访问 https://github.com/settings/keys
2. 点击 "New SSH key"
3. Title: `OpenClaw-自动同步`
4. Key type: `Authentication Key`
5. Key: 粘贴刚才复制的公钥
6. 点击 "Add SSH key"

#### 步骤3: 修改仓库URL为SSH格式
```bash
cd ~/.openclaw/workspace/storage-knowledge-base
git remote set-url origin git@github.com:zyu-zju/storage-knowledge-base.git
```

#### 步骤4: 测试SSH连接
```bash
ssh -T git@github.com
# 应该看到: Hi zyu-zju! You've successfully authenticated...
```

#### 步骤5: 测试同步
```bash
./scripts/sync-to-github.sh
# 现在应该不需要输入用户名密码了
```

### 方案B: 使用Personal Access Token（HTTPS）

#### 步骤1: 创建令牌
1. 访问 https://github.com/settings/tokens
2. 点击 "Generate new token (classic)"
3. Note: `OpenClaw-知识库同步`
4. Expiration: `90 days`（或自定义）
5. Select scopes: 勾选 `repo`（完全控制仓库）
6. 点击 "Generate token"
7. **立即复制令牌**（只显示一次！）

#### 步骤2: 配置Git凭证存储
```bash
# 启用Git凭证存储
git config --global credential.helper store

# 修改仓库URL（如果还没设置）
cd ~/.openclaw/workspace/storage-knowledge-base
git remote set-url origin https://github.com/zyu-zju/storage-knowledge-base.git
```

#### 步骤3: 第一次推送（输入令牌）
```bash
cd ~/.openclaw/workspace/storage-knowledge-base
git push -u origin main
# Username: zyu-zju
# Password: <粘贴刚才复制的令牌>  # 注意：不是GitHub密码！
```

#### 步骤4: 验证
```bash
# 之后就不需要再输入了
./scripts/sync-to-github.sh
```

### 方案C: 在脚本中直接使用令牌（高级）

#### 步骤1: 设置环境变量
```bash
# 将令牌添加到环境变量
echo 'export GITHUB_TOKEN="你的令牌内容"' >> ~/.bashrc
source ~/.bashrc

# 验证
echo $GITHUB_TOKEN
```

#### 步骤2: 修改远程URL包含令牌
```bash
cd ~/.openclaw/workspace/storage-knowledge-base
git remote set-url origin https://zyu-zju:$GITHUB_TOKEN@github.com/zyu-zju/storage-knowledge-base.git
```

#### 步骤3: 测试
```bash
./scripts/sync-to-github.sh
```

## 📊 方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|------|------|------|--------|
| **SSH** | 安全、一次配置永久使用、无需令牌 | 需要生成SSH密钥 | ⭐⭐⭐⭐⭐ |
| **HTTPS+令牌** | 简单、无需SSH密钥 | 令牌会过期、需要存储凭证 | ⭐⭐⭐⭐ |
| **环境变量** | 完全自动化 | 令牌暴露在脚本中、安全性较低 | ⭐⭐ |

## 🛠 故障排除

### 问题1: SSH连接测试失败
```bash
# 检查SSH密钥
ls -la ~/.ssh/

# 启动SSH代理
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 再次测试
ssh -T git@github.com
```

### 问题2: 令牌认证失败
```bash
# 清除缓存的凭证
git credential-cache exit
# 或
git config --global --unset credential.helper

# 重新配置
git config --global credential.helper store
```

### 问题3: 权限不足
```bash
# 检查远程仓库URL
git remote -v

# 确认仓库存在且你有权限
# 访问: https://github.com/zyu-zju/storage-knowledge-base
```

### 问题4: 分支名称不匹配
```bash
# 查看当前分支
git branch

# 如果显示master而不是main
git branch -M main
```

## 🔄 完整配置流程（推荐SSH）

### 第一步: 创建GitHub仓库
1. 访问 https://github.com/new
2. Repository name: `storage-knowledge-base`
3. Description: `企业级存储技术知识库 - 自动化收集和同步`
4. 选择 Public 或 Private
5. 不勾选 "Initialize this repository with a README"
6. 点击 "Create repository"

### 第二步: 获取仓库URL
- SSH: `git@github.com:zyu-zju/storage-knowledge-base.git`
- HTTPS: `https://github.com/zyu-zju/storage-knowledge-base.git`

### 第三步: 本地配置（SSH方式）
```bash
# 1. 进入知识库目录
cd ~/.openclaw/workspace/storage-knowledge-base

# 2. 如果已有origin，修改URL
git remote set-url origin git@github.com:zyu-zju/storage-knowledge-base.git

# 3. 如果没有origin，添加
git remote add origin git@github.com:zyu-zju/storage-knowledge-base.git

# 4. 重命名分支为main
git branch -M main

# 5. 首次推送
git push -u origin main
```

### 第四步: 验证配置
```bash
# 测试同步脚本
./scripts/sync-to-github.sh

# 检查Git状态
git remote -v
git branch
git log --oneline -3
```

## 📝 自动化脚本改进

我已经更新了 `sync-to-github.sh` 脚本，现在会：
1. 检测HTTPS URL并给出警告
2. 提供详细的错误信息和解决方案
3. 更好的错误处理

## 🚀 立即行动建议

**推荐使用SSH方式：**
```bash
# 1. 生成SSH密钥（如果还没有）
ssh-keygen -t ed25519 -C "zyu-zju@github.com"

# 2. 添加公钥到GitHub
cat ~/.ssh/id_ed25519.pub
# 复制到 GitHub → Settings → SSH and GPG keys

# 3. 配置仓库
cd ~/.openclaw/workspace/storage-knowledge-base
git remote set-url origin git@github.com:zyu-zju/storage-knowledge-base.git

# 4. 测试
./scripts/sync-to-github.sh
```

## 🔒 安全提醒

1. **SSH私钥** (`~/.ssh/id_ed25519`) 是敏感文件，不要分享
2. **Personal Access Token** 相当于密码，妥善保管
3. 定期更新令牌（建议90天）
4. 不要在公共代码中硬编码令牌

## 📞 获取帮助

如果还有问题：
1. 查看详细错误信息
2. 检查网络连接
3. 验证GitHub账户权限
4. 联系GitHub支持

---

**配置完成后，系统将完全自动化运行：**
- ✅ 每日早晨8点自动收集信息
- ✅ 每日凌晨2点自动同步到GitHub
- ✅ 无需人工干预
- ✅ 完整的版本历史记录

现在就开始配置吧！ 🚀