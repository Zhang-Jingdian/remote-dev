#!/bin/bash

# =============================================================================
# 多服务器集群管理系统 - 企业级扩展
# =============================================================================

# 获取脚本目录
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"

source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"
source "$SCRIPT_DIR/network/connection_pool.sh"

# 集群配置
CLUSTER_CONFIG_FILE="$CONFIG_DIR/cluster/servers.yml"
CLUSTER_STATE_FILE="/tmp/cluster-state.json"
HEALTH_CHECK_INTERVAL=30
FAILOVER_THRESHOLD=3

# 初始化集群
init_cluster() {
    log_header "初始化服务器集群"
    
    # 创建集群配置目录
    mkdir -p "$CONFIG_DIR/cluster"
    
    # 创建服务器配置模板
    if [[ ! -f "$CLUSTER_CONFIG_FILE" ]]; then
        create_cluster_config_template
    fi
    
    # 初始化集群状态
    init_cluster_state
    
    log_success "集群初始化完成"
}

# 创建集群配置模板
create_cluster_config_template() {
    log_info "创建集群配置模板..."
    
    cat > "$CLUSTER_CONFIG_FILE" << 'EOF'
# =============================================================================
# 服务器集群配置
# =============================================================================

servers:
  - name: "primary"
    host: "192.168.1.100"
    user: "dev"
    port: 22
    role: "primary"
    weight: 100
    health_check: "/health"
    tags: ["production", "primary"]
    
  - name: "secondary"
    host: "192.168.1.101"
    user: "dev"
    port: 22
    role: "secondary"
    weight: 50
    health_check: "/health"
    tags: ["production", "backup"]
    
  - name: "development"
    host: "192.168.1.102"
    user: "dev"
    port: 22
    role: "development"
    weight: 25
    health_check: "/health"
    tags: ["development", "testing"]

load_balancer:
  algorithm: "weighted_round_robin"  # round_robin, weighted_round_robin, least_connections
  sticky_sessions: false
  health_check_interval: 30
  failover_threshold: 3

monitoring:
  enabled: true
  metrics_port: 9090
  alert_webhook: "https://hooks.slack.com/services/..."
EOF
    
    log_success "集群配置模板创建完成"
}

# 初始化集群状态
init_cluster_state() {
    cat > "$CLUSTER_STATE_FILE" << 'EOF'
{
  "timestamp": "",
  "active_servers": [],
  "failed_servers": [],
  "current_primary": "",
  "load_balancer": {
    "algorithm": "weighted_round_robin",
    "current_server": 0,
    "request_count": 0
  },
  "health_checks": {}
}
EOF
    
    # 更新时间戳
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    jq ".timestamp = \"$timestamp\"" "$CLUSTER_STATE_FILE" > "$CLUSTER_STATE_FILE.tmp"
    mv "$CLUSTER_STATE_FILE.tmp" "$CLUSTER_STATE_FILE"
}

# 解析集群配置
parse_cluster_config() {
    if [[ ! -f "$CLUSTER_CONFIG_FILE" ]]; then
        log_error "集群配置文件不存在: $CLUSTER_CONFIG_FILE"
        return 1
    fi
    
    # 使用yq解析YAML（如果没有则用python）
    if command -v yq &> /dev/null; then
        yq eval "$CLUSTER_CONFIG_FILE" -o json
    else
        python3 -c "
import yaml, json, sys
with open('$CLUSTER_CONFIG_FILE', 'r') as f:
    data = yaml.safe_load(f)
    print(json.dumps(data, indent=2))
"
    fi
}

# 获取服务器列表
get_servers() {
    local role="$1"
    local tag="$2"
    
    local config=$(parse_cluster_config)
    
    if [[ -n "$role" ]]; then
        echo "$config" | jq -r ".servers[] | select(.role == \"$role\") | .name"
    elif [[ -n "$tag" ]]; then
        echo "$config" | jq -r ".servers[] | select(.tags[] == \"$tag\") | .name"
    else
        echo "$config" | jq -r ".servers[].name"
    fi
}

# 获取服务器信息
get_server_info() {
    local server_name="$1"
    
    local config=$(parse_cluster_config)
    echo "$config" | jq -r ".servers[] | select(.name == \"$server_name\")"
}

