#!/bin/bash

# 文档管理器 - 自动生成和维护项目文档
# 作者: 远程开发环境项目
# 版本: 1.0.0

set -euo pipefail

# 获取脚本路径
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"
source "$SCRIPT_DIR/constants.sh"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
DOCS_DIR="${DOCS_DIR:-$PROJECT_ROOT/docs}"
DOCS_LOG="$LOG_DIR/documentation.log"
API_DOCS_DIR="$DOCS_DIR/api"
USER_DOCS_DIR="$DOCS_DIR/user"
DEV_DOCS_DIR="$DOCS_DIR/development"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$DOCS_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$DOCS_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$DOCS_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$DOCS_LOG"
}

# 初始化文档目录
init_docs_directories() {
    log_info "初始化文档目录结构..."
    
    local dirs=(
        "$DOCS_DIR"
        "$API_DOCS_DIR"
        "$USER_DOCS_DIR"
        "$DEV_DOCS_DIR"
        "$DOCS_DIR/images"
        "$DOCS_DIR/templates"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        log_success "✅ 创建目录: $dir"
    done
}

# 生成项目概览文档
generate_project_overview() {
    log_info "生成项目概览文档..."
    
    local overview_file="$DOCS_DIR/README.md"
    
    cat > "$overview_file" << 'EOF'
# 远程开发环境项目

## 🚀 项目简介

这是一个完整的远程开发环境解决方案，提供了从基础设施搭建到高级功能的全套工具和脚本。

## 📁 项目结构

```
config/
├── core/              # 核心功能模块
├── security/          # 安全模块
├── monitoring/        # 监控模块
├── backup/           # 备份模块
├── dev/              # 开发工具模块
├── advanced/         # 高级功能模块
├── docs/             # 文档模块
├── network/          # 网络模块
├── cluster/          # 集群模块
├── plugins/          # 插件模块
├── dynamic/          # 动态配置模块
├── docker/           # Docker配置
├── vscode/           # VSCode配置
├── devcontainer/     # 开发容器配置
├── setup/            # 安装脚本
├── testing/          # 测试脚本
├── deployment/       # 部署脚本
└── optimization/     # 优化脚本
```

## 🔧 核心功能

- **安全加固**: 密钥管理、权限控制、安全扫描
- **监控告警**: 系统监控、性能指标、告警通知
- **自动备份**: 定期备份、数据恢复、版本控制
- **CI/CD集成**: 代码质量检查、自动化测试、部署流程
- **网络管理**: 连接池、负载均衡、故障转移
- **集群管理**: 多节点部署、资源调度、高可用
- **插件系统**: 扩展功能、第三方集成、自定义插件
- **动态配置**: 热更新、配置中心、环境隔离

## 🚀 快速开始

### 1. 测试验证
```bash
# 运行全面测试
./config/testing/test_runner.sh

# 检查特定模块
./config/testing/test_runner.sh --module security
```

### 2. 本地部署
```bash
# 预览部署操作
./config/deployment/deploy.sh --dry-run

# 执行部署
./config/deployment/deploy.sh
```

### 3. 持续优化
```bash
# 运行性能优化
./config/optimization/continuous_optimizer.sh

# 仅收集指标
./config/optimization/continuous_optimizer.sh --metrics-only
```

## 📚 详细文档

- [用户手册](./user/README.md)
- [开发指南](./development/README.md)
- [API文档](./api/README.md)
- [部署指南](./deployment/README.md)
- [故障排除](./troubleshooting/README.md)

## 🛠️ 系统要求

- **操作系统**: Ubuntu 18.04+, CentOS 7+, macOS 10.15+
- **内存**: 最低4GB，推荐8GB+
- **磁盘**: 最低20GB可用空间
- **网络**: 稳定的互联网连接
- **Docker**: 版本20.10+
- **Docker Compose**: 版本1.29+

## 📞 支持与贡献

如有问题或建议，请提交Issue或Pull Request。

## 📄 许可证

本项目采用MIT许可证，详情请参阅LICENSE文件。
EOF
    
    log_success "✅ 项目概览文档生成完成: $overview_file"
}

# 生成API文档
generate_api_docs() {
    log_info "生成API文档..."
    
    local api_readme="$API_DOCS_DIR/README.md"
    
    cat > "$api_readme" << 'EOF'
# API 文档

## 核心API

### 安全模块API

#### security_hardening.sh
- `--init`: 初始化安全配置
- `--check`: 执行安全检查
- `--rotate-keys`: 轮换密钥
- `--scan`: 执行安全扫描

### 监控模块API

#### alerting.sh
- `--setup`: 初始化监控配置
- `--start`: 启动监控服务
- `--stop`: 停止监控服务
- `--check`: 检查监控状态

### 备份模块API

#### backup_strategy.sh
- `--setup`: 初始化备份配置
- `--run`: 执行备份操作
- `--restore <backup_id>`: 恢复指定备份
- `--list`: 列出所有备份

### 开发模块API

#### cicd_integration.sh
- `--setup`: 初始化CI/CD配置
- `--test`: 运行测试
- `--build`: 构建项目
- `--deploy`: 部署项目

## 使用示例

```bash
# 安全检查
./config/security/security_hardening.sh --check

# 启动监控
./config/monitoring/alerting.sh --start

# 执行备份
./config/backup/backup_strategy.sh --run

# 运行测试
./config/dev/cicd_integration.sh --test
```
EOF
    
    log_success "✅ API文档生成完成: $api_readme"
}

# 生成用户手册
generate_user_manual() {
    log_info "生成用户手册..."
    
    local user_readme="$USER_DOCS_DIR/README.md"
    
    cat > "$user_readme" << 'EOF'
# 用户手册

## 🎯 目标用户

本项目适用于以下用户：
- 软件开发者
- 系统管理员
- DevOps工程师
- 技术团队负责人

## 📖 使用指南

### 基础操作

#### 1. 环境准备
确保系统满足最低要求，并安装必要的依赖。

#### 2. 初始化配置
```bash
# 设置基础配置
./config/setup/init.sh

# 验证配置
./config/testing/test_runner.sh
```

#### 3. 启动服务
```bash
# 启动所有服务
./config/core/lib.sh --start-all

# 启动特定服务
./config/monitoring/alerting.sh --start
```

### 高级操作

#### 安全管理
```bash
# 执行安全加固
./config/security/security_hardening.sh --init

# 定期安全检查
./config/security/security_hardening.sh --check
```

#### 性能优化
```bash
# 系统优化
./config/optimization/continuous_optimizer.sh

# 强制优化
./config/optimization/continuous_optimizer.sh --force
```

### 故障排除

#### 常见问题

1. **连接失败**
   - 检查网络配置
   - 验证SSH密钥
   - 确认防火墙设置

2. **服务启动失败**
   - 检查端口占用
   - 验证配置文件
   - 查看日志文件

3. **性能问题**
   - 运行性能分析
   - 检查资源使用
   - 优化配置参数

## 📊 监控面板

系统提供了丰富的监控指标：
- CPU使用率
- 内存使用率
- 磁盘使用率
- 网络流量
- 服务状态

## 🔐 安全最佳实践

1. 定期更新密钥
2. 启用双因素认证
3. 限制网络访问
4. 定期安全扫描
5. 备份重要数据
EOF
    
    log_success "✅ 用户手册生成完成: $user_readme"
}

# 生成开发指南
generate_dev_guide() {
    log_info "生成开发指南..."
    
    local dev_readme="$DEV_DOCS_DIR/README.md"
    
    cat > "$dev_readme" << 'EOF'
# 开发指南

## 🏗️ 架构设计

### 模块化架构
项目采用模块化设计，每个模块负责特定功能：

```
核心层 (core/)
├── 基础库 (lib.sh)
├── 配置管理 (constants.sh)
└── 工具函数

功能层
├── 安全模块 (security/)
├── 监控模块 (monitoring/)
├── 备份模块 (backup/)
├── 开发模块 (dev/)
└── 高级功能 (advanced/)

服务层
├── 网络服务 (network/)
├── 集群服务 (cluster/)
└── 插件服务 (plugins/)
```

### 设计原则
1. **单一职责**: 每个模块专注一个功能
2. **低耦合**: 模块间依赖最小化
3. **高内聚**: 模块内功能紧密相关
4. **可扩展**: 支持插件和扩展
5. **可维护**: 代码清晰，文档完整

## 🔧 开发环境搭建

### 1. 克隆项目
```bash
git clone <repository-url>
cd remote-dev-env
```

### 2. 安装依赖
```bash
# macOS
brew install jq bc

# Ubuntu/Debian
sudo apt-get install jq bc

# CentOS/RHEL
sudo yum install jq bc
```

### 3. 配置开发环境
```bash
# 设置环境变量
cp .env.example .env
vim .env

# 初始化配置
./config/setup/init.sh --dev
```

## 📝 代码规范

### Shell脚本规范
1. 使用`#!/bin/bash`作为shebang
2. 启用严格模式：`set -euo pipefail`
3. 使用标准的函数命名：`function_name()`
4. 添加详细的注释和文档
5. 使用一致的缩进（4个空格）

### 变量命名规范
- 全局常量：`UPPER_CASE`
- 局部变量：`lower_case`
- 环境变量：`PROJECT_PREFIX_VARIABLE`

### 错误处理
```bash
# 检查命令执行结果
if command; then
    log_success "操作成功"
else
    log_error "操作失败"
    return 1
fi
```

## 🧪 测试指南

### 单元测试
```bash
# 运行所有测试
./config/testing/test_runner.sh

# 测试特定模块
./config/testing/test_runner.sh --module security
```

### 集成测试
```bash
# 部署测试环境
./config/deployment/deploy.sh --test-env

# 运行集成测试
./config/testing/integration_test.sh
```

## 🚀 新功能开发

### 1. 创建新模块
```bash
# 使用模板创建新模块
./config/tools/create_module.sh new_feature

# 手动创建目录结构
mkdir -p config/new_feature
touch config/new_feature/manager.sh
```

### 2. 实现功能
按照现有模块的结构实现功能：
- main函数作为入口
- 完整的错误处理
- 详细的日志记录
- 命令行参数解析

### 3. 添加测试
```bash
# 在test_runner.sh中添加测试
check_file_exists "$SCRIPT_DIR/new_feature/manager.sh" "新功能脚本存在"
check_script_syntax "$SCRIPT_DIR/new_feature/manager.sh" "新功能脚本语法检查"
```

## 📊 性能优化

### 1. 脚本性能
- 减少外部命令调用
- 使用内置命令替代外部工具
- 优化循环和条件判断

### 2. 资源使用
- 控制并发数量
- 及时清理临时文件
- 优化内存使用

## 🔍 调试技巧

### 1. 启用调试模式
```bash
# 详细输出
bash -x script.sh

# 自定义调试
export DEBUG=1
./script.sh
```

### 2. 日志分析
```bash
# 查看实时日志
tail -f logs/application.log

# 过滤错误日志
grep "ERROR" logs/*.log
```

## 🤝 贡献指南

1. Fork项目
2. 创建功能分支
3. 提交代码
4. 创建Pull Request
5. 代码审查
6. 合并主分支
EOF
    
    log_success "✅ 开发指南生成完成: $dev_readme"
}

# 扫描并生成模块文档
scan_and_generate_module_docs() {
    log_info "扫描并生成模块文档..."
    
    local modules_dir="$SCRIPT_DIR"
    local module_docs_dir="$DOCS_DIR/modules"
    mkdir -p "$module_docs_dir"
    
    # 扫描所有模块目录
    for module_dir in "$modules_dir"/*/; do
        if [ -d "$module_dir" ]; then
            local module_name=$(basename "$module_dir")
            
            # 跳过特殊目录
            if [[ "$module_name" == "docs" || "$module_name" == "testing" ]]; then
                continue
            fi
            
            local module_doc="$module_docs_dir/${module_name}.md"
            
            cat > "$module_doc" << EOF
# ${module_name^} 模块

## 概述
${module_name} 模块的功能描述。

## 文件列表
$(find "$module_dir" -name "*.sh" -type f | while read -r file; do
    echo "- \`$(basename "$file")\`: $(head -n 3 "$file" | grep "^#" | tail -n 1 | sed 's/^# *//')"
done)

## 使用方法
\`\`\`bash
# 基本用法
./config/${module_name}/main_script.sh [options]

# 帮助信息
./config/${module_name}/main_script.sh --help
\`\`\`

## 配置选项
模块特定的配置选项。

## 示例
使用示例和最佳实践。

## 故障排除
常见问题和解决方案。
EOF
            
            log_success "✅ 生成模块文档: $module_doc"
        fi
    done
}

# 生成变更日志
generate_changelog() {
    log_info "生成变更日志..."
    
    local changelog_file="$DOCS_DIR/CHANGELOG.md"
    
    cat > "$changelog_file" << 'EOF'
# 变更日志

## [1.0.0] - 2024-01-01

### 新增功能
- ✅ 核心功能模块
- ✅ 安全加固系统
- ✅ 监控告警系统
- ✅ 自动备份系统
- ✅ CI/CD集成
- ✅ 高级功能模块
- ✅ 文档管理系统
- ✅ 测试验证框架
- ✅ 部署自动化
- ✅ 持续优化系统

### 改进优化
- 🔧 统一了脚本路径解析
- 🔧 标准化了错误处理
- 🔧 优化了日志输出格式
- 🔧 改进了配置管理

### 修复问题
- 🐛 修复了路径引用问题
- 🐛 解决了权限设置问题
- 🐛 修复了变量未定义错误

### 文档更新
- 📚 完善了用户手册
- 📚 添加了开发指南
- 📚 生成了API文档
- 📚 创建了故障排除指南

## [未来计划]

### v1.1.0
- 🚀 Web管理界面
- 🚀 更多监控指标
- 🚀 插件市场
- 🚀 多语言支持

### v1.2.0
- 🚀 微服务支持
- 🚀 容器编排优化
- 🚀 AI驱动的优化建议
- 🚀 云平台集成
EOF
    
    log_success "✅ 变更日志生成完成: $changelog_file"
}

# 验证文档完整性
validate_documentation() {
    log_info "验证文档完整性..."
    
    local required_docs=(
        "$DOCS_DIR/README.md"
        "$API_DOCS_DIR/README.md"
        "$USER_DOCS_DIR/README.md"
        "$DEV_DOCS_DIR/README.md"
        "$DOCS_DIR/CHANGELOG.md"
    )
    
    local missing_docs=()
    
    for doc in "${required_docs[@]}"; do
        if [ ! -f "$doc" ]; then
            missing_docs+=("$doc")
            log_error "缺少文档: $doc"
        else
            log_success "✅ 文档存在: $doc"
        fi
    done
    
    if [ ${#missing_docs[@]} -eq 0 ]; then
        log_success "✅ 所有必需文档都已存在"
        return 0
    else
        log_error "❌ 缺少 ${#missing_docs[@]} 个文档"
        return 1
    fi
}

# 主函数
main() {
    log_info "🚀 开始文档管理"
    echo "========================================"
    
    # 初始化目录
    init_docs_directories
    
    # 生成各种文档
    generate_project_overview
    generate_api_docs
    generate_user_manual
    generate_dev_guide
    scan_and_generate_module_docs
    generate_changelog
    
    # 验证文档完整性
    if validate_documentation; then
        echo "========================================"
        log_success "🎉 文档管理完成！"
        log_info "文档目录: $DOCS_DIR"
        log_info "查看项目概览: $DOCS_DIR/README.md"
    else
        log_error "❌ 文档生成不完整"
        return 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
文档管理器

用法: $0 [选项]

选项:
    -h, --help              显示帮助信息
    --init-only             仅初始化目录结构
    --generate-overview     仅生成项目概览
    --generate-api          仅生成API文档
    --generate-user         仅生成用户手册
    --generate-dev          仅生成开发指南
    --scan-modules          仅扫描并生成模块文档
    --validate              仅验证文档完整性

示例:
    $0                      # 生成所有文档
    $0 --generate-api       # 仅生成API文档
    $0 --validate           # 验证文档完整性
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --init-only)
            init_docs_directories
            exit 0
            ;;
        --generate-overview)
            generate_project_overview
            exit 0
            ;;
        --generate-api)
            generate_api_docs
            exit 0
            ;;
        --generate-user)
            generate_user_manual
            exit 0
            ;;
        --generate-dev)
            generate_dev_guide
            exit 0
            ;;
        --scan-modules)
            scan_and_generate_module_docs
            exit 0
            ;;
        --validate)
            validate_documentation
            exit 0
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行主函数
main "$@" 