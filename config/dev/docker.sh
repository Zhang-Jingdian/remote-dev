#!/bin/bash

# 加载常量
source "$(dirname "${BASH_SOURCE[0]}")/../constants.sh"

# Docker管理模块
if [ -z "$SCRIPT_DIR" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
fi
source "$SCRIPT_DIR/core/lib.sh"
load_config

# 本地Docker操作
docker_local_up() {
    log_step "启动本地Docker容器"
    
    if ! check_docker; then
        return $EXIT_FAILURE
    fi
    
    local project_root=$(get_project_root)
    cd "$project_root"
    
    if docker compose -f "$DOCKER_COMPOSE_FILE_PATH" up -d; then
        log_info "本地容器启动成功"
        return $EXIT_SUCCESS
    else
        log_error "本地容器启动失败"
        return $EXIT_FAILURE
    fi
}

docker_local_down() {
    log_step "停止本地Docker容器"
    
    local project_root=$(get_project_root)
    cd "$project_root"
    
    if docker compose -f "$DOCKER_COMPOSE_FILE_PATH" down; then
        log_info "本地容器已停止"
        return $EXIT_SUCCESS
    else
        log_error "本地容器停止失败"
        return $EXIT_FAILURE
    fi
}

docker_local_logs() {
    local service=${1:-$DEFAULT_DOCKER_SERVICE_NAME}
    
    local project_root=$(get_project_root)
    cd "$project_root"
    
    docker compose -f "$DOCKER_COMPOSE_FILE_PATH" logs -f "$service"
}

# 远程Docker操作
docker_remote_up() {
    log_step "启动远程Docker容器"
    
    if ! check_ssh_connection; then
        return $EXIT_FAILURE
    fi
    
    if ! check_remote_docker; then
        return $EXIT_FAILURE
    fi
    
    if ssh "$SSH_ALIAS" "cd '$REMOTE_PROJECT_PATH' && docker compose -f '$DOCKER_COMPOSE_FILE_PATH' up -d"; then
        log_info "远程容器启动成功"
        return $EXIT_SUCCESS
    else
        log_error "远程容器启动失败"
        return $EXIT_FAILURE
    fi
}

docker_remote_down() {
    log_step "停止远程Docker容器"
    
    if ! check_ssh_connection; then
        return $EXIT_FAILURE
    fi
    
    if ssh "$SSH_ALIAS" "cd '$REMOTE_PROJECT_PATH' && docker compose -f '$DOCKER_COMPOSE_FILE_PATH' down"; then
        log_info "远程容器已停止"
        return $EXIT_SUCCESS
    else
        log_error "远程容器停止失败"
        return $EXIT_FAILURE
    fi
}

docker_remote_logs() {
    local service=${1:-$DEFAULT_DOCKER_SERVICE_NAME}
    
    if ! check_ssh_connection; then
        return $EXIT_FAILURE
    fi
    
    ssh "$SSH_ALIAS" "cd '$REMOTE_PROJECT_PATH' && docker compose -f '$DOCKER_COMPOSE_FILE_PATH' logs -f '$service'"
}

# 容器状态检查
docker_status() {
    log_debug "本地Docker状态"
    docker_local_status
    echo
    log_debug "远程Docker状态"
    docker_remote_status
}

docker_local_status() {
    if check_docker; then
        local project_root=$(get_project_root)
        cd "$project_root"
        
        local containers=$(docker compose -f "$DOCKER_COMPOSE_FILE_PATH" ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}")
        if [ -n "$containers" ]; then
            log_debug "本地容器:"
            echo "$containers"
        else
            log_warn "无运行容器"
        fi
    else
        log_error "Docker未运行"
    fi
}

docker_remote_status() {
    if check_ssh_connection && check_remote_docker; then
        local containers=$(ssh "$SSH_ALIAS" "cd '$REMOTE_PROJECT_PATH' && docker compose -f '$DOCKER_COMPOSE_FILE_PATH' ps --format 'table {{.Name}}\t{{.Status}}\t{{.Ports}}'")
        if [ -n "$containers" ]; then
            log_debug "远程容器:"
            echo "$containers"
        else
            log_warn "无运行容器"
        fi
    else
        log_error "远程连接失败"
    fi
}

# 重建容器
docker_local_rebuild() {
    log_step "重建本地Docker容器"
    
    docker_local_down
    
    local project_root=$(get_project_root)
    cd "$project_root"
    
    if docker compose -f "$DOCKER_COMPOSE_FILE_PATH" build --no-cache && docker compose -f "$DOCKER_COMPOSE_FILE_PATH" up -d; then
        log_info "本地容器重建成功"
        return $EXIT_SUCCESS
    else
        log_error "本地容器重建失败"
        return $EXIT_FAILURE
    fi
}

docker_remote_rebuild() {
    log_step "重建远程Docker容器"
    
    docker_remote_down
    
    if ssh "$SSH_ALIAS" "cd '$REMOTE_PROJECT_PATH' && docker compose -f '$DOCKER_COMPOSE_FILE_PATH' build --no-cache && docker compose -f '$DOCKER_COMPOSE_FILE_PATH' up -d"; then
        log_info "远程容器重建成功"
        return $EXIT_SUCCESS
    else
        log_error "远程容器重建失败"
        return $EXIT_FAILURE
    fi
}

# 统一重建接口
docker_rebuild() {
    local mode=${1:-"auto"}
    
    case "$mode" in
        "local")
            docker_local_rebuild
            ;;
        "remote")
            docker_remote_rebuild
            ;;
        "auto")
            if check_ssh_connection; then
                docker_remote_rebuild
            else
                docker_local_rebuild
            fi
            ;;
        *)
            log_error "未知模式: $mode"
            return $EXIT_FAILURE
            ;;
    esac
}

# 导出函数
export -f docker_local_up docker_local_down docker_local_logs docker_local_status docker_local_rebuild
export -f docker_remote_up docker_remote_down docker_remote_logs docker_remote_status docker_remote_rebuild
export -f docker_status docker_rebuild 