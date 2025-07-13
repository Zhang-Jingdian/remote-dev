#!/bin/bash

# =============================================================================
# 智能文件监控系统 - 高性能实时同步
# =============================================================================

# 获取脚本目录
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"

source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"

# 监控状态文件
WATCHER_PID_FILE="/tmp/dev-watcher.pid"
WATCHER_LOG_FILE="/tmp/dev-watcher.log"
SYNC_QUEUE_FILE="/tmp/dev-sync-queue"

# 智能同步队列 (兼容macOS bash 3.2)
# 使用文件系统存储替代关联数组
SYNC_QUEUE_DIR="/tmp/dev-sync-queue"
LAST_SYNC_DIR="/tmp/dev-last-sync"
mkdir -p "$SYNC_QUEUE_DIR" "$LAST_SYNC_DIR"

# 启动文件监控
start_watcher() {
    log_header "启动智能文件监控系统"
    
    # 检查是否已经运行
    if [[ -f "$WATCHER_PID_FILE" ]]; then
        local pid=$(cat "$WATCHER_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            log_warning "文件监控已经在运行中 (PID: $pid)"
            return 0
        fi
    fi
    
    # 检查依赖
    if ! command -v fswatch &> /dev/null; then
        log_info "安装 fswatch..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install fswatch
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get install -y fswatch || sudo yum install -y fswatch
        fi
    fi
    
    # 启动监控进程
    log_info "启动文件监控进程..."
    nohup fswatch -r \
        --exclude="$RSYNC_EXCLUDE_PATTERNS" \
        --exclude="\.git" \
        --exclude="node_modules" \
        --exclude="__pycache__" \
        --exclude="\.DS_Store" \
        --exclude="\.log$" \
        --exclude="\.tmp$" \
        --latency=0.5 \
        "$PWD" | while read file; do
            handle_file_change "$file"
        done > "$WATCHER_LOG_FILE" 2>&1 &
    
    local watcher_pid=$!
    echo "$watcher_pid" > "$WATCHER_PID_FILE"
    
    log_success "文件监控已启动 (PID: $watcher_pid)"
    log_info "监控日志: $WATCHER_LOG_FILE"
}

# 处理文件变化
handle_file_change() {
    local file="$1"
    local current_time=$(date +%s)
    local file_hash=$(echo "$file" | md5sum | cut -d' ' -f1)
    
    # 防抖处理 - 避免频繁同步 (兼容macOS)
    local last_sync_file="$LAST_SYNC_DIR/$file_hash"
    if [[ -f "$last_sync_file" ]]; then
        local last_sync_time=$(cat "$last_sync_file")
        local time_diff=$((current_time - last_sync_time))
        if [[ $time_diff -lt 2 ]]; then
            return 0
        fi
    fi
    
    echo "$current_time" > "$last_sync_file"
    
    # 添加到同步队列
    echo "$file" >> "$SYNC_QUEUE_FILE"
    
    # 触发智能同步
    trigger_smart_sync
}

# 智能同步触发器
trigger_smart_sync() {
    # 批量处理同步队列
    if [[ -f "$SYNC_QUEUE_FILE" ]]; then
        local queue_size=$(wc -l < "$SYNC_QUEUE_FILE")
        
        # 当队列达到阈值或超时时触发同步
        if [[ $queue_size -ge 5 ]] || should_sync_timeout; then
            log_info "触发智能同步 (队列: $queue_size 个文件)"
            
            # 执行增量同步
            source "$(dirname "$0")/sync.sh"
            sync_to_remote --incremental
            
            # 清空队列
            > "$SYNC_QUEUE_FILE"
        fi
    fi
}

# 检查是否应该超时同步
should_sync_timeout() {
    if [[ -f "$SYNC_QUEUE_FILE" ]]; then
        local last_mod=$(stat -c %Y "$SYNC_QUEUE_FILE" 2>/dev/null || stat -f %m "$SYNC_QUEUE_FILE" 2>/dev/null)
        local current_time=$(date +%s)
        local time_diff=$((current_time - last_mod))
        
        # 超过10秒就同步
        [[ $time_diff -gt 10 ]]
    else
        false
    fi
}

# 停止文件监控
stop_watcher() {
    log_header "停止文件监控系统"
    
    if [[ -f "$WATCHER_PID_FILE" ]]; then
        local pid=$(cat "$WATCHER_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$WATCHER_PID_FILE"
            log_success "文件监控已停止"
        else
            log_warning "文件监控进程不存在"
            rm -f "$WATCHER_PID_FILE"
        fi
    else
        log_warning "文件监控未运行"
    fi
    
    # 清理临时文件
    rm -f "$SYNC_QUEUE_FILE"
}

# 获取监控状态
get_watcher_status() {
    if [[ -f "$WATCHER_PID_FILE" ]]; then
        local pid=$(cat "$WATCHER_PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            echo "running:$pid"
        else
            echo "stopped"
        fi
    else
        echo "stopped"
    fi
}

# 显示监控统计
show_watcher_stats() {
    log_header "文件监控统计"
    
    local status=$(get_watcher_status)
    if [[ "$status" == "stopped" ]]; then
        log_warning "文件监控未运行"
        return 1
    fi
    
    local pid=$(echo "$status" | cut -d: -f2)
    log_info "进程ID: $pid"
    
    if [[ -f "$WATCHER_LOG_FILE" ]]; then
        local log_size=$(wc -l < "$WATCHER_LOG_FILE")
        log_info "监控事件: $log_size 个"
    fi
    
    if [[ -f "$SYNC_QUEUE_FILE" ]]; then
        local queue_size=$(wc -l < "$SYNC_QUEUE_FILE")
        log_info "同步队列: $queue_size 个文件"
    fi
    
    # 显示最近的文件变化
    if [[ -f "$WATCHER_LOG_FILE" ]]; then
        log_info "最近变化的文件:"
        tail -5 "$WATCHER_LOG_FILE" | while read line; do
            echo "  → $line"
        done
    fi
}

# 重启监控
restart_watcher() {
    stop_watcher
    sleep 1
    start_watcher
}

# 导出函数
export -f start_watcher stop_watcher get_watcher_status show_watcher_stats restart_watcher 