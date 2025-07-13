#!/bin/bash

# 远程开发环境 - 统一CLI入口

set -e

# 加载常量和核心库
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"
export SCRIPT_DIR
source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"
source "$SCRIPT_DIR/network/tunnel.sh"
source "$SCRIPT_DIR/network/connection_pool.sh"
source "$SCRIPT_DIR/dev/sync.sh"
source "$SCRIPT_DIR/dev/docker.sh"
source "$SCRIPT_DIR/dev/watcher.sh"
source "$SCRIPT_DIR/security/secrets.sh"
source "$SCRIPT_DIR/plugins/manager.sh"
source "$SCRIPT_DIR/dynamic/config_manager.sh"
source "$SCRIPT_DIR/cluster/manager.sh"

# 显示帮助信息
show_help() {
    cat << EOF
远程开发环境 CLI

用法: $0 <command> [options]

核心命令:
  setup              一键设置开发环境
  sync               同步代码到远程
  up                 启动开发环境
  down               停止开发环境
  logs               查看容器日志
  status             查看系统状态
  rebuild            重建容器

网络命令:
  tunnel <action>    管理SSH隧道 (start|stop|status|restart)
  proxy              配置远程代理
  pool <action>      SSH连接池管理 (init|status|cleanup|monitor)

同步命令:
  sync [direction]   同步代码 (to-remote|from-remote|bidirectional)
  watch <action>     文件监控 (start|stop|status|stats)

Docker命令:
  docker <action>    Docker操作 (up|down|logs|status|rebuild)
  local <action>     本地Docker操作
  remote <action>    远程Docker操作

安全命令:
  encrypt <file>     加密配置文件
  decrypt [file]     解密配置文件
  security audit     安全审计
  security clean     清理敏感数据

插件命令:
  plugin list        列出所有插件
  plugin enable      启用插件
  plugin disable     禁用插件
  plugin install     安装插件

集群命令:
  cluster init       初始化集群
  cluster status     集群状态
  cluster health     健康检查
  cluster monitor    监控集群

配置命令:
  config show        显示当前配置
  config update      更新配置
  config rollback    回滚配置

Web界面:
  web start          启动Web管理界面
  web stop           停止Web管理界面

其他命令:
  health             健康检查
  optimize           性能优化
  clean              清理临时文件
  help               显示此帮助信息

示例:
  $0 setup           # 初始化环境
  $0 tunnel start    # 启动SSH隧道
  $0 sync            # 同步代码
  $0 up              # 启动远程容器
  $0 logs            # 查看日志
  $0 status          # 查看状态

EOF
}

# 智能模式选择
smart_mode() {
    log_step "智能模式选择"
    
    # 检查SSH连接
    if check_ssh_connection; then
        log_info "检测到SSH连接，使用远程模式"
        return $EXIT_SUCCESS  # 远程模式
    else
        log_info "SSH连接失败，使用本地模式"
        return $EXIT_FAILURE  # 本地模式
    fi
}

# 一键设置
cmd_setup() {
    log_step "开始一键设置"
    
    # 检查依赖
    local missing_deps=()
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        return $EXIT_FAILURE
    fi
    
    # 配置SSH隧道
    if ! tunnel_start; then
        log_warn "SSH隧道启动失败，跳过代理配置"
    else
        log_info "SSH隧道已启动"
    fi
    
    # 同步代码
    if ! sync_to_remote; then
        log_error "代码同步失败"
        return $EXIT_FAILURE
    fi
    
    # 启动远程容器
    if ! docker_remote_up; then
        log_error "远程容器启动失败"
        return $EXIT_FAILURE
    fi
    
    log_info "设置完成！"
    cmd_status
}

# 同步命令
cmd_sync() {
    local direction=${1:-"to-remote"}
    
    case "$direction" in
        "to-remote"|"push")
            sync_to_remote
            ;;
        "from-remote"|"pull")
            sync_from_remote
            ;;
        "bidirectional"|"both")
            sync_bidirectional
            ;;
        "watch")
            sync_watch
            ;;
        "status")
            sync_status
            ;;
        *)
            log_error "未知同步方向: $direction"
            echo "支持的方向: to-remote, from-remote, bidirectional, watch, status"
            return $EXIT_FAILURE
            ;;
    esac
}

