#!/bin/bash

# 安全加固系统
# 提供全面的安全检查、配置加密、访问控制和安全监控功能

# 加载基础库
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"
source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"
source "$SCRIPT_DIR/security/security_config.sh"

# 安全检查配置
SECURITY_LOG_DIR="$SCRIPT_DIR/logs/security"
SECURITY_REPORT_DIR="$SCRIPT_DIR/reports/security"
SECURITY_SCHEDULE_FILE="$SCRIPT_DIR/config/security_schedule.conf"

# 确保目录存在
ensure_dir "$SECURITY_LOG_DIR"
ensure_dir "$SECURITY_REPORT_DIR"

# 系统安全检查
check_system_security() {
    log_step "执行系统安全检查"
    
    local report_file="$SECURITY_REPORT_DIR/system_security_$(date +%Y%m%d_%H%M%S).json"
    local issues=()
    
    # 检查SSH配置
    log_info "检查SSH配置安全性..."
    local ssh_issues=$(check_ssh_security)
    if [ -n "$ssh_issues" ]; then
        issues+=("SSH配置存在安全风险: $ssh_issues")
    fi
    
    # 检查文件权限
    log_info "检查关键文件权限..."
    local perm_issues=$(check_file_permissions)
    if [ -n "$perm_issues" ]; then
        issues+=("文件权限不安全: $perm_issues")
    fi
    
    # 检查密码策略
    log_info "检查密码策略..."
    local pwd_issues=$(check_password_policy)
    if [ -n "$pwd_issues" ]; then
        issues+=("密码策略不符合要求: $pwd_issues")
    fi
    
    # 检查网络安全
    log_info "检查网络安全配置..."
    local net_issues=$(check_network_security)
    if [ -n "$net_issues" ]; then
        issues+=("网络安全配置问题: $net_issues")
    fi
    
    # 检查加密配置
    log_info "检查加密配置..."
    local enc_issues=$(check_encryption_config)
    if [ -n "$enc_issues" ]; then
        issues+=("加密配置问题: $enc_issues")
    fi
    
    # 生成报告
    generate_security_report "$report_file" "${issues[@]}"
    
    if [ ${#issues[@]} -eq 0 ]; then
        log_info "✅ 系统安全检查通过"
        return 0
    else
        log_warn "⚠️ 发现 ${#issues[@]} 个安全问题"
        return 1
    fi
}

# SSH安全检查
check_ssh_security() {
    local issues=""
    
    # 检查SSH配置文件
    if [ -f ~/.ssh/config ]; then
        # 检查密钥类型
        if grep -q "IdentityFile.*rsa" ~/.ssh/config; then
            issues+="使用RSA密钥(建议使用Ed25519); "
        fi
        
        # 检查端口配置
        if ! grep -q "Port" ~/.ssh/config; then
            issues+="未配置非标准端口; "
        fi
        
        # 检查密钥权限
        local key_files=$(grep "IdentityFile" ~/.ssh/config | awk '{print $2}' | sed 's/~/$HOME/g')
        for key_file in $key_files; do
            if [ -f "$key_file" ]; then
                local perms=$(stat -c %a "$key_file" 2>/dev/null || stat -f %A "$key_file" 2>/dev/null)
                if [ "$perms" != "600" ]; then
                    issues+="密钥文件权限不安全($key_file: $perms); "
                fi
            fi
        done
    fi
    
    echo "$issues"
}

# 文件权限检查
check_file_permissions() {
    local issues=""
    
    # 检查关键配置文件权限
    local config_files=(
        "$SCRIPT_DIR/constants.sh"
        "$SCRIPT_DIR/config.env"
        "$SCRIPT_DIR/security/security_config.sh"
    )
    
    for file in "${config_files[@]}"; do
        if [ -f "$file" ]; then
            local perms=$(stat -c %a "$file" 2>/dev/null || stat -f %A "$file" 2>/dev/null)
            if [ "$perms" -gt 644 ]; then
                issues+="配置文件权限过宽($file: $perms); "
            fi
        fi
    done
    
    # 检查脚本文件权限
    local script_files=$(find "$SCRIPT_DIR" -name "*.sh" -type f)
    for file in $script_files; do
        local perms=$(stat -c %a "$file" 2>/dev/null || stat -f %A "$file" 2>/dev/null)
        if [ "$perms" -gt 755 ]; then
            issues+="脚本文件权限过宽($file: $perms); "
        fi
    done
    
    echo "$issues"
}

# 密码策略检查
check_password_policy() {
    local issues=""
    
    # 检查环境变量中的密码
    if env | grep -i "password\|passwd\|pwd" | grep -v "PWD=" >/dev/null 2>&1; then
        issues+="环境变量中包含密码; "
    fi
    
    # 检查配置文件中的明文密码
    local config_files=$(find "$SCRIPT_DIR" -name "*.env" -o -name "*.conf" -o -name "*.config")
    for file in $config_files; do
        if [ -f "$file" ]; then
            if grep -i "password\|passwd" "$file" | grep -v "^#" >/dev/null 2>&1; then
                issues+="配置文件包含明文密码($file); "
            fi
        fi
    done
    
    echo "$issues"
}

# 网络安全检查
check_network_security() {
    local issues=""
    
    # 检查开放端口
    if command_exists netstat; then
        local open_ports=$(netstat -tuln | grep LISTEN | wc -l)
        if [ "$open_ports" -gt 10 ]; then
            issues+="开放端口过多($open_ports个); "
        fi
    fi
    
    # 检查防火墙状态
    if command_exists ufw; then
        if ! ufw status | grep -q "Status: active"; then
            issues+="防火墙未启用; "
        fi
    elif command_exists firewall-cmd; then
        if ! firewall-cmd --state | grep -q "running"; then
            issues+="防火墙未运行; "
        fi
    fi
    
    echo "$issues"
}

# 加密配置检查
check_encryption_config() {
    local issues=""
    
    # 检查加密配置是否初始化
    if [ ! -f "$SCRIPT_DIR/security/.encryption_initialized" ]; then
        issues+="加密系统未初始化; "
    fi
    
    # 检查加密文件权限
    local enc_files=$(find "$SCRIPT_DIR" -name "*.enc" -type f)
    for file in $enc_files; do
        local perms=$(stat -c %a "$file" 2>/dev/null || stat -f %A "$file" 2>/dev/null)
        if [ "$perms" -gt 600 ]; then
            issues+="加密文件权限不安全($file: $perms); "
        fi
    done
    
    echo "$issues"
}

# 生成安全报告
generate_security_report() {
    local report_file="$1"
    shift
    local issues=("$@")
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local hostname=$(hostname)
    local user=$(whoami)
    
    cat > "$report_file" << EOF
{
    "timestamp": "$timestamp",
    "hostname": "$hostname",
    "user": "$user",
    "scan_type": "system_security",
    "status": "$([ ${#issues[@]} -eq 0 ] && echo "PASS" || echo "FAIL")",
    "issues_count": ${#issues[@]},
    "issues": [
$(for issue in "${issues[@]}"; do
    echo "        \"$issue\","
done | sed '$ s/,$//')
    ],
    "recommendations": [
        "定期更新系统和软件包",
        "使用强密码和多因素认证",
        "限制不必要的网络访问",
        "定期备份重要数据",
        "监控系统日志和异常活动"
    ]
}
EOF
    
    log_info "安全报告已生成: $report_file"
}

# 自动修复安全问题
auto_fix_security_issues() {
    log_step "自动修复安全问题"
    
    # 修复文件权限
    log_info "修复文件权限..."
    find "$SCRIPT_DIR" -name "*.sh" -type f -exec chmod 755 {} \;
    find "$SCRIPT_DIR" -name "*.env" -type f -exec chmod 600 {} \;
    find "$SCRIPT_DIR" -name "*.conf" -type f -exec chmod 644 {} \;
    
    # 修复SSH密钥权限
    if [ -d ~/.ssh ]; then
        chmod 700 ~/.ssh
        find ~/.ssh -name "id_*" -not -name "*.pub" -exec chmod 600 {} \;
        find ~/.ssh -name "*.pub" -exec chmod 644 {} \;
    fi
    
    # 清理临时文件
    find "$SCRIPT_DIR" -name "*.tmp" -type f -delete
    find "$SCRIPT_DIR" -name "*.log" -type f -mtime +30 -delete
    
    log_info "自动修复完成"
}

# 配置定期安全检查
setup_security_schedule() {
    log_step "配置定期安全检查"
    
    # 创建调度配置
    cat > "$SECURITY_SCHEDULE_FILE" << EOF
# 安全检查调度配置
# 格式: 检查类型 频率 时间

# 系统安全检查 - 每天凌晨2点
system_security daily 02:00

# 权限检查 - 每周一凌晨3点
permission_check weekly 03:00

# 加密检查 - 每月1号凌晨4点
encryption_check monthly 04:00

# 网络安全检查 - 每天凌晨1点
network_security daily 01:00
EOF
    
    # 创建cron任务
    local cron_file="/tmp/security_cron"
    cat > "$cron_file" << EOF
# 安全检查定时任务
0 2 * * * $SCRIPT_DIR/security/security_hardening.sh check_system_security
0 3 * * 1 $SCRIPT_DIR/security/security_hardening.sh check_file_permissions
0 4 1 * * $SCRIPT_DIR/security/security_hardening.sh check_encryption_config
0 1 * * * $SCRIPT_DIR/security/security_hardening.sh check_network_security
EOF
    
    # 安装cron任务
    if command_exists crontab; then
        crontab -l 2>/dev/null | grep -v "security_hardening.sh" > /tmp/current_cron
        cat /tmp/current_cron "$cron_file" | crontab -
        rm -f /tmp/current_cron "$cron_file"
        log_info "定期安全检查已配置"
    else
        log_warn "crontab不可用，请手动配置定期任务"
    fi
}

# 安全监控
security_monitor() {
    log_step "启动安全监控"
    
    local monitor_log="$SECURITY_LOG_DIR/monitor_$(date +%Y%m%d).log"
    
    while true; do
        local timestamp=$(date)
        
        # 检查登录失败
        if command_exists journalctl; then
            local failed_logins=$(journalctl -u ssh --since "1 minute ago" | grep -c "Failed password" || echo "0")
            if [ "$failed_logins" -gt 5 ]; then
                echo "[$timestamp] 警告: 检测到大量SSH登录失败 ($failed_logins次)" >> "$monitor_log"
            fi
        fi
        
        # 检查异常进程
        local suspicious_processes=$(ps aux | grep -E "(nc|netcat|nmap|wget|curl)" | grep -v grep | wc -l)
        if [ "$suspicious_processes" -gt 3 ]; then
            echo "[$timestamp] 警告: 检测到可疑进程活动" >> "$monitor_log"
        fi
        
        # 检查磁盘使用率
        local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
        if [ "$disk_usage" -gt 90 ]; then
            echo "[$timestamp] 警告: 磁盘使用率过高 ($disk_usage%)" >> "$monitor_log"
        fi
        
        sleep 60
    done
}

# 安全事件响应
security_incident_response() {
    local incident_type="$1"
    local description="$2"
    
    log_step "安全事件响应: $incident_type"
    
    local incident_log="$SECURITY_LOG_DIR/incidents_$(date +%Y%m%d).log"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # 记录事件
    echo "[$timestamp] 事件类型: $incident_type" >> "$incident_log"
    echo "[$timestamp] 事件描述: $description" >> "$incident_log"
    
    # 根据事件类型采取行动
    case "$incident_type" in
        "login_failure")
            # 临时封禁IP
            log_warn "检测到登录失败，考虑封禁IP"
            ;;
        "privilege_escalation")
            # 锁定账户
            log_error "检测到权限提升，立即锁定相关账户"
            ;;
        "malware_detected")
            # 隔离系统
            log_error "检测到恶意软件，系统需要隔离"
            ;;
        *)
            log_info "未知事件类型，记录并监控"
            ;;
    esac
}

# 主函数
main() {
    case "${1:-help}" in
        "check"|"check_system_security")
            check_system_security
            ;;
        "fix"|"auto_fix")
            auto_fix_security_issues
            ;;
        "schedule"|"setup_schedule")
            setup_security_schedule
            ;;
        "monitor")
            security_monitor
            ;;
        "incident")
            security_incident_response "$2" "$3"
            ;;
        "report")
            ls -la "$SECURITY_REPORT_DIR"
            ;;
        "help"|*)
            echo "安全加固系统 🔒"
            echo ""
            echo "用法: $0 <命令>"
            echo ""
            echo "命令:"
            echo "  check      - 执行系统安全检查"
            echo "  fix        - 自动修复安全问题"
            echo "  schedule   - 配置定期安全检查"
            echo "  monitor    - 启动安全监控"
            echo "  incident   - 安全事件响应"
            echo "  report     - 查看安全报告"
            echo "  help       - 显示帮助信息"
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 