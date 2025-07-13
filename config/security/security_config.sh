#!/bin/bash

# =============================================================================
# 安全配置管理系统 - 企业级安全解决方案
# =============================================================================

# 获取脚本目录
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"

source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"

# 安全配置常量
SECURITY_DIR="$CONFIG_DIR/security"
VAULT_DIR="$SECURITY_DIR/vault"
KEYS_DIR="$SECURITY_DIR/keys"
ENCRYPTED_DIR="$SECURITY_DIR/encrypted"
AUDIT_LOG="$SECURITY_DIR/audit.log"

# 创建安全目录结构
init_security_structure() {
    log_header "初始化安全目录结构"
    
    # 创建目录
    mkdir -p "$VAULT_DIR" "$KEYS_DIR" "$ENCRYPTED_DIR"
    
    # 设置严格权限
    chmod 700 "$SECURITY_DIR"
    chmod 700 "$VAULT_DIR"
    chmod 700 "$KEYS_DIR"
    chmod 755 "$ENCRYPTED_DIR"
    
    # 创建审计日志
    touch "$AUDIT_LOG"
    chmod 600 "$AUDIT_LOG"
    
    log_success "安全目录结构初始化完成"
}

# 生成安全密钥
generate_master_key() {
    local key_file="$KEYS_DIR/master.key"
    
    if [[ -f "$key_file" ]]; then
        log_warning "主密钥已存在，跳过生成"
        return 0
    fi
    
    log_info "生成主密钥..."
    
    # 使用多种熵源生成高强度密钥
    {
        date +%s%N
        cat /dev/urandom | head -c 1024 | base64
        ps aux | sha256sum
        df -h | sha256sum
        uname -a | sha256sum
    } | sha256sum | cut -d' ' -f1 > "$key_file"
    
    chmod 600 "$key_file"
    log_success "主密钥生成完成"
    audit_log "MASTER_KEY_GENERATED" "主密钥已生成"
}

# 配置加密
encrypt_config() {
    local config_file="$1"
    local encrypted_file="$ENCRYPTED_DIR/$(basename "$config_file").enc"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    log_info "加密配置文件: $(basename "$config_file")"
    
    # 使用AES-256-GCM加密
    openssl enc -aes-256-gcm -salt -in "$config_file" \
        -out "$encrypted_file" \
        -pass file:"$KEYS_DIR/master.key" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        log_success "配置文件加密成功"
        audit_log "CONFIG_ENCRYPTED" "配置文件已加密: $(basename "$config_file")"
        return 0
    else
        log_error "配置文件加密失败"
        return 1
    fi
}

# 配置解密
decrypt_config() {
    local encrypted_file="$1"
    local output_file="$2"
    
    if [[ ! -f "$encrypted_file" ]]; then
        log_error "加密文件不存在: $encrypted_file"
        return 1
    fi
    
    log_info "解密配置文件: $(basename "$encrypted_file")"
    
    # 解密到临时文件
    local temp_file=$(mktemp)
    openssl enc -aes-256-gcm -d -salt -in "$encrypted_file" \
        -out "$temp_file" \
        -pass file:"$KEYS_DIR/master.key" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        mv "$temp_file" "$output_file"
        chmod 600 "$output_file"
        log_success "配置文件解密成功"
        audit_log "CONFIG_DECRYPTED" "配置文件已解密: $(basename "$encrypted_file")"
        return 0
    else
        rm -f "$temp_file"
        log_error "配置文件解密失败"
        return 1
    fi
}

# 安全配置验证
validate_security() {
    log_header "安全配置验证"
    
    local issues=0
    
    # 检查目录权限
    if [[ $(stat -c %a "$SECURITY_DIR" 2>/dev/null || stat -f %A "$SECURITY_DIR") != "700" ]]; then
        log_warning "安全目录权限不正确"
        ((issues++))
    fi
    
    # 检查主密钥
    if [[ ! -f "$KEYS_DIR/master.key" ]]; then
        log_warning "主密钥不存在"
        ((issues++))
    fi
    
    # 检查配置文件权限
    find "$CONFIG_DIR" -name "*.env" -type f | while read -r file; do
        if [[ $(stat -c %a "$file" 2>/dev/null || stat -f %A "$file") != "600" ]]; then
            log_warning "配置文件权限不安全: $file"
            ((issues++))
        fi
    done
    
    if [[ $issues -eq 0 ]]; then
        log_success "安全配置验证通过"
    else
        log_error "发现 $issues 个安全问题"
    fi
    
    return $issues
}

# 审计日志
audit_log() {
    local action="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local user=$(whoami)
    
    echo "[$timestamp] [$user] [$action] $message" >> "$AUDIT_LOG"
}

# 安全清理
security_cleanup() {
    log_header "安全清理"
    
    # 清理临时文件
    find /tmp -name "*dev-env*" -type f -delete 2>/dev/null
    
    # 清理历史记录中的敏感信息
    if [[ -f ~/.bash_history ]]; then
        sed -i.bak '/password\|secret\|key\|token/d' ~/.bash_history
    fi
    
    # 清理core dumps
    find /tmp -name "core.*" -delete 2>/dev/null
    
    log_success "安全清理完成"
    audit_log "SECURITY_CLEANUP" "执行安全清理"
}

# 权限管理
manage_permissions() {
    log_header "权限管理"
    
    # 设置配置文件权限
    find "$CONFIG_DIR" -name "*.env" -type f -exec chmod 600 {} \;
    find "$CONFIG_DIR" -name "*.sh" -type f -exec chmod 755 {} \;
    
    # 设置密钥文件权限
    find "$KEYS_DIR" -type f -exec chmod 600 {} \;
    
    # 设置目录权限
    find "$CONFIG_DIR" -type d -exec chmod 755 {} \;
    chmod 700 "$SECURITY_DIR"
    
    log_success "权限管理完成"
}

# 主函数
main() {
    case "$1" in
        "init")
            init_security_structure
            generate_master_key
            ;;
        "encrypt")
            encrypt_config "$2"
            ;;
        "decrypt")
            decrypt_config "$2" "$3"
            ;;
        "validate")
            validate_security
            ;;
        "cleanup")
            security_cleanup
            ;;
        "permissions")
            manage_permissions
            ;;
        *)
            echo "用法: $0 {init|encrypt|decrypt|validate|cleanup|permissions}"
            exit 1
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 