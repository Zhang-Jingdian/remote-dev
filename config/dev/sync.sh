#!/bin/bash

# =============================================================================
# 代码同步模块 - 本地与远程代码同步管理
# 作者: Zhang-Jingdian
# 邮箱: 2157429750@qq.com
# 创建时间: 2025年7月14日
# 描述: 提供本地与远程服务器之间的代码同步功能，支持文件监控和自动同步
# =============================================================================

# 加载常量
source "$(dirname "${BASH_SOURCE[0]}")/../constants.sh"

# 代码同步模块
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
fi
source "$SCRIPT_DIR/core/lib.sh"
load_config

# 同步代码到远程
sync_to_remote() {
    local source_dir="${1:-.}"
    local target_dir="${2:-$REMOTE_PROJECT_PATH}"
    
    log_step "同步到远程: $SSH_ALIAS:$target_dir"
    
    # 检查SSH连接
    if ! check_ssh_connection; then
        return 1
    fi
    
    # 确保远程目录存在
    ensure_remote_dir "$SSH_ALIAS" "$target_dir"
    
    # 构建排除模式
    local exclude_args=""
    for pattern in $SYNC_EXCLUDE_PATTERNS; do
        exclude_args="$exclude_args --exclude=$pattern"
    done
    
    log_debug "开始同步..."
    if rsync -avz --delete $exclude_args "$source_dir/" "$SSH_ALIAS:$target_dir/"; then
        log_info "同步完成"
        return 0
    else
        log_error "同步失败"
        return 1
    fi
}

# 从远程同步代码
sync_from_remote() {
    local source_dir="${1:-$REMOTE_PROJECT_PATH}"
    local target_dir="${2:-.}"
    
    log_step "从远程服务器同步代码"
    log_info "源: $SSH_ALIAS:$source_dir"
    log_info "目标目录: $target_dir"
    
    # 检查SSH连接
    if ! check_ssh_connection; then
        return 1
    fi
    
    # 确保本地目录存在
    ensure_dir "$target_dir"
    
    # 构建排除模式
    local exclude_args=""
    for pattern in $SYNC_EXCLUDE_PATTERNS; do
        exclude_args="$exclude_args --exclude=$pattern"
    done
    
    # 执行同步
    log_info "开始同步..."
    if rsync -avz --delete $exclude_args "$SSH_ALIAS:$source_dir/" "$target_dir/"; then
        log_info "同步完成"
        return 0
    else
        log_error "同步失败"
        return 1
    fi
}

# 双向同步
sync_bidirectional() {
    log_step "双向同步"
    
    # 先同步到远程
    if sync_to_remote; then
        log_info "本地->远程 同步完成"
    else
        log_error "本地->远程 同步失败"
        return 1
    fi
    
    # 再从远程同步回来（处理远程可能的修改）
    if sync_from_remote; then
        log_info "远程->本地 同步完成"
    else
        log_warn "远程->本地 同步失败（可能无新内容）"
    fi
    
    return 0
}

# 检查并安装fswatch
check_and_install_fswatch() {
    if command_exists fswatch; then
        log_info "fswatch已安装"
        return 0
    fi
    
    log_warn "fswatch未安装，正在尝试自动安装..."
    
    # 检测操作系统并安装
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            log_info "使用Homebrew安装fswatch..."
            brew install fswatch
        elif command_exists port; then
            log_info "使用MacPorts安装fswatch..."
            sudo port install fswatch
        else
            log_error "请先安装Homebrew或MacPorts，然后运行: brew install fswatch"
            return 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            log_info "使用apt安装fswatch..."
            sudo apt-get update && sudo apt-get install -y fswatch
        elif command_exists yum; then
            log_info "使用yum安装fswatch..."
            sudo yum install -y fswatch
        elif command_exists dnf; then
            log_info "使用dnf安装fswatch..."
            sudo dnf install -y fswatch
        elif command_exists pacman; then
            log_info "使用pacman安装fswatch..."
            sudo pacman -S fswatch
        else
            log_error "不支持的Linux发行版，请手动安装fswatch"
            return 1
        fi
    else
        log_error "不支持的操作系统: $OSTYPE"
        return 1
    fi
    
    # 验证安装
    if command_exists fswatch; then
        log_info "fswatch安装成功"
        return 0
    else
        log_error "fswatch安装失败"
        return 1
    fi
}