# 启动环境
cmd_up() {
    local mode=${1:-"auto"}
    
    case "$mode" in
        "local")
            docker_local_up
            ;;
        "remote")
            docker_remote_up
            ;;
        "auto")
            if smart_mode; then
                sync_to_remote
                docker_remote_up
            else
                docker_local_up
            fi
            ;;
        *)
            log_error "未知模式: $mode"
            return $EXIT_FAILURE
            ;;
    esac
}

# 停止环境
cmd_down() {
    local mode=${1:-"auto"}
    
    case "$mode" in
        "local")
            docker_local_down
            ;;
        "remote")
            docker_remote_down
            ;;
        "auto")
            if smart_mode; then
                docker_remote_down
            else
                docker_local_down
            fi
            ;;
        *)
            log_error "未知模式: $mode"
            return $EXIT_FAILURE
            ;;
    esac
}

# 查看日志
cmd_logs() {
    local mode=${1:-"auto"}
    local service=${2:-$DOCKER_SERVICE_NAME}
    
    case "$mode" in
        "local")
            docker_local_logs "$service"
            ;;
        "remote")
            docker_remote_logs "$service"
            ;;
        "auto")
            if smart_mode; then
                docker_remote_logs "$service"
            else
                docker_local_logs "$service"
            fi
            ;;
        *)
            log_error "未知模式: $mode"
            return $EXIT_FAILURE
            ;;
    esac
}

# 状态检查
cmd_status() {
    log_header "系统状态检查"
    
    log_header "配置信息"
    echo "SSH别名: $SSH_ALIAS"
    echo "远程路径: $REMOTE_PROJECT_PATH"
    echo "代理地址: $REMOTE_DOCKER_PROXY"
    
    log_header "连接状态"
    check_ssh_connection && log_info "SSH连接正常" || log_error "SSH连接失败"
    check_docker && log_info "本地Docker正常" || log_error "本地Docker异常"
    check_remote_docker && log_info "远程Docker正常" || log_error "远程Docker异常"
    
    log_header "隧道状态"
    tunnel_status
    
    log_header "容器状态"
    docker_status
}

# 健康检查
cmd_health() {
    log_step "健康检查"
    
    local issues=0
    
    # 检查配置
    if ! load_config; then
        log_error "配置加载失败"
        ((issues++))
    fi
    
    # 检查SSH
    if ! check_ssh_connection; then
        log_error "SSH连接异常"
        ((issues++))
    fi
    
    # 检查Docker
    if ! check_docker; then
        log_error "本地Docker异常"
        ((issues++))
    fi
    
    if ! check_remote_docker; then
        log_error "远程Docker异常"
        ((issues++))
    fi
    
    # 检查隧道
    if ! tunnel_status >/dev/null 2>&1; then
        log_warn "SSH隧道未运行"
        ((issues++))
    fi
    
    if [ $issues -eq 0 ]; then
        log_info "所有检查通过！"
        return $EXIT_SUCCESS
    else
        log_error "发现 $issues 个问题"
        return $EXIT_FAILURE
    fi
}

