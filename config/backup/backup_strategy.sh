#!/bin/bash

# 备份策略系统
# 提供定期备份、增量备份、远程备份、备份验证和恢复功能

# 加载基础库
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"
source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"

# 备份配置
BACKUP_CONFIG_DIR="$SCRIPT_DIR/backup"
BACKUP_LOG_DIR="$SCRIPT_DIR/logs/backup"
BACKUP_LOCAL_DIR="$SCRIPT_DIR/backups"
BACKUP_REMOTE_DIR="/backup/remote-dev"
BACKUP_CONFIG_FILE="$BACKUP_CONFIG_DIR/backup_config.conf"
BACKUP_SCHEDULE_FILE="$BACKUP_CONFIG_DIR/backup_schedule.conf"

# 确保目录存在
ensure_dir "$BACKUP_CONFIG_DIR"
ensure_dir "$BACKUP_LOG_DIR"
ensure_dir "$BACKUP_LOCAL_DIR"

# 初始化备份策略系统
init_backup_strategy() {
    log_step "初始化备份策略系统"
    
    # 创建备份配置
    create_backup_config
    
    # 创建备份调度配置
    create_backup_schedule
    
    # 创建备份脚本
    create_backup_scripts
    
    # 设置备份定时任务
    setup_backup_cron
    
    log_info "备份策略系统初始化完成"
}

# 创建备份配置
create_backup_config() {
    log_info "创建备份配置..."
    
    cat > "$BACKUP_CONFIG_FILE" << 'EOF'
# 备份配置文件
# 格式: 配置项=值

# 基础配置
BACKUP_ENABLED=true
BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION=true
BACKUP_ENCRYPTION=true
BACKUP_VERIFICATION=true

# 本地备份配置
LOCAL_BACKUP_ENABLED=true
LOCAL_BACKUP_PATH=/backup/local
LOCAL_BACKUP_MAX_SIZE=10G

# 远程备份配置
REMOTE_BACKUP_ENABLED=true
REMOTE_BACKUP_HOST=backup.example.com
REMOTE_BACKUP_USER=backup
REMOTE_BACKUP_PATH=/backup/remote-dev
REMOTE_BACKUP_METHOD=rsync

# 云备份配置
CLOUD_BACKUP_ENABLED=false
CLOUD_BACKUP_PROVIDER=aws
CLOUD_BACKUP_BUCKET=remote-dev-backup
CLOUD_BACKUP_REGION=us-east-1

# 数据库备份配置
DB_BACKUP_ENABLED=false
DB_BACKUP_HOST=localhost
DB_BACKUP_PORT=3306
DB_BACKUP_USER=backup
DB_BACKUP_PASSWORD=backup_password
DB_BACKUP_DATABASES=remote_dev

# 备份类型配置
FULL_BACKUP_FREQUENCY=weekly
INCREMENTAL_BACKUP_FREQUENCY=daily
DIFFERENTIAL_BACKUP_FREQUENCY=never

# 通知配置
BACKUP_NOTIFICATIONS=true
BACKUP_EMAIL_RECIPIENTS=admin@example.com
BACKUP_SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
EOF
    
    log_info "备份配置已创建: $BACKUP_CONFIG_FILE"
}

# 创建备份调度配置
create_backup_schedule() {
    log_info "创建备份调度配置..."
    
    cat > "$BACKUP_SCHEDULE_FILE" << 'EOF'
# 备份调度配置
# 格式: 备份类型 频率 时间 启用状态

# 配置文件备份
config_backup daily 02:00 true
security_backup daily 02:15 true
logs_backup daily 02:30 true

# 代码备份
source_code_backup daily 03:00 true
scripts_backup daily 03:15 true

# 系统备份
system_config_backup weekly 04:00 true
ssh_keys_backup weekly 04:15 true

# 数据库备份
database_backup daily 01:00 false

# 完整备份
full_backup weekly 05:00 true
incremental_backup daily 01:30 true
EOF
    
    log_info "备份调度配置已创建: $BACKUP_SCHEDULE_FILE"
}