# 使用inotify替代fswatch (Linux)
sync_watch_inotify() {
    local watch_dir="${1:-.}"
    
    if ! command_exists inotifywait; then
        log_error "inotifywait未安装，请安装inotify-tools"
        return 1
    fi
    
    log_info "使用inotifywait监控文件变化"
    
    inotifywait -m -r -e modify,create,delete,move "$watch_dir" \
        --format '%w%f %e' | while read file event; do
        log_debug "文件变化: $file ($event)"
        sync_to_remote "$watch_dir"
    done
}

# 使用find替代fswatch (通用)
sync_watch_polling() {
    local watch_dir="${1:-.}"
    local last_sync_file="/tmp/last_sync_$(basename "$watch_dir")"
    
    log_info "使用轮询模式监控文件变化"
    
    # 创建初始时间戳
    touch "$last_sync_file"
    
    while true; do
        # 查找比上次同步时间新的文件
        if find "$watch_dir" -newer "$last_sync_file" -type f | grep -q .; then
            log_debug "检测到文件变化，开始同步..."
            if sync_to_remote "$watch_dir"; then
                # 更新时间戳
                touch "$last_sync_file"
            fi
        fi
        sleep "$AUTO_SYNC_INTERVAL"
    done
}

# 智能文件监控（自动选择最佳方案）
sync_watch_smart() {
    local watch_dir="${1:-.}"
    
    log_step "启动智能文件监控同步"
    log_info "监控目录: $watch_dir"
    log_info "同步间隔: ${AUTO_SYNC_INTERVAL}秒"
    
    # 1. 优先使用fswatch（性能最好）
    if command_exists fswatch; then
        log_info "使用fswatch监控文件变化"
        fswatch -o "$watch_dir" | while read f; do
            log_debug "检测到文件变化，开始同步..."
            sync_to_remote "$watch_dir"
        done
    # 2. Linux系统使用inotify
    elif [[ "$OSTYPE" == "linux-gnu"* ]] && command_exists inotifywait; then
        sync_watch_inotify "$watch_dir"
    # 3. 尝试安装fswatch
    elif check_and_install_fswatch; then
        log_info "fswatch安装成功，重新启动监控"
        sync_watch_smart "$watch_dir"
    # 4. 降级到轮询模式
    else
        log_warn "使用轮询模式监控文件变化（性能较低）"
        sync_watch_polling "$watch_dir"
    fi
}

# 监控文件变化并自动同步
sync_watch() {
    local watch_dir="${1:-.}"
    
    # 使用智能监控
    sync_watch_smart "$watch_dir"
}

# 同步状态检查
sync_status() {
    log_step "检查同步状态"
    
    # 检查SSH连接
    if ! check_ssh_connection; then
        return 1
    fi
    
    # 比较本地和远程文件
    local local_files=$(find . -type f -name "*.py" -o -name "*.js" -o -name "*.md" | wc -l)
    local remote_files=$(ssh "$SSH_ALIAS" "cd '$REMOTE_PROJECT_PATH' && find . -type f -name '*.py' -o -name '*.js' -o -name '*.md' | wc -l")
    
    log_info "本地文件数: $local_files"
    log_info "远程文件数: $remote_files"
    
    if [ "$local_files" -eq "$remote_files" ]; then
        log_info "文件数量一致"
    else
        log_warn "文件数量不一致，可能需要同步"
    fi
}

# 导出函数
export -f sync_to_remote sync_from_remote sync_bidirectional sync_watch sync_status 