# 清理临时文件
cmd_clean() {
    log_step "清理临时文件"
    
    # 清理PID文件
    rm -f "$SSH_TUNNEL_PID_FILE"
    rm -f ${PID_DIR}/*.pid
    
    # 清理Docker
    if command_exists docker; then
        docker system prune -f
    fi
    
    log_info "清理完成"
}

# 显示配置
cmd_config() {
    log_step "当前配置"
    
    if load_config; then
        echo "SSH_ALIAS=$SSH_ALIAS"
        echo "REMOTE_HOST=$REMOTE_HOST"
        echo "REMOTE_PROJECT_PATH=$REMOTE_PROJECT_PATH"
        echo "REMOTE_DOCKER_PROXY=$REMOTE_DOCKER_PROXY"
        echo "DOCKER_SERVICE_NAME=$DOCKER_SERVICE_NAME"
        echo "LOCAL_PROXY_PORT=$LOCAL_PROXY_PORT"
    else
        log_error "配置加载失败"
        return $EXIT_CONFIG_ERROR
    fi
}

# 主函数
main() {
    local command=${1:-"help"}
    shift || true
    
    # 加载配置
    if ! load_config; then
        log_error "配置加载失败，请检查配置文件"
        return $EXIT_CONFIG_ERROR
    fi
    
    case "$command" in
        "setup")
            cmd_setup "$@"
            ;;
        "sync")
            cmd_sync "$@"
            ;;
        "up")
            cmd_up "$@"
            ;;
        "down")
            cmd_down "$@"
            ;;
        "logs")
            cmd_logs "$@"
            ;;
        "status")
            cmd_status "$@"
            ;;
        "rebuild")
            docker_rebuild "$@"
            ;;
        "tunnel")
            local action=${1:-"status"}
            case "$action" in
                "start") tunnel_start ;;
                "stop") tunnel_stop ;;
                "status") tunnel_status ;;
                "restart") tunnel_restart ;;
                *) log_error "未知隧道操作: $action"; return $EXIT_FAILURE ;;
            esac
            ;;
        "docker")
            local action=${1:-"status"}
            shift || true
            case "$action" in
                "up") docker_remote_up "$@" ;;
                "down") docker_remote_down "$@" ;;
                "logs") docker_remote_logs "$@" ;;
                "status") docker_status "$@" ;;
                "rebuild") docker_rebuild "remote" ;;
                *) log_error "未知Docker操作: $action"; return $EXIT_FAILURE ;;
            esac
            ;;
        "local")
            local action=${1:-"status"}
            shift || true
            case "$action" in
                "up") docker_local_up "$@" ;;
                "down") docker_local_down "$@" ;;
                "logs") docker_local_logs "$@" ;;
                "status") docker_local_status "$@" ;;
                "rebuild") docker_local_rebuild ;;
                *) log_error "未知本地操作: $action"; return $EXIT_FAILURE ;;
            esac
            ;;
        "remote")
            local action=${1:-"status"}
            shift || true
            case "$action" in
                "up") docker_remote_up "$@" ;;
                "down") docker_remote_down "$@" ;;
                "logs") docker_remote_logs "$@" ;;
                "status") docker_remote_status "$@" ;;
                "rebuild") docker_remote_rebuild ;;
                *) log_error "未知远程操作: $action"; return $EXIT_FAILURE ;;
            esac
            ;;
        "watch")
            local action="$1"
            shift || true
            case "$action" in
                "start")
                    local watch_dir="${1:-.}"
                    log_header "启动文件监控"
                    sync_watch "$watch_dir"
                    ;;
                "stop")
                    log_header "停止文件监控"
                    source "$SCRIPT_DIR/dev/watcher.sh"
                    stop_watcher
                    ;;
                "status")
                    log_header "文件监控状态"
                    source "$SCRIPT_DIR/dev/watcher.sh"
                    watcher_status
                    ;;
                "stats")
                    log_header "文件监控统计"
                    source "$SCRIPT_DIR/dev/watcher.sh"
                    watcher_stats
                    ;;
                *)
                    log_error "未知监控命令: $action"
                    echo "可用命令: start, stop, status, stats"
                    return $EXIT_FAILURE
                    ;;
            esac
            ;;
        "health")
            cmd_health "$@"
            ;;
        "clean")
            cmd_clean "$@"
            ;;
        "config")
            local action="$1"
            shift || true
            case "$action" in
                "show")
                    cmd_config
                    ;;
                "update")
                    log_header "更新配置"
                    source "$SCRIPT_DIR/dynamic/config_manager.sh"
                    update_config "$@"
                    ;;
                "rollback")
                    log_header "回滚配置"
                    source "$SCRIPT_DIR/dynamic/config_manager.sh"
                    rollback_config "$@"
                    ;;
                *)
                    # 默认显示配置
                    cmd_config
                    ;;
            esac
            ;;
        
        # 插件管理
        "plugin")
            local action="$1"
            shift || true
            case "$action" in
                "list") list_plugins ;;
                "enable") 
                    if [[ -z "$1" ]]; then
                        log_error "请指定插件名称"
                        return $EXIT_FAILURE
                    fi
                    enable_plugin "$1"
                    ;;
                "disable")
                    if [[ -z "$1" ]]; then
                        log_error "请指定插件名称"
                        return $EXIT_FAILURE
                    fi
                    disable_plugin "$1"
                    ;;
                "install")
                    log_info "插件安装功能即将推出"
                    ;;
                *)
                    log_error "未知插件命令: $action"
                    echo "可用命令: list, enable, disable, install"
                    return $EXIT_FAILURE
                    ;;
            esac
            ;;
        
        # 集群管理
        "cluster")
            local action="$1"
            shift || true
            case "$action" in
                "init") init_cluster ;;
                "status") cluster_status ;;
                "health") cluster_health_check ;;
                "monitor") monitor_cluster ;;
                *)
                    log_error "未知集群命令: $action"
                    echo "可用命令: init, status, health, monitor"
                    return $EXIT_FAILURE
                    ;;
            esac
            ;;
        
        # Web管理界面
        "web")
            local action="$1"
            shift || true
            case "$action" in
                "start")
                    log_header "启动Web管理界面"
                    cd "$SCRIPT_DIR/../web" || return $EXIT_FAILURE
                    
                    # 检查Python依赖
                    if ! python3 -c "import flask" 2>/dev/null; then
                        log_info "安装Python依赖..."
                        pip3 install -r requirements.txt
                    fi
                    
                    log_info "启动Web服务器..."
                    python3 app.py &
                    echo $! > /tmp/web-manager.pid
                    log_success "Web管理界面已启动"
                    log_info "访问地址: http://localhost:8080"
                    ;;
                "stop")
                    log_header "停止Web管理界面"
                    if [[ -f /tmp/web-manager.pid ]]; then
                        local pid=$(cat /tmp/web-manager.pid)
                        if kill -0 "$pid" 2>/dev/null; then
                            kill "$pid"
                            rm -f /tmp/web-manager.pid
                            log_success "Web管理界面已停止"
                        else
                            log_warning "Web管理界面进程不存在"
                            rm -f /tmp/web-manager.pid
                        fi
                    else
                        log_warning "Web管理界面未运行"
                    fi
                    ;;
                *)
                    log_error "未知Web命令: $action"
                    echo "可用命令: start, stop"
                    return $EXIT_FAILURE
                    ;;
            esac
            ;;
        
        # 安全命令
        "security")
            local action="$1"
            shift || true
            case "$action" in
                "audit")
                    log_header "安全审计"
                    source "$SCRIPT_DIR/security/secrets.sh"
                    security_audit
                    ;;
                "clean")
                    log_header "清理敏感数据"
                    source "$SCRIPT_DIR/security/secrets.sh"
                    security_cleanup
                    ;;
                *)
                    log_error "未知安全命令: $action"
                    echo "可用命令: audit, clean"
                    return $EXIT_FAILURE
                    ;;
            esac
            ;;
        
        # 加密解密命令
        "encrypt")
            if [[ -z "$1" ]]; then
                log_error "请指定要加密的文件"
                return $EXIT_FAILURE
            fi
            log_header "加密配置文件"
            source "$SCRIPT_DIR/security/secrets.sh"
            encrypt_config "$1"
            ;;
        
        "decrypt")
            local file="$1"
            log_header "解密配置文件"
            source "$SCRIPT_DIR/security/secrets.sh"
            decrypt_config "$file"
            ;;
        
        # SSH连接池命令
        "pool")
            local action="$1"
            shift || true
            case "$action" in
                "init")
                    log_header "初始化SSH连接池"
                    source "$SCRIPT_DIR/network/connection_pool.sh"
                    init_connection_pool
                    ;;
                "status")
                    source "$SCRIPT_DIR/network/connection_pool.sh"
                    get_pool_status
                    ;;
                "cleanup")
                    log_header "清理SSH连接池"
                    source "$SCRIPT_DIR/network/connection_pool.sh"
                    # 实现清理功能
                    rm -f "$SSH_POOL_DIR"/*
                    log_success "SSH连接池已清理"
                    ;;
                "monitor")
                    log_header "监控SSH连接池"
                    source "$SCRIPT_DIR/network/connection_pool.sh"
                    # 实现监控功能
                    while true; do
                        get_pool_status
                        sleep 5
                    done
                    ;;
                *)
                    log_error "未知连接池命令: $action"
                    echo "可用命令: init, status, cleanup, monitor"
                    return $EXIT_FAILURE
                    ;;
            esac
            ;;
        
        # 代理配置命令
        "proxy")
            log_header "配置远程代理"
            source "$SCRIPT_DIR/network/tunnel.sh"
            if tunnel_start; then
                log_success "代理配置成功"
                log_info "代理地址: http://127.0.0.1:$LOCAL_PROXY_PORT"
            else
                log_error "代理配置失败"
            fi
            ;;
        
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            log_error "未知命令: $command"
            echo "使用 '$0 help' 查看帮助"
            return $EXIT_FAILURE
            ;;
    esac
}

# 运行主函数
main "$@" 