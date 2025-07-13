#!/bin/bash

# =============================================================================
# SSH连接池管理系统 - 高性能连接复用
# =============================================================================

# 获取脚本目录
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"

source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"

# 连接池配置
SSH_POOL_DIR="/tmp/ssh-pool"
SSH_MASTER_TIMEOUT="600"  # 10分钟超时
SSH_MAX_CONNECTIONS="5"   # 最大连接数

# 初始化连接池
init_connection_pool() {
    log_header "初始化SSH连接池"
    
    # 创建连接池目录
    mkdir -p "$SSH_POOL_DIR"
    
    # 设置SSH连接复用配置
    if [[ ! -f ~/.ssh/config ]] || ! grep -q "ControlMaster" ~/.ssh/config; then
        log_info "配置SSH连接复用..."
        
        cat >> ~/.ssh/config << EOF

# SSH连接池配置
Host *
    ControlMaster auto
    ControlPath $SSH_POOL_DIR/%r@%h:%p
    ControlPersist $SSH_MASTER_TIMEOUT
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    Compression yes
EOF
        
        log_success "SSH连接复用配置完成"
    fi
}

# 获取连接池状态
get_pool_status() {
    log_header "SSH连接池状态"
    
    if [[ ! -d "$SSH_POOL_DIR" ]]; then
        log_warning "连接池未初始化"
        return 1
    fi
    
    local active_connections=0
    local connection_info=""
    
    for socket in "$SSH_POOL_DIR"/*; do
        if [[ -S "$socket" ]]; then
            local socket_name=$(basename "$socket")
            local connection_time=$(stat -c %Y "$socket" 2>/dev/null || stat -f %m "$socket" 2>/dev/null)
            local current_time=$(date +%s)
            local duration=$((current_time - connection_time))
            
            connection_info+="\n  → $socket_name (运行时间: ${duration}s)"
            ((active_connections++))
        fi
    done
    
    log_info "活跃连接: $active_connections/$SSH_MAX_CONNECTIONS"
    
    if [[ $active_connections -gt 0 ]]; then
        log_info "连接详情:$connection_info"
    fi
}

# 创建新的SSH连接
create_connection() {
    local host="$1"
    local user="$2"
    local port="${3:-22}"
    
    log_info "创建SSH连接: $user@$host:$port"
    
    # 检查连接数限制
    local current_connections=$(ls -1 "$SSH_POOL_DIR" 2>/dev/null | wc -l)
    if [[ $current_connections -ge $SSH_MAX_CONNECTIONS ]]; then
        log_warning "连接池已满，清理旧连接..."
        cleanup_old_connections
    fi
    
    # 建立主连接
    ssh -fN -o ControlMaster=yes -o ControlPath="$SSH_POOL_DIR/$user@$host:$port" \
        -p "$port" "$user@$host" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        log_success "SSH连接创建成功"
        return 0
    else
        log_error "SSH连接创建失败"
        return 1
    fi
}

# 测试连接
test_connection() {
    local ssh_alias="$1"
    
    if [[ -z "$ssh_alias" ]]; then
        log_error "请提供SSH别名"
        return 1
    fi
    
    log_info "测试SSH连接: $ssh_alias"
    
    # 使用连接池测试
    if ssh -o BatchMode=yes -o ConnectTimeout=5 "$ssh_alias" exit 2>/dev/null; then
        log_success "SSH连接正常"
        return 0
    else
        log_error "SSH连接失败"
        return 1
    fi
}

# 获取连接信息
get_connection_info() {
    local ssh_alias="$1"
    
    # 解析SSH配置获取连接信息
    local host=$(ssh -G "$ssh_alias" | grep "^hostname " | cut -d' ' -f2)
    local user=$(ssh -G "$ssh_alias" | grep "^user " | cut -d' ' -f2)
    local port=$(ssh -G "$ssh_alias" | grep "^port " | cut -d' ' -f2)
    
    echo "host=$host user=$user port=$port"
}

# 清理旧连接
cleanup_old_connections() {
    log_info "清理旧的SSH连接..."
    
    local cleaned=0
    for socket in "$SSH_POOL_DIR"/*; do
        if [[ -S "$socket" ]]; then
            local socket_name=$(basename "$socket")
            local connection_time=$(stat -c %Y "$socket" 2>/dev/null || stat -f %m "$socket" 2>/dev/null)
            local current_time=$(date +%s)
            local duration=$((current_time - connection_time))
            
            # 清理超过5分钟的连接
            if [[ $duration -gt 300 ]]; then
                ssh -O exit -o ControlPath="$socket" dummy 2>/dev/null
                rm -f "$socket"
                log_info "清理连接: $socket_name"
                ((cleaned++))
            fi
        fi
    done
    
    log_info "清理了 $cleaned 个旧连接"
}

# 关闭所有连接
close_all_connections() {
    log_header "关闭所有SSH连接"
    
    local closed=0
    for socket in "$SSH_POOL_DIR"/*; do
        if [[ -S "$socket" ]]; then
            local socket_name=$(basename "$socket")
            ssh -O exit -o ControlPath="$socket" dummy 2>/dev/null
            rm -f "$socket"
            log_info "关闭连接: $socket_name"
            ((closed++))
        fi
    done
    
    log_success "关闭了 $closed 个连接"
}

# 优化SSH连接
optimize_ssh_connection() {
    local ssh_alias="$1"
    
    log_header "优化SSH连接: $ssh_alias"
    
    # 获取连接信息
    local conn_info=$(get_connection_info "$ssh_alias")
    eval "$conn_info"
    
    # 预热连接
    log_info "预热SSH连接..."
    ssh -o ControlMaster=yes -o ControlPersist=600 -fN "$ssh_alias" 2>/dev/null
    
    # 测试连接性能
    log_info "测试连接性能..."
    local start_time=$(date +%s%N)
    ssh "$ssh_alias" "echo 'connection test'" >/dev/null 2>&1
    local end_time=$(date +%s%N)
    local latency=$(( (end_time - start_time) / 1000000 ))
    
    log_info "连接延迟: ${latency}ms"
    
    # 性能建议
    if [[ $latency -gt 100 ]]; then
        log_warning "连接延迟较高，建议检查网络状况"
    elif [[ $latency -gt 50 ]]; then
        log_info "连接延迟正常"
    else
        log_success "连接延迟优秀"
    fi
}

# 监控连接池
monitor_pool() {
    log_header "SSH连接池监控"
    
    while true; do
        clear
        echo "=== SSH连接池实时监控 ==="
        echo "时间: $(date)"
        echo ""
        
        get_pool_status
        
        echo ""
        echo "按 Ctrl+C 退出监控"
        sleep 5
    done
}

# 导出函数
export -f init_connection_pool get_pool_status create_connection test_connection
export -f cleanup_old_connections close_all_connections optimize_ssh_connection monitor_pool 