# 健康检查
health_check_server() {
    local server_name="$1"
    
    local server_info=$(get_server_info "$server_name")
    local host=$(echo "$server_info" | jq -r ".host")
    local user=$(echo "$server_info" | jq -r ".user")
    local port=$(echo "$server_info" | jq -r ".port")
    local health_endpoint=$(echo "$server_info" | jq -r ".health_check")
    
    log_info "健康检查: $server_name ($host)"
    
    # SSH连接测试
    if ! ssh -o BatchMode=yes -o ConnectTimeout=5 -p "$port" "$user@$host" exit 2>/dev/null; then
        log_error "SSH连接失败: $server_name"
        return 1
    fi
    
    # 服务健康检查
    if [[ -n "$health_endpoint" && "$health_endpoint" != "null" ]]; then
        local health_status=$(ssh -p "$port" "$user@$host" "curl -s -o /dev/null -w '%{http_code}' http://localhost:8000$health_endpoint" 2>/dev/null)
        
        if [[ "$health_status" == "200" ]]; then
            log_success "服务健康: $server_name"
            return 0
        else
            log_warning "服务异常: $server_name (HTTP: $health_status)"
            return 1
        fi
    fi
    
    log_success "服务器健康: $server_name"
    return 0
}

# 集群健康检查
cluster_health_check() {
    log_header "集群健康检查"
    
    local servers=$(get_servers)
    local healthy_servers=()
    local failed_servers=()
    
    while IFS= read -r server; do
        if health_check_server "$server"; then
            healthy_servers+=("$server")
        else
            failed_servers+=("$server")
        fi
    done <<< "$servers"
    
    # 更新集群状态
    update_cluster_state "${healthy_servers[@]}" "${failed_servers[@]}"
    
    # 显示结果
    log_info "健康服务器: ${#healthy_servers[@]}"
    for server in "${healthy_servers[@]}"; do
        echo "  ✓ $server"
    done
    
    if [[ ${#failed_servers[@]} -gt 0 ]]; then
        log_warning "故障服务器: ${#failed_servers[@]}"
        for server in "${failed_servers[@]}"; do
            echo "  ✗ $server"
        done
    fi
}

# 更新集群状态
update_cluster_state() {
    local healthy_servers=("$@")
    local failed_servers=()
    
    # 分离健康和故障服务器
    local all_servers=$(get_servers)
    while IFS= read -r server; do
        local is_healthy=false
        for healthy in "${healthy_servers[@]}"; do
            if [[ "$server" == "$healthy" ]]; then
                is_healthy=true
                break
            fi
        done
        
        if [[ "$is_healthy" == false ]]; then
            failed_servers+=("$server")
        fi
    done <<< "$all_servers"
    
    # 更新状态文件
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --argjson healthy "$(printf '%s\n' "${healthy_servers[@]}" | jq -R . | jq -s .)" \
       --argjson failed "$(printf '%s\n' "${failed_servers[@]}" | jq -R . | jq -s .)" \
       --arg timestamp "$timestamp" \
       '.timestamp = $timestamp | .active_servers = $healthy | .failed_servers = $failed' \
       "$CLUSTER_STATE_FILE" > "$CLUSTER_STATE_FILE.tmp"
    
    mv "$CLUSTER_STATE_FILE.tmp" "$CLUSTER_STATE_FILE"
}

# 负载均衡选择服务器
select_server() {
    local algorithm="${1:-weighted_round_robin}"
    
    local active_servers=$(jq -r '.active_servers[]' "$CLUSTER_STATE_FILE")
    
    if [[ -z "$active_servers" ]]; then
        log_error "没有可用的服务器"
        return 1
    fi
    
    case "$algorithm" in
        "round_robin")
            select_round_robin
            ;;
        "weighted_round_robin")
            select_weighted_round_robin
            ;;
        "least_connections")
            select_least_connections
            ;;
        *)
            log_error "未知的负载均衡算法: $algorithm"
            return 1
            ;;
    esac
}

