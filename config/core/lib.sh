#!/bin/bash

# =============================================================================
# 核心库文件 - 通用函数和工具集
# 作者: Zhang-Jingdian
# 邮箱: 2157429750@qq.com
# 创建时间: 2025年7月14日
# 描述: 提供项目中所有模块共用的基础函数和工具
# =============================================================================

# 获取脚本目录
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"

# 加载常量
source "$SCRIPT_DIR/constants.sh"

# =============================================================================
# 核心库函数 - 通用功能和配置管理
# =============================================================================

# 颜色定义
if [ -z "$RED" ]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly NC='\033[0m' # No Color
fi

# 日志函数
log_info() {
    echo -e "${GREEN}✓${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}!${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_debug() {
    echo -e "${BLUE}→${NC} $1"
}

log_step() {
    echo -e "${CYAN}▶${NC} $1"
}

log_header() {
    echo -e "\n${PURPLE}═══ $1 ═══${NC}"
}

# 获取脚本目录
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd
}

# 获取项目根目录
get_project_root() {
    local script_dir=$(get_script_dir)
    cd "$script_dir/../.." &>/dev/null && pwd
}

# 加载配置文件
load_config() {
    local config_file="$SCRIPT_DIR/core/config.env"
    
    if [ -f "$config_file" ]; then
        source "$config_file"
        return $EXIT_SUCCESS
    else
        log_error "配置文件不存在: $config_file"
        return $EXIT_CONFIG_ERROR
    fi
}

# 命令存在性检查
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 检查必需的命令
check_required_commands() {
    local missing_commands=()
    
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -ne 0 ]; then
        log_error "缺少必需的命令: ${missing_commands[*]}"
        return $EXIT_FAILURE
    fi
    
    return $EXIT_SUCCESS
}

# SSH连接检查
check_ssh_connection() {
    if [ -z "$SSH_ALIAS" ]; then
        log_error "SSH_ALIAS 未设置"
        return $EXIT_CONFIG_ERROR
    fi
    
    if ssh -o ConnectTimeout=$SSH_TIMEOUT -o BatchMode=yes "$SSH_ALIAS" exit 2>/dev/null; then
        return $EXIT_SUCCESS
    else
        return $EXIT_NETWORK_ERROR
    fi
}

# Docker检查
check_docker() {
    if ! command_exists docker; then
        log_error "Docker 未安装"
        return $EXIT_FAILURE
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker 未运行"
        return $EXIT_DOCKER_ERROR
    fi
    
    return $EXIT_SUCCESS
}

# 远程Docker检查
check_remote_docker() {
    if ! check_ssh_connection; then
        return $EXIT_NETWORK_ERROR
    fi
    
    if ssh -o ConnectTimeout=$SSH_TIMEOUT "$SSH_ALIAS" "docker info" >/dev/null 2>&1; then
        return $EXIT_SUCCESS
    else
        return $EXIT_DOCKER_ERROR
    fi
}

# 确保远程目录存在
ensure_remote_dir() {
    local ssh_alias="$1"
    local remote_dir="$2"
    
    if [ -z "$ssh_alias" ] || [ -z "$remote_dir" ]; then
        log_error "SSH别名或远程目录未指定"
        return $EXIT_FAILURE
    fi
    
    log_debug "确保远程目录存在: $ssh_alias:$remote_dir"
    
    if ssh "$ssh_alias" "mkdir -p '$remote_dir'"; then
        log_debug "远程目录已准备: $remote_dir"
        return $EXIT_SUCCESS
    else
        log_error "无法创建远程目录: $remote_dir"
        return $EXIT_FAILURE
    fi
}

# 等待服务就绪
wait_for_service() {
    local check_command="$1"
    local timeout="${2:-$DOCKER_TIMEOUT}"
    local interval=2
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if eval "$check_command" >/dev/null 2>&1; then
            return $EXIT_SUCCESS
        fi
        
        sleep $interval
        elapsed=$((elapsed + interval))
    done
    
    return $EXIT_FAILURE
}

# 获取环境变量或使用默认值
get_env_or_default() {
    local env_name="$1"
    local default_value="$2"
    
    if [ -n "${!env_name}" ]; then
        echo "${!env_name}"
    else
        echo "$default_value"
    fi
}

# 验证配置
validate_config() {
    local errors=0
    
    if [ -z "$SSH_ALIAS" ]; then
        log_error "SSH_ALIAS 未设置"
        ((errors++))
    fi
    
    if [ -z "$REMOTE_PROJECT_PATH" ]; then
        log_error "REMOTE_PROJECT_PATH 未设置"
        ((errors++))
    fi
    
    if [ $errors -gt 0 ]; then
        log_error "配置验证失败，发现 $errors 个错误"
        return $EXIT_CONFIG_ERROR
    fi
    
    return $EXIT_SUCCESS
}

# 检查代理连接
check_proxy() {
    local proxy_url="$1"
    
    if [ -z "$proxy_url" ]; then
        return $EXIT_FAILURE
    fi
    
    if curl -s --proxy "$proxy_url" --max-time 5 http://www.google.com >/dev/null 2>&1; then
        return $EXIT_SUCCESS
    else
        return $EXIT_FAILURE
    fi
}

# 文件同步排除模式
get_rsync_excludes() {
    local exclude_args=""
    
    for pattern in "${RSYNC_EXCLUDE_PATTERNS[@]}"; do
        exclude_args="$exclude_args --exclude=$pattern"
    done
    
    echo "$exclude_args"
}

# 清理函数
cleanup() {
    log_debug "执行清理操作"
    
    # 清理PID文件
    if [ -f "$SSH_TUNNEL_PID_FILE" ]; then
        local pid=$(cat "$SSH_TUNNEL_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_debug "已停止隧道进程: $pid"
        fi
        rm -f "$SSH_TUNNEL_PID_FILE"
    fi
}

# 设置信号处理
setup_signal_handlers() {
    trap cleanup EXIT
    trap 'cleanup; exit 130' INT
    trap 'cleanup; exit 143' TERM
}

# 初始化
init() {
    setup_signal_handlers
    
    if ! check_required_commands; then
        return $EXIT_FAILURE
    fi
    
    if ! validate_config; then
        return $EXIT_CONFIG_ERROR
    fi
    
    return $EXIT_SUCCESS
} 