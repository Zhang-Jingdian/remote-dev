#!/bin/bash

# 远程开发环境部署脚本
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
REMOTE_HOST="${REMOTE_HOST:-192.168.0.105}"
REMOTE_USER="${REMOTE_USER:-zjd}"
REMOTE_PORT="${REMOTE_PORT:-22}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_ed25519}"
DEPLOYMENT_DIR="${DEPLOYMENT_DIR:-/home/zjd/remote-dev-env}"
BACKUP_DIR="${BACKUP_DIR:-/home/zjd/backups}"

# 日志函数
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

# SSH执行函数
ssh_exec() {
    local command="$1"
    ssh -i "$SSH_KEY" -p "$REMOTE_PORT" "$REMOTE_USER@$REMOTE_HOST" "$command"
}

# 文件传输函数
scp_upload() {
    local local_path="$1"
    local remote_path="$2"
    scp -i "$SSH_KEY" -P "$REMOTE_PORT" -r "$local_path" "$REMOTE_USER@$REMOTE_HOST:$remote_path"
}

# 检查远程连接
check_remote_connection() {
    log_info "检查远程连接..."
    
    if ssh_exec "echo 'Connection successful'" &>/dev/null; then
        log_success "✅ 远程连接正常"
        return 0
    else
        log_error "❌ 无法连接到远程主机 $REMOTE_HOST"
        return 1
    fi
}

# 检查远程环境
check_remote_environment() {
    log_info "检查远程环境..."
    
    # 检查必要的命令
    local required_commands=("docker" "docker-compose" "git" "curl" "wget" "jq")
    
    for cmd in "${required_commands[@]}"; do
        if ssh_exec "command -v $cmd" &>/dev/null; then
            log_success "✅ $cmd 已安装"
        else
            log_warning "⚠️  $cmd 未安装，将尝试安装"
            case "$cmd" in
                "docker")
                    ssh_exec "curl -fsSL https://get.docker.com | sh && sudo usermod -aG docker \$USER"
                    ;;
                "docker-compose")
                    ssh_exec "sudo curl -L \"https://github.com/docker/compose/releases/download/1.29.2/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
                    ;;
                "jq")
                    ssh_exec "sudo apt-get update && sudo apt-get install -y jq"
                    ;;
                *)
                    ssh_exec "sudo apt-get update && sudo apt-get install -y $cmd"
                    ;;
            esac
        fi
    done
}

# 创建远程目录结构
create_remote_directories() {
    log_info "创建远程目录结构..."
    
    local directories=(
        "$DEPLOYMENT_DIR"
        "$DEPLOYMENT_DIR/config"
        "$DEPLOYMENT_DIR/logs"
        "$DEPLOYMENT_DIR/data"
        "$BACKUP_DIR"
        "$BACKUP_DIR/configs"
        "$BACKUP_DIR/data"
    )
    
    for dir in "${directories[@]}"; do
        ssh_exec "mkdir -p '$dir'"
        log_success "✅ 创建目录: $dir"
    done
}

# 上传配置文件
upload_config_files() {
    log_info "上传配置文件..."
    
    # 上传整个config目录
    scp_upload "$SCRIPT_DIR" "$DEPLOYMENT_DIR/"
    log_success "✅ 配置文件上传完成"
    
    # 设置执行权限
    ssh_exec "find '$DEPLOYMENT_DIR/config' -name '*.sh' -type f -exec chmod +x {} +"
    log_success "✅ 设置脚本执行权限"
}

# 配置环境变量
configure_environment() {
    log_info "配置环境变量..."
    
    # 创建环境配置文件
    ssh_exec "cat > '$DEPLOYMENT_DIR/.env' << 'EOF'
# 远程开发环境配置
PROJECT_NAME=$PROJECT_NAME
CONFIG_DIR=$DEPLOYMENT_DIR/config
LOG_DIR=$DEPLOYMENT_DIR/logs
DATA_DIR=$DEPLOYMENT_DIR/data
BACKUP_DIR=$BACKUP_DIR

# 网络配置
DOCKER_NETWORK_NAME=${DOCKER_NETWORK_NAME:-dev-network}
DOCKER_SUBNET=${DOCKER_SUBNET:-172.20.0.0/16}

# 安全配置
ENABLE_SSL=${ENABLE_SSL:-true}
SSL_CERT_PATH=${SSL_CERT_PATH:-/etc/ssl/certs}
SSL_KEY_PATH=${SSL_KEY_PATH:-/etc/ssl/private}

# 监控配置
ENABLE_MONITORING=${ENABLE_MONITORING:-true}
MONITORING_PORT=${MONITORING_PORT:-9090}
ALERT_EMAIL=${ALERT_EMAIL:-admin@example.com}

# 备份配置
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
BACKUP_SCHEDULE=${BACKUP_SCHEDULE:-0 2 * * *}
EOF"
    
    log_success "✅ 环境变量配置完成"
}