# 创建备份脚本
create_backup_scripts() {
    log_info "创建备份脚本..."
    
    # 创建配置备份脚本
    cat > "$BACKUP_CONFIG_DIR/backup_config.sh" << 'EOF'
#!/bin/bash
# 配置文件备份脚本

source "$(dirname "$0")/../constants.sh"
source "$(dirname "$0")/../core/lib.sh"

backup_config_files() {
    local backup_dir="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local config_backup_dir="$backup_dir/config_$timestamp"
    
    ensure_dir "$config_backup_dir"
    
    # 备份配置文件
    cp -r "$SCRIPT_DIR/config" "$config_backup_dir/"
    cp "$SCRIPT_DIR/constants.sh" "$config_backup_dir/"
    [ -f "$SCRIPT_DIR/config.env" ] && cp "$SCRIPT_DIR/config.env" "$config_backup_dir/"
    
    # 创建备份清单
    find "$config_backup_dir" -type f > "$config_backup_dir/backup_manifest.txt"
    
    # 压缩备份
    tar -czf "$backup_dir/config_backup_$timestamp.tar.gz" -C "$backup_dir" "config_$timestamp"
    rm -rf "$config_backup_dir"
    
    echo "$backup_dir/config_backup_$timestamp.tar.gz"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup_config_files "$1"
fi
EOF
    
    # 创建代码备份脚本
    cat > "$BACKUP_CONFIG_DIR/backup_source.sh" << 'EOF'
#!/bin/bash
# 源代码备份脚本

source "$(dirname "$0")/../constants.sh"
source "$(dirname "$0")/../core/lib.sh"

backup_source_code() {
    local backup_dir="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local source_backup_dir="$backup_dir/source_$timestamp"
    
    ensure_dir "$source_backup_dir"
    
    # 备份源代码
    [ -d "$SCRIPT_DIR/src" ] && cp -r "$SCRIPT_DIR/src" "$source_backup_dir/"
    [ -d "$SCRIPT_DIR/web" ] && cp -r "$SCRIPT_DIR/web" "$source_backup_dir/"
    [ -f "$SCRIPT_DIR/README.md" ] && cp "$SCRIPT_DIR/README.md" "$source_backup_dir/"
    
    # 备份重要文件
    [ -f "$SCRIPT_DIR/docker-compose.yml" ] && cp "$SCRIPT_DIR/docker-compose.yml" "$source_backup_dir/"
    [ -f "$SCRIPT_DIR/Dockerfile" ] && cp "$SCRIPT_DIR/Dockerfile" "$source_backup_dir/"
    [ -f "$SCRIPT_DIR/requirements.txt" ] && cp "$SCRIPT_DIR/requirements.txt" "$source_backup_dir/"
    
    # 创建Git信息备份
    if [ -d "$SCRIPT_DIR/.git" ]; then
        git log --oneline -10 > "$source_backup_dir/git_log.txt"
        git status > "$source_backup_dir/git_status.txt"
        git branch -a > "$source_backup_dir/git_branches.txt"
    fi
    
    # 压缩备份
    tar -czf "$backup_dir/source_backup_$timestamp.tar.gz" -C "$backup_dir" "source_$timestamp"
    rm -rf "$source_backup_dir"
    
    echo "$backup_dir/source_backup_$timestamp.tar.gz"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup_source_code "$1"
fi
EOF
    
    # 创建数据库备份脚本
    cat > "$BACKUP_CONFIG_DIR/backup_database.sh" << 'EOF'
#!/bin/bash
# 数据库备份脚本

source "$(dirname "$0")/../constants.sh"
source "$(dirname "$0")/../core/lib.sh"

backup_database() {
    local backup_dir="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    # 读取数据库配置
    source "$BACKUP_CONFIG_FILE"
    
    if [ "$DB_BACKUP_ENABLED" != "true" ]; then
        log_info "数据库备份未启用"
        return 0
    fi
    
    local db_backup_file="$backup_dir/database_backup_$timestamp.sql"
    
    # 备份数据库
    if command_exists mysqldump; then
        mysqldump -h "$DB_BACKUP_HOST" -P "$DB_BACKUP_PORT" \
                  -u "$DB_BACKUP_USER" -p"$DB_BACKUP_PASSWORD" \
                  --all-databases > "$db_backup_file"
    elif command_exists pg_dump; then
        pg_dump -h "$DB_BACKUP_HOST" -p "$DB_BACKUP_PORT" \
                -U "$DB_BACKUP_USER" -d "$DB_BACKUP_DATABASES" > "$db_backup_file"
    else
        log_error "未找到数据库备份工具"
        return 1
    fi
    
    # 压缩备份
    gzip "$db_backup_file"
    
    echo "$db_backup_file.gz"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    backup_database "$1"
fi
EOF
    
    # 设置脚本权限
    chmod +x "$BACKUP_CONFIG_DIR"/*.sh
    
    log_info "备份脚本已创建"
}

# 设置备份定时任务
setup_backup_cron() {
    log_info "设置备份定时任务..."
    
    # 创建cron任务文件
    local cron_file="/tmp/backup_cron"
    cat > "$cron_file" << EOF
# 备份定时任务
# 每日增量备份 - 凌晨1:30
30 1 * * * $SCRIPT_DIR/backup/backup_strategy.sh incremental_backup

# 每日配置备份 - 凌晨2:00
0 2 * * * $SCRIPT_DIR/backup/backup_strategy.sh config_backup

# 每日源代码备份 - 凌晨3:00
0 3 * * * $SCRIPT_DIR/backup/backup_strategy.sh source_backup

# 每周完整备份 - 周日凌晨5:00
0 5 * * 0 $SCRIPT_DIR/backup/backup_strategy.sh full_backup

# 每日清理过期备份 - 凌晨6:00
0 6 * * * $SCRIPT_DIR/backup/backup_strategy.sh cleanup_old_backups
EOF
    
    # 安装cron任务
    if command_exists crontab; then
        crontab -l 2>/dev/null | grep -v "backup_strategy.sh" > /tmp/current_cron
        cat /tmp/current_cron "$cron_file" | crontab -
        rm -f /tmp/current_cron "$cron_file"
        log_info "备份定时任务已配置"
    else
        log_warn "crontab不可用，请手动配置定时任务"
    fi
}

# 执行完整备份
full_backup() {
    log_step "执行完整备份"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_LOCAL_DIR/full_$timestamp"
    local backup_log="$BACKUP_LOG_DIR/full_backup_$timestamp.log"
    
    ensure_dir "$backup_dir"
    
    {
        log_info "开始完整备份..."
        
        # 配置文件备份
        log_info "备份配置文件..."
        local config_backup=$("$BACKUP_CONFIG_DIR/backup_config.sh" "$backup_dir")
        log_info "配置备份完成: $config_backup"
        
        # 源代码备份
        log_info "备份源代码..."
        local source_backup=$("$BACKUP_CONFIG_DIR/backup_source.sh" "$backup_dir")
        log_info "源代码备份完成: $source_backup"
        
        # 数据库备份
        if [ "$DB_BACKUP_ENABLED" = "true" ]; then
            log_info "备份数据库..."
            local db_backup=$("$BACKUP_CONFIG_DIR/backup_database.sh" "$backup_dir")
            log_info "数据库备份完成: $db_backup"
        fi
        
        # 系统配置备份
        backup_system_config "$backup_dir"
        
        # 日志备份
        backup_logs "$backup_dir"
        
        # 创建备份元数据
        create_backup_metadata "$backup_dir" "full"
        
        # 验证备份
        if [ "$BACKUP_VERIFICATION" = "true" ]; then
            verify_backup "$backup_dir"
        fi
        
        # 加密备份
        if [ "$BACKUP_ENCRYPTION" = "true" ]; then
            encrypt_backup "$backup_dir"
        fi
        
        # 上传到远程
        if [ "$REMOTE_BACKUP_ENABLED" = "true" ]; then
            upload_to_remote "$backup_dir"
        fi
        
        # 上传到云端
        if [ "$CLOUD_BACKUP_ENABLED" = "true" ]; then
            upload_to_cloud "$backup_dir"
        fi
        
        log_info "完整备份完成: $backup_dir"
        
        # 发送通知
        if [ "$BACKUP_NOTIFICATIONS" = "true" ]; then
            send_backup_notification "完整备份完成" "备份路径: $backup_dir"
        fi
        
    } 2>&1 | tee "$backup_log"
}

# 执行增量备份
incremental_backup() {
    log_step "执行增量备份"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$BACKUP_LOCAL_DIR/incremental_$timestamp"
    local backup_log="$BACKUP_LOG_DIR/incremental_backup_$timestamp.log"
    local last_backup_file="$BACKUP_LOCAL_DIR/.last_backup_time"
    
    ensure_dir "$backup_dir"
    
    {
        log_info "开始增量备份..."
        
        # 获取上次备份时间
        local last_backup_time
        if [ -f "$last_backup_file" ]; then
            last_backup_time=$(cat "$last_backup_file")
        else
            last_backup_time=$(date -d "1 day ago" +%s)
        fi
        
        # 查找变更文件
        local changed_files=$(find "$SCRIPT_DIR" -type f -newer "$last_backup_file" 2>/dev/null | grep -v ".git" | grep -v "logs" | grep -v "backups")
        
        if [ -z "$changed_files" ]; then
            log_info "没有文件变更，跳过增量备份"
            return 0
        fi
        
        # 备份变更文件
        log_info "备份变更文件..."
        while IFS= read -r file; do
            local rel_path=$(realpath --relative-to="$SCRIPT_DIR" "$file")
            local target_dir="$backup_dir/$(dirname "$rel_path")"
            ensure_dir "$target_dir"
            cp "$file" "$target_dir/"
        done <<< "$changed_files"
        
        # 创建变更列表
        echo "$changed_files" > "$backup_dir/changed_files.txt"
        
        # 创建备份元数据
        create_backup_metadata "$backup_dir" "incremental"
        
        # 更新最后备份时间
        date +%s > "$last_backup_file"
        
        log_info "增量备份完成: $backup_dir"
        
    } 2>&1 | tee "$backup_log"
}

# 备份系统配置
backup_system_config() {
    local backup_dir="$1"
    local system_backup_dir="$backup_dir/system"
    
    ensure_dir "$system_backup_dir"
    
    # 备份SSH配置
    if [ -d ~/.ssh ]; then
        cp -r ~/.ssh "$system_backup_dir/ssh_config"
        # 排除私钥（安全考虑）
        find "$system_backup_dir/ssh_config" -name "id_*" -not -name "*.pub" -delete
    fi
    
    # 备份环境变量
    env > "$system_backup_dir/environment.txt"
    
    # 备份cron任务
    crontab -l > "$system_backup_dir/crontab.txt" 2>/dev/null || echo "No crontab" > "$system_backup_dir/crontab.txt"
    
    # 备份系统信息
    uname -a > "$system_backup_dir/system_info.txt"
    df -h > "$system_backup_dir/disk_usage.txt"
    ps aux > "$system_backup_dir/processes.txt"
    
    log_info "系统配置备份完成"
}

# 备份日志
backup_logs() {
    local backup_dir="$1"
    local logs_backup_dir="$backup_dir/logs"
    
    ensure_dir "$logs_backup_dir"
    
    # 备份应用日志
    if [ -d "$SCRIPT_DIR/logs" ]; then
        # 只备份最近7天的日志
        find "$SCRIPT_DIR/logs" -name "*.log" -mtime -7 -exec cp {} "$logs_backup_dir/" \;
    fi
    
    # 备份系统日志（如果可访问）
    if [ -r /var/log/syslog ]; then
        tail -1000 /var/log/syslog > "$logs_backup_dir/syslog.txt"
    fi
    
    log_info "日志备份完成"
}

# 创建备份元数据
create_backup_metadata() {
    local backup_dir="$1"
    local backup_type="$2"
    local metadata_file="$backup_dir/backup_metadata.json"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local hostname=$(hostname)
    local user=$(whoami)
    local backup_size=$(du -sh "$backup_dir" | cut -f1)
    
    cat > "$metadata_file" << EOF
{
    "backup_type": "$backup_type",
    "timestamp": "$timestamp",
    "hostname": "$hostname",
    "user": "$user",
    "backup_size": "$backup_size",
    "backup_path": "$backup_dir",
    "script_version": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
    "system_info": {
        "os": "$(uname -s)",
        "kernel": "$(uname -r)",
        "architecture": "$(uname -m)"
    }
}
EOF
    
    log_info "备份元数据已创建"
}

# 验证备份
verify_backup() {
    local backup_dir="$1"
    
    log_info "验证备份完整性..."
    
    # 检查备份目录是否存在
    if [ ! -d "$backup_dir" ]; then
        log_error "备份目录不存在: $backup_dir"
        return 1
    fi
    
    # 检查备份文件
    local backup_files=$(find "$backup_dir" -type f | wc -l)
    if [ "$backup_files" -eq 0 ]; then
        log_error "备份目录为空"
        return 1
    fi
    
    # 验证压缩文件
    local tar_files=$(find "$backup_dir" -name "*.tar.gz")
    for tar_file in $tar_files; do
        if ! tar -tzf "$tar_file" >/dev/null 2>&1; then
            log_error "压缩文件损坏: $tar_file"
            return 1
        fi
    done
    
    # 计算校验和
    find "$backup_dir" -type f -exec md5sum {} \; > "$backup_dir/checksums.md5"
    
    log_info "备份验证完成"
    return 0
}

# 加密备份
encrypt_backup() {
    local backup_dir="$1"
    
    log_info "加密备份..."
    
    # 使用GPG加密
    if command_exists gpg; then
        local encrypted_file="$backup_dir.gpg"
        tar -czf - -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")" | \
            gpg --symmetric --cipher-algo AES256 --output "$encrypted_file"
        
        if [ $? -eq 0 ]; then
            rm -rf "$backup_dir"
            log_info "备份加密完成: $encrypted_file"
        else
            log_error "备份加密失败"
            return 1
        fi
    else
        log_warn "GPG不可用，跳过加密"
    fi
}

# 上传到远程服务器
upload_to_remote() {
    local backup_dir="$1"
    
    log_info "上传备份到远程服务器..."
    
    # 读取远程备份配置
    source "$BACKUP_CONFIG_FILE"
    
    # 确保远程目录存在
    ssh "$REMOTE_BACKUP_USER@$REMOTE_BACKUP_HOST" "mkdir -p $REMOTE_BACKUP_PATH"
    
    # 上传备份
    if [ "$REMOTE_BACKUP_METHOD" = "rsync" ]; then
        rsync -avz --progress "$backup_dir" "$REMOTE_BACKUP_USER@$REMOTE_BACKUP_HOST:$REMOTE_BACKUP_PATH/"
    elif [ "$REMOTE_BACKUP_METHOD" = "scp" ]; then
        scp -r "$backup_dir" "$REMOTE_BACKUP_USER@$REMOTE_BACKUP_HOST:$REMOTE_BACKUP_PATH/"
    fi
    
    if [ $? -eq 0 ]; then
        log_info "远程备份上传完成"
    else
        log_error "远程备份上传失败"
        return 1
    fi
}

# 上传到云端
upload_to_cloud() {
    local backup_dir="$1"
    
    log_info "上传备份到云端..."
    
    # 读取云备份配置
    source "$BACKUP_CONFIG_FILE"
    
    case "$CLOUD_BACKUP_PROVIDER" in
        "aws")
            if command_exists aws; then
                aws s3 sync "$backup_dir" "s3://$CLOUD_BACKUP_BUCKET/$(basename "$backup_dir")"
            else
                log_error "AWS CLI未安装"
                return 1
            fi
            ;;
        "gcp")
            if command_exists gsutil; then
                gsutil -m cp -r "$backup_dir" "gs://$CLOUD_BACKUP_BUCKET/"
            else
                log_error "Google Cloud SDK未安装"
                return 1
            fi
            ;;
        "azure")
            if command_exists az; then
                az storage blob upload-batch --destination "$CLOUD_BACKUP_BUCKET" --source "$backup_dir"
            else
                log_error "Azure CLI未安装"
                return 1
            fi
            ;;
        *)
            log_error "不支持的云备份提供商: $CLOUD_BACKUP_PROVIDER"
            return 1
            ;;
    esac
    
    log_info "云端备份上传完成"
}

# 清理过期备份
cleanup_old_backups() {
    log_step "清理过期备份"
    
    # 读取配置
    source "$BACKUP_CONFIG_FILE"
    
    # 清理本地备份
    log_info "清理本地过期备份..."
    find "$BACKUP_LOCAL_DIR" -type d -name "full_*" -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} \;
    find "$BACKUP_LOCAL_DIR" -type d -name "incremental_*" -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} \;
    
    # 清理远程备份
    if [ "$REMOTE_BACKUP_ENABLED" = "true" ]; then
        log_info "清理远程过期备份..."
        ssh "$REMOTE_BACKUP_USER@$REMOTE_BACKUP_HOST" \
            "find $REMOTE_BACKUP_PATH -type d -name 'full_*' -mtime +$BACKUP_RETENTION_DAYS -exec rm -rf {} \;"
    fi
    
    log_info "过期备份清理完成"
}

# 恢复备份
restore_backup() {
    local backup_path="$1"
    local restore_target="${2:-$SCRIPT_DIR}"
    
    log_step "恢复备份: $backup_path"
    
    if [ ! -e "$backup_path" ]; then
        log_error "备份文件不存在: $backup_path"
        return 1
    fi
    
    # 创建恢复目录
    local restore_dir="$restore_target/restore_$(date +%Y%m%d_%H%M%S)"
    ensure_dir "$restore_dir"
    
    # 解压备份
    if [[ "$backup_path" == *.tar.gz ]]; then
        tar -xzf "$backup_path" -C "$restore_dir"
    elif [[ "$backup_path" == *.gpg ]]; then
        # 解密并解压
        gpg --decrypt "$backup_path" | tar -xzf - -C "$restore_dir"
    elif [ -d "$backup_path" ]; then
        cp -r "$backup_path"/* "$restore_dir/"
    else
        log_error "不支持的备份格式"
        return 1
    fi
    
    # 验证恢复
    if [ -f "$restore_dir/backup_metadata.json" ]; then
        log_info "备份恢复完成: $restore_dir"
        log_info "备份元数据:"
        cat "$restore_dir/backup_metadata.json"
    else
        log_warn "未找到备份元数据"
    fi
    
    return 0
}

# 列出可用备份
list_backups() {
    log_step "列出可用备份"
    
    log_info "本地备份:"
    find "$BACKUP_LOCAL_DIR" -maxdepth 1 -type d -name "*_*" | sort | while read backup_dir; do
        if [ -f "$backup_dir/backup_metadata.json" ]; then
            local backup_type=$(jq -r '.backup_type' "$backup_dir/backup_metadata.json" 2>/dev/null || echo "unknown")
            local timestamp=$(jq -r '.timestamp' "$backup_dir/backup_metadata.json" 2>/dev/null || echo "unknown")
            local size=$(jq -r '.backup_size' "$backup_dir/backup_metadata.json" 2>/dev/null || echo "unknown")
            log_info "  $(basename "$backup_dir") - 类型: $backup_type, 时间: $timestamp, 大小: $size"
        else
            log_info "  $(basename "$backup_dir") - 无元数据"
        fi
    done
    
    # 列出远程备份
    if [ "$REMOTE_BACKUP_ENABLED" = "true" ]; then
        log_info "远程备份:"
        ssh "$REMOTE_BACKUP_USER@$REMOTE_BACKUP_HOST" "ls -la $REMOTE_BACKUP_PATH" 2>/dev/null || log_warn "无法访问远程备份"
    fi
}

# 发送备份通知
send_backup_notification() {
    local title="$1"
    local message="$2"
    
    # 读取配置
    source "$BACKUP_CONFIG_FILE"
    
    # 发送邮件通知
    if [ -n "$BACKUP_EMAIL_RECIPIENTS" ]; then
        echo "$message" | mail -s "$title" "$BACKUP_EMAIL_RECIPIENTS" 2>/dev/null
    fi
    
    # 发送Slack通知
    if [ -n "$BACKUP_SLACK_WEBHOOK" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$title\n$message\"}" \
            "$BACKUP_SLACK_WEBHOOK" 2>/dev/null
    fi
}

# 主函数
main() {
    case "${1:-help}" in
        "init")
            init_backup_strategy
            ;;
        "full_backup")
            full_backup
            ;;
        "incremental_backup")
            incremental_backup
            ;;
        "config_backup")
            "$BACKUP_CONFIG_DIR/backup_config.sh" "$BACKUP_LOCAL_DIR"
            ;;
        "source_backup")
            "$BACKUP_CONFIG_DIR/backup_source.sh" "$BACKUP_LOCAL_DIR"
            ;;
        "database_backup")
            "$BACKUP_CONFIG_DIR/backup_database.sh" "$BACKUP_LOCAL_DIR"
            ;;
        "cleanup_old_backups")
            cleanup_old_backups
            ;;
        "restore")
            restore_backup "$2" "$3"
            ;;
        "list")
            list_backups
            ;;
        "verify")
            verify_backup "$2"
            ;;
        "help"|*)
            echo "备份策略系统 💾"
            echo ""
            echo "用法: $0 <命令> [参数]"
            echo ""
            echo "命令:"
            echo "  init                - 初始化备份策略系统"
            echo "  full_backup         - 执行完整备份"
            echo "  incremental_backup  - 执行增量备份"
            echo "  config_backup       - 备份配置文件"
            echo "  source_backup       - 备份源代码"
            echo "  database_backup     - 备份数据库"
            echo "  cleanup_old_backups - 清理过期备份"
            echo "  restore <path>      - 恢复备份"
            echo "  list                - 列出可用备份"
            echo "  verify <path>       - 验证备份"
            echo "  help                - 显示帮助信息"
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 