# 轮询选择
select_round_robin() {
    local active_servers=($(jq -r '.active_servers[]' "$CLUSTER_STATE_FILE"))
    local current_index=$(jq -r '.load_balancer.current_server' "$CLUSTER_STATE_FILE")
    
    local selected_server="${active_servers[$current_index]}"
    
    # 更新索引
    local next_index=$(( (current_index + 1) % ${#active_servers[@]} ))
    jq ".load_balancer.current_server = $next_index" "$CLUSTER_STATE_FILE" > "$CLUSTER_STATE_FILE.tmp"
    mv "$CLUSTER_STATE_FILE.tmp" "$CLUSTER_STATE_FILE"
    
    echo "$selected_server"
}

# 加权轮询选择
select_weighted_round_robin() {
    local active_servers=($(jq -r '.active_servers[]' "$CLUSTER_STATE_FILE"))
    local config=$(parse_cluster_config)
    
    # 计算权重总和
    local total_weight=0
    for server in "${active_servers[@]}"; do
        local weight=$(echo "$config" | jq -r ".servers[] | select(.name == \"$server\") | .weight")
        total_weight=$((total_weight + weight))
    done
    
    # 随机选择
    local random=$((RANDOM % total_weight))
    local current_weight=0
    
    for server in "${active_servers[@]}"; do
        local weight=$(echo "$config" | jq -r ".servers[] | select(.name == \"$server\") | .weight")
        current_weight=$((current_weight + weight))
        
        if [[ $random -lt $current_weight ]]; then
            echo "$server"
            return 0
        fi
    done
    
    # 默认返回第一个服务器
    echo "${active_servers[0]}"
}

# 故障转移
failover() {
    local failed_server="$1"
    
    log_header "执行故障转移: $failed_server"
    
    # 从活跃服务器列表中移除
    jq --arg server "$failed_server" \
       '.active_servers = (.active_servers | map(select(. != $server))) | 
        .failed_servers = (.failed_servers + [$server] | unique)' \
       "$CLUSTER_STATE_FILE" > "$CLUSTER_STATE_FILE.tmp"
    mv "$CLUSTER_STATE_FILE.tmp" "$CLUSTER_STATE_FILE"
    
    # 选择新的主服务器
    local new_primary=$(select_server)
    
    if [[ -n "$new_primary" ]]; then
        log_success "故障转移完成，新主服务器: $new_primary"
        
        # 更新当前主服务器
        jq --arg primary "$new_primary" '.current_primary = $primary' \
           "$CLUSTER_STATE_FILE" > "$CLUSTER_STATE_FILE.tmp"
        mv "$CLUSTER_STATE_FILE.tmp" "$CLUSTER_STATE_FILE"
        
        # 发送告警
        send_alert "故障转移" "服务器 $failed_server 故障，已切换到 $new_primary"
        
        return 0
    else
        log_error "故障转移失败，没有可用的服务器"
        send_alert "集群故障" "所有服务器都不可用"
        return 1
    fi
}

# 发送告警
send_alert() {
    local title="$1"
    local message="$2"
    
    local config=$(parse_cluster_config)
    local webhook_url=$(echo "$config" | jq -r ".monitoring.alert_webhook")
    
    if [[ -n "$webhook_url" && "$webhook_url" != "null" ]]; then
        curl -X POST -H 'Content-type: application/json' \
             --data "{\"text\":\"🚨 $title: $message\"}" \
             "$webhook_url" 2>/dev/null
    fi
    
    log_info "告警发送: $title - $message"
}

# 集群监控
monitor_cluster() {
    log_header "启动集群监控"
    
    while true; do
        cluster_health_check
        
        # 检查是否需要故障转移
        local failed_servers=($(jq -r '.failed_servers[]' "$CLUSTER_STATE_FILE"))
        for server in "${failed_servers[@]}"; do
            log_warning "检测到故障服务器: $server"
        done
        
        sleep "$HEALTH_CHECK_INTERVAL"
    done
}

# 集群状态
cluster_status() {
    log_header "集群状态"
    
    if [[ ! -f "$CLUSTER_STATE_FILE" ]]; then
        log_warning "集群状态文件不存在"
        return 1
    fi
    
    local state=$(cat "$CLUSTER_STATE_FILE")
    local timestamp=$(echo "$state" | jq -r '.timestamp')
    local active_count=$(echo "$state" | jq -r '.active_servers | length')
    local failed_count=$(echo "$state" | jq -r '.failed_servers | length')
    local current_primary=$(echo "$state" | jq -r '.current_primary')
    
    log_info "最后更新: $timestamp"
    log_info "活跃服务器: $active_count"
    log_info "故障服务器: $failed_count"
    log_info "当前主服务器: $current_primary"
    
    # 显示服务器详情
    echo ""
    echo "活跃服务器:"
    echo "$state" | jq -r '.active_servers[]' | while read server; do
        echo "  ✓ $server"
    done
    
    if [[ $failed_count -gt 0 ]]; then
        echo ""
        echo "故障服务器:"
        echo "$state" | jq -r '.failed_servers[]' | while read server; do
            echo "  ✗ $server"
        done
    fi
}

# 导出函数
export -f init_cluster cluster_health_check select_server failover monitor_cluster cluster_status 