#!/bin/bash

# =============================================================================
# 配置加密管理系统 - 企业级安全
# =============================================================================

# 获取脚本目录
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"

source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"

# 加密配置
SECRETS_DIR="$CONFIG_DIR/secrets"
ENCRYPTED_CONFIG_FILE="$SECRETS_DIR/config.env.gpg"
DECRYPTED_CONFIG_FILE="$SECRETS_DIR/config.env"
GPG_KEY_ID="dev-environment"

# 初始化加密系统
init_encryption() {
    log_header "初始化配置加密系统"
    
    # 创建secrets目录
    mkdir -p "$SECRETS_DIR"
    
    # 检查GPG
    if ! command -v gpg &> /dev/null; then
        log_info "安装GPG..."
        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew install gnupg
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            sudo apt-get install -y gnupg || sudo yum install -y gnupg
        fi
    fi
    
    # 生成GPG密钥
    if ! gpg --list-keys "$GPG_KEY_ID" &>/dev/null; then
        log_info "生成GPG密钥..."
        
        cat > "$SECRETS_DIR/gpg-batch" << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Dev Environment
Name-Email: dev@localhost
Expire-Date: 1y
Passphrase: $(generate_secure_passphrase)
%commit
EOF
        
        gpg --batch --generate-key "$SECRETS_DIR/gpg-batch"
        rm -f "$SECRETS_DIR/gpg-batch"
        
        log_success "GPG密钥生成完成"
    fi
}

# 生成安全密码
generate_secure_passphrase() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# 加密配置文件
encrypt_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    log_info "加密配置文件: $config_file"
    
    # 备份原文件
    cp "$config_file" "$config_file.backup"
    
    # 加密文件
    gpg --trust-model always --cipher-algo AES256 --compress-algo 1 \
        --output "$ENCRYPTED_CONFIG_FILE" \
        --encrypt --recipient "$GPG_KEY_ID" "$config_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "配置文件加密成功"
        
        # 安全删除原文件
        shred -vfz -n 3 "$config_file" 2>/dev/null || rm -f "$config_file"
        
        return 0
    else
        log_error "配置文件加密失败"
        return 1
    fi
}

# 解密配置文件
decrypt_config() {
    local output_file="${1:-$DECRYPTED_CONFIG_FILE}"
    
    if [[ ! -f "$ENCRYPTED_CONFIG_FILE" ]]; then
        log_error "加密配置文件不存在: $ENCRYPTED_CONFIG_FILE"
        return 1
    fi
    
    log_info "解密配置文件..."
    
    # 解密文件
    gpg --quiet --batch --yes --decrypt "$ENCRYPTED_CONFIG_FILE" > "$output_file"
    
    if [[ $? -eq 0 ]]; then
        log_success "配置文件解密成功"
        
        # 设置安全权限
        chmod 600 "$output_file"
        
        return 0
    else
        log_error "配置文件解密失败"
        return 1
    fi
}

# 安全读取配置
secure_load_config() {
    local temp_config="/tmp/dev-config-$$"
    
    # 解密到临时文件
    if decrypt_config "$temp_config"; then
        # 加载配置
        source "$temp_config"
        
        # 立即删除临时文件
        shred -vfz -n 3 "$temp_config" 2>/dev/null || rm -f "$temp_config"
        
        log_success "安全配置加载完成"
        return 0
    else
        log_error "安全配置加载失败"
        return 1
    fi
}

# 创建加密配置模板
create_encrypted_template() {
    local template_file="$SECRETS_DIR/config.env.template"
    
    log_info "创建加密配置模板..."
    
    cat > "$template_file" << 'EOF'
# =============================================================================
# 加密配置文件模板
# =============================================================================

# SSH配置 (敏感信息)
SSH_PRIVATE_KEY_PATH="~/.ssh/id_rsa"
SSH_PASSPHRASE="your-ssh-passphrase"

# 数据库配置
DB_PASSWORD="your-database-password"
DB_CONNECTION_STRING="postgresql://user:password@host:5432/db"

# API密钥
API_SECRET_KEY="your-api-secret-key"
JWT_SECRET="your-jwt-secret"

# 第三方服务密钥
DOCKER_REGISTRY_PASSWORD="your-registry-password"
CLOUD_ACCESS_KEY="your-cloud-access-key"
CLOUD_SECRET_KEY="your-cloud-secret-key"

# 代理认证
PROXY_USERNAME="your-proxy-username"
PROXY_PASSWORD="your-proxy-password"

# 通知服务
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."
EMAIL_SMTP_PASSWORD="your-email-password"
EOF
    
    log_success "加密配置模板创建完成: $template_file"
}