# 初始化服务
initialize_services() {
    log_info "初始化服务..."
    
    # 运行安全加固
    ssh_exec "cd '$DEPLOYMENT_DIR/config' && ./security/security_hardening.sh --init"
    log_success "✅ 安全加固初始化完成"
    
    # 配置监控
    ssh_exec "cd '$DEPLOYMENT_DIR/config' && ./monitoring/alerting.sh --setup"
    log_success "✅ 监控配置完成"
    
    # 设置备份策略
    ssh_exec "cd '$DEPLOYMENT_DIR/config' && ./backup/backup_strategy.sh --setup"
    log_success "✅ 备份策略设置完成"
    
    # 配置CI/CD集成
    ssh_exec "cd '$DEPLOYMENT_DIR/config' && ./dev/cicd_integration.sh --setup"
    log_success "✅ CI/CD集成配置完成"
}

# 启动服务
start_services() {
    log_info "启动服务..."
    
    # 启动核心服务
    ssh_exec "cd '$DEPLOYMENT_DIR/config' && ./core/lib.sh --start"
    
    # 启动网络服务
    ssh_exec "cd '$DEPLOYMENT_DIR/config' && ./network/connection_pool.sh --start"
    
    # 启动监控服务
    ssh_exec "cd '$DEPLOYMENT_DIR/config' && ./monitoring/alerting.sh --start"
    
    # 启动高级功能
    ssh_exec "cd '$DEPLOYMENT_DIR/config' && ./advanced/advanced_manager.sh --start"
    
    log_success "✅ 所有服务启动完成"
}

# 运行部署后测试
run_deployment_tests() {
    log_info "运行部署后测试..."
    
    # 在远程环境运行测试
    ssh_exec "cd '$DEPLOYMENT_DIR/config' && ./testing/test_runner.sh"
    
    if [ $? -eq 0 ]; then
        log_success "✅ 部署测试通过"
    else
        log_error "❌ 部署测试失败"
        return 1
    fi
}

# 创建系统服务
create_system_services() {
    log_info "创建系统服务..."
    
    # 创建systemd服务文件
    ssh_exec "sudo tee /etc/systemd/system/remote-dev-env.service > /dev/null << 'EOF'
[Unit]
Description=Remote Development Environment
After=network.target docker.service
Requires=docker.service

[Service]
Type=forking
User=$REMOTE_USER
Group=$REMOTE_USER
WorkingDirectory=$DEPLOYMENT_DIR
ExecStart=$DEPLOYMENT_DIR/config/core/lib.sh --start
ExecStop=$DEPLOYMENT_DIR/config/core/lib.sh --stop
ExecReload=$DEPLOYMENT_DIR/config/core/lib.sh --reload
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF"
    
    # 启用服务
    ssh_exec "sudo systemctl daemon-reload && sudo systemctl enable remote-dev-env.service"
    log_success "✅ 系统服务创建完成"
}

# 设置定时任务
setup_cron_jobs() {
    log_info "设置定时任务..."
    
    # 创建crontab条目
    ssh_exec "crontab -l 2>/dev/null | grep -v 'remote-dev-env' > /tmp/crontab.tmp || true"
    ssh_exec "cat >> /tmp/crontab.tmp << 'EOF'
# 远程开发环境定时任务
0 2 * * * $DEPLOYMENT_DIR/config/backup/backup_strategy.sh --run
0 */6 * * * $DEPLOYMENT_DIR/config/security/security_hardening.sh --check
*/15 * * * * $DEPLOYMENT_DIR/config/monitoring/alerting.sh --check
0 3 * * 0 $DEPLOYMENT_DIR/config/advanced/advanced_manager.sh --maintenance
EOF"
    
    ssh_exec "crontab /tmp/crontab.tmp && rm /tmp/crontab.tmp"
    log_success "✅ 定时任务设置完成"
}

