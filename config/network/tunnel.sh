#!/bin/bash

# 加载常量
source "$(dirname "${BASH_SOURCE[0]}")/../constants.sh"

# 网络隧道管理模块
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
fi
source "$SCRIPT_DIR/core/lib.sh"
load_config

# SSH隧道管理
tunnel_start() {
    # 检查是否已运行
    if [ -f "$SSH_TUNNEL_PID_FILE" ]; then
        local pid=$(cat "$SSH_TUNNEL_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "隧道已运行 (PID: $pid)"
            return $EXIT_SUCCESS
        else
            rm -f "$SSH_TUNNEL_PID_FILE"
        fi
    fi
    
    log_step "启动SSH隧道"
    
    # 启动隧道
    ssh -f -N -L "$REMOTE_DOCKER_PROXY_PORT:127.0.0.1:$REMOTE_DOCKER_PROXY_PORT" "$SSH_ALIAS" &
    local pid=$!
    
    # 保存PID
    echo "$pid" > "$SSH_TUNNEL_PID_FILE"
    
    # 验证连接
    sleep 2
    if test_proxy_connection; then
        log_info "隧道启动成功 (PID: $pid)"
        return $EXIT_SUCCESS
    else
        log_error "隧道启动失败"
        kill "$pid" 2>/dev/null
        rm -f "$SSH_TUNNEL_PID_FILE"
        return $EXIT_FAILURE
    fi
}

tunnel_stop() {
    if [ -f "$SSH_TUNNEL_PID_FILE" ]; then
        local pid=$(cat "$SSH_TUNNEL_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            log_info "进程已停止: $pid ($DEFAULT_SSH_TUNNEL_NAME)"
            rm -f "$SSH_TUNNEL_PID_FILE"
            log_info "SSH隧道已停止"
            return $EXIT_SUCCESS
        else
            log_warn "进程不存在: $pid"
            rm -f "$SSH_TUNNEL_PID_FILE"
            return $EXIT_FAILURE
        fi
    else
        log_warn "SSH隧道未运行"
        return $EXIT_FAILURE
    fi
}

tunnel_status() {
    if [ -f "$SSH_TUNNEL_PID_FILE" ]; then
        local pid=$(cat "$SSH_TUNNEL_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "SSH隧道正在运行 (PID: $pid)"
            if test_proxy_connection; then
                log_info "代理连接正常"
                return $EXIT_SUCCESS
            else
                log_warn "代理连接异常"
                return $EXIT_FAILURE
            fi
        else
            log_warn "PID文件存在但进程不存在"
            rm -f "$SSH_TUNNEL_PID_FILE"
            return $EXIT_FAILURE
        fi
    else
        log_warn "SSH隧道未运行"
        return $EXIT_FAILURE
    fi
}

tunnel_restart() {
    tunnel_stop
    sleep 1
    tunnel_start
}

# 测试代理连接
test_proxy_connection() {
    local proxy_url="http://$DEFAULT_LOCAL_PROXY_HOST:$DEFAULT_LOCAL_PROXY_PORT"
    if curl -s --proxy "$proxy_url" --max-time 5 http://www.google.com >/dev/null 2>&1; then
        return $EXIT_SUCCESS
    else
        return $EXIT_FAILURE
    fi
}

# 导出函数
export -f tunnel_start tunnel_stop tunnel_status tunnel_restart 