# 轮换加密密钥
rotate_encryption_key() {
    log_header "轮换加密密钥"
    
    local old_key_id="$GPG_KEY_ID"
    local new_key_id="$GPG_KEY_ID-$(date +%Y%m%d)"
    
    # 生成新密钥
    log_info "生成新的加密密钥..."
    
    cat > "$SECRETS_DIR/new-gpg-batch" << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: Dev Environment New
Name-Email: dev-new@localhost
Expire-Date: 1y
Passphrase: $(generate_secure_passphrase)
%commit
EOF
    
    gpg --batch --generate-key "$SECRETS_DIR/new-gpg-batch"
    rm -f "$SECRETS_DIR/new-gpg-batch"
    
    # 重新加密配置
    if [[ -f "$ENCRYPTED_CONFIG_FILE" ]]; then
        log_info "使用新密钥重新加密配置..."
        
        # 解密
        local temp_config="/tmp/dev-reencrypt-$$"
        decrypt_config "$temp_config"
        
        # 使用新密钥加密
        GPG_KEY_ID="$new_key_id"
        encrypt_config "$temp_config"
        
        # 清理
        shred -vfz -n 3 "$temp_config" 2>/dev/null || rm -f "$temp_config"
    fi
    
    log_success "密钥轮换完成"
}

# 安全审计
security_audit() {
    log_header "安全审计"
    
    local audit_issues=0
    
    # 检查文件权限
    log_info "检查文件权限..."
    
    if [[ -f "$DECRYPTED_CONFIG_FILE" ]]; then
        local perms=$(stat -c %a "$DECRYPTED_CONFIG_FILE" 2>/dev/null || stat -f %A "$DECRYPTED_CONFIG_FILE" 2>/dev/null)
        if [[ "$perms" != "600" ]]; then
            log_warning "解密配置文件权限不安全: $perms"
            ((audit_issues++))
        fi
    fi
    
    # 检查GPG密钥
    log_info "检查GPG密钥..."
    
    local key_info=$(gpg --list-keys "$GPG_KEY_ID" 2>/dev/null)
    if [[ -z "$key_info" ]]; then
        log_warning "GPG密钥不存在"
        ((audit_issues++))
    fi
    
    # 检查临时文件
    log_info "检查临时文件泄露..."
    
    local temp_files=$(find /tmp -name "*dev-config*" -o -name "*dev-reencrypt*" 2>/dev/null)
    if [[ -n "$temp_files" ]]; then
        log_warning "发现临时配置文件泄露"
        echo "$temp_files"
        ((audit_issues++))
    fi
    
    # 审计结果
    if [[ $audit_issues -eq 0 ]]; then
        log_success "安全审计通过"
    else
        log_error "发现 $audit_issues 个安全问题"
    fi
    
    return $audit_issues
}

# 清理敏感数据
cleanup_sensitive_data() {
    log_header "清理敏感数据"
    
    # 清理解密的配置文件
    if [[ -f "$DECRYPTED_CONFIG_FILE" ]]; then
        shred -vfz -n 3 "$DECRYPTED_CONFIG_FILE" 2>/dev/null || rm -f "$DECRYPTED_CONFIG_FILE"
        log_info "清理解密配置文件"
    fi
    
    # 清理临时文件
    find /tmp -name "*dev-config*" -o -name "*dev-reencrypt*" 2>/dev/null | while read file; do
        shred -vfz -n 3 "$file" 2>/dev/null || rm -f "$file"
        log_info "清理临时文件: $file"
    done
    
    # 清理shell历史中的敏感命令
    history -c
    
    log_success "敏感数据清理完成"
}

# 导出函数
export -f init_encryption encrypt_config decrypt_config secure_load_config
export -f create_encrypted_template rotate_encryption_key security_audit cleanup_sensitive_data 