# 生成部署报告
generate_deployment_report() {
    log_info "生成部署报告..."
    
    local report_file="$DEPLOYMENT_DIR/deployment_report.md"
    
    ssh_exec "cat > '$report_file' << 'EOF'
# 远程开发环境部署报告

## 部署信息
- 部署时间: $(date)
- 部署主机: $REMOTE_HOST
- 部署用户: $REMOTE_USER
- 部署目录: $DEPLOYMENT_DIR

## 服务状态
- 核心服务: 已启动
- 网络服务: 已启动
- 监控服务: 已启动
- 备份服务: 已配置
- 安全服务: 已加固

## 访问信息
- 主机地址: $REMOTE_HOST
- SSH端口: $REMOTE_PORT
- 配置目录: $DEPLOYMENT_DIR/config
- 日志目录: $DEPLOYMENT_DIR/logs
- 数据目录: $DEPLOYMENT_DIR/data

## 定时任务
- 备份任务: 每日2:00执行
- 安全检查: 每6小时执行
- 监控检查: 每15分钟执行
- 维护任务: 每周日3:00执行

## 下一步操作
1. 验证所有服务正常运行
2. 配置SSL证书（如需要）
3. 设置监控告警
4. 进行性能调优

EOF"
    
    log_success "✅ 部署报告生成完成: $report_file"
}

# 主部署函数
main() {
    log_info "🚀 开始远程开发环境部署"
    echo "========================================"
    
    # 检查本地环境
    if [ ! -f "$SSH_KEY" ]; then
        log_error "SSH密钥文件不存在: $SSH_KEY"
        exit 1
    fi
    
    # 执行部署步骤
    check_remote_connection || exit 1
    check_remote_environment
    create_remote_directories
    upload_config_files
    configure_environment
    initialize_services
    start_services
    run_deployment_tests || log_warning "部署测试失败，但部署继续"
    create_system_services
    setup_cron_jobs
    generate_deployment_report
    
    echo "========================================"
    log_success "🎉 远程开发环境部署完成！"
    log_info "访问地址: ssh -i $SSH_KEY -p $REMOTE_PORT $REMOTE_USER@$REMOTE_HOST"
    log_info "配置目录: $DEPLOYMENT_DIR/config"
    log_info "查看报告: cat $DEPLOYMENT_DIR/deployment_report.md"
}

# 显示帮助信息
show_help() {
    cat << EOF
远程开发环境部署脚本

用法: $0 [选项]

选项:
    -h, --help              显示帮助信息
    -H, --host HOST         远程主机地址 (默认: $REMOTE_HOST)
    -u, --user USER         远程用户名 (默认: $REMOTE_USER)
    -p, --port PORT         SSH端口 (默认: $REMOTE_PORT)
    -k, --key KEY_FILE      SSH密钥文件 (默认: $SSH_KEY)
    -d, --deploy-dir DIR    部署目录 (默认: $DEPLOYMENT_DIR)
    -b, --backup-dir DIR    备份目录 (默认: $BACKUP_DIR)
    --dry-run              仅显示将要执行的操作，不实际执行

示例:
    $0                                          # 使用默认配置部署
    $0 -H 192.168.1.100 -u admin               # 指定主机和用户
    $0 --dry-run                               # 预览部署操作
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -H|--host)
            REMOTE_HOST="$2"
            shift 2
            ;;
        -u|--user)
            REMOTE_USER="$2"
            shift 2
            ;;
        -p|--port)
            REMOTE_PORT="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -d|--deploy-dir)
            DEPLOYMENT_DIR="$2"
            shift 2
            ;;
        -b|--backup-dir)
            BACKUP_DIR="$2"
            shift 2
            ;;
        --dry-run)
            log_info "预览模式 - 将要执行的操作:"
            log_info "1. 检查远程连接到 $REMOTE_HOST:$REMOTE_PORT"
            log_info "2. 检查远程环境和依赖"
            log_info "3. 创建目录结构在 $DEPLOYMENT_DIR"
            log_info "4. 上传配置文件"
            log_info "5. 配置环境变量"
            log_info "6. 初始化和启动服务"
            log_info "7. 运行部署测试"
            log_info "8. 创建系统服务"
            log_info "9. 设置定时任务"
            log_info "10. 生成部署报告"
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