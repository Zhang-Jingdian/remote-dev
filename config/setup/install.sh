#!/bin/bash

# =============================================================================
# 远程开发环境安装脚本
# =============================================================================

set -e

# 加载核心库
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../core/lib.sh"

# 安装主函数
main() {
    log_step "开始安装远程开发环境"
    
    # 检查依赖
    check_dependencies
    
    # 设置shell别名
    setup_shell_aliases
    
    # 创建符号链接
    create_symlinks
    
    # 配置完成
    log_info "安装完成！"
    show_usage
}

# 检查依赖
check_dependencies() {
    log_step "检查系统依赖"
    
    local missing_deps=()
    local deps=("docker" "rsync" "ssh" "curl")
    
    for dep in "${deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "请安装缺少的依赖后重试"
        exit 1
    fi
    
    log_info "所有依赖已安装"
}

# 设置shell别名
setup_shell_aliases() {
    log_step "设置Shell别名"
    
    local project_root=$(get_project_root)
    local zshrc="$HOME/.zshrc"
    local zprofile="$HOME/.zprofile"
    
    # 备份现有文件
    [ -f "$zshrc" ] && cp "$zshrc" "$zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    [ -f "$zprofile" ] && cp "$zprofile" "$zprofile.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 添加环境变量到 .zprofile
    if ! grep -q "# Remote Dev Environment" "$zprofile" 2>/dev/null; then
        cat >> "$zprofile" << EOF

# Remote Dev Environment
export REMOTE_DEV_ROOT="$project_root"
export PATH="\$REMOTE_DEV_ROOT:\$PATH"
EOF
        log_info "环境变量已添加到 ~/.zprofile"
    fi
    
    # 添加别名到 .zshrc
    if ! grep -q "# Remote Dev Aliases" "$zshrc" 2>/dev/null; then
        cat >> "$zshrc" << EOF

# Remote Dev Aliases
alias dev="$project_root/dev"
alias devsync="$project_root/dev sync"
alias devup="$project_root/dev up"
alias devdown="$project_root/dev down"
alias devlogs="$project_root/dev logs"
alias devstatus="$project_root/dev status"
EOF
        log_info "别名已添加到 ~/.zshrc"
    fi
    
    log_info "Shell配置完成"
}

# 创建符号链接
create_symlinks() {
    log_step "创建符号链接"
    
    local project_root=$(get_project_root)
    
    # 创建docker-compose.yml符号链接
    local compose_link="$project_root/docker-compose.yml"
    local compose_target="config/docker/docker-compose.yml"
    
    if [ ! -L "$compose_link" ]; then
        ln -sf "$compose_target" "$compose_link"
        log_info "创建符号链接: docker-compose.yml"
    fi
    
    # 创建Dockerfile符号链接
    local dockerfile_link="$project_root/Dockerfile"
    local dockerfile_target="config/docker/Dockerfile"
    
    if [ ! -L "$dockerfile_link" ]; then
        ln -sf "$dockerfile_target" "$dockerfile_link"
        log_info "创建符号链接: Dockerfile"
    fi
}

# 显示使用说明
show_usage() {
    cat << EOF

🎉 安装完成！

要激活新的环境，请运行：
  source ~/.zprofile
  source ~/.zshrc

或者重新打开终端。

常用命令：
  dev setup          # 一键设置开发环境
  dev status          # 查看系统状态
  dev tunnel start    # 启动SSH隧道
  dev sync            # 同步代码
  dev up              # 启动容器
  dev logs            # 查看日志

完整帮助：
  dev help

EOF
}

# 运行主函数
main "$@" 