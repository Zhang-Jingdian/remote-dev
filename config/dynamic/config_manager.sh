#!/bin/bash

# =============================================================================
# 动态配置管理系统 - 热更新配置
# =============================================================================

# 获取脚本目录
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"

source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"

# 动态配置系统配置
DYNAMIC_CONFIG_DIR="$CONFIG_DIR/dynamic"
CONFIG_HISTORY_DIR="$DYNAMIC_CONFIG_DIR/history"
CONFIG_SCHEMAS_DIR="$DYNAMIC_CONFIG_DIR/schemas"
CONFIG_WATCHERS_DIR="$DYNAMIC_CONFIG_DIR/watchers"
ACTIVE_CONFIG_FILE="$DYNAMIC_CONFIG_DIR/active.json"
CONFIG_LOCK_FILE="/tmp/config-manager.lock"

# 初始化动态配置系统
init_dynamic_config() {
    log_header "初始化动态配置系统"
    
    # 创建目录结构
    mkdir -p "$DYNAMIC_CONFIG_DIR"/{history,schemas,watchers,templates}
    
    # 创建配置架构
    create_config_schemas
    
    # 创建活跃配置文件
    create_active_config
    
    # 启动配置监控
    start_config_watcher
    
    log_success "动态配置系统初始化完成"
}

# 创建配置架构
create_config_schemas() {
    log_info "创建配置架构..."
    
    # 主配置架构
    cat > "$CONFIG_SCHEMAS_DIR/main.json" << 'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Dev Environment Configuration",
  "type": "object",
  "properties": {
    "ssh": {
      "type": "object",
      "properties": {
        "alias": {
          "type": "string",
          "description": "SSH别名"
        },
        "host": {
          "type": "string",
          "format": "hostname",
          "description": "SSH主机"
        },
        "port": {
          "type": "integer",
          "minimum": 1,
          "maximum": 65535,
          "default": 22
        },
        "user": {
          "type": "string",
          "description": "SSH用户名"
        },
        "key_path": {
          "type": "string",
          "description": "SSH私钥路径"
        }
      },
      "required": ["alias", "host", "user"]
    },
    "docker": {
      "type": "object",
      "properties": {
        "compose_project": {
          "type": "string",
          "description": "Docker Compose项目名"
        },
        "host_port": {
          "type": "integer",
          "minimum": 1024,
          "maximum": 65535,
          "default": 8000
        },
        "container_port": {
          "type": "integer",
          "minimum": 1,
          "maximum": 65535,
          "default": 8000
        },
        "service_name": {
          "type": "string",
          "default": "web"
        }
      },
      "required": ["compose_project"]
    },
    "sync": {
      "type": "object",
      "properties": {
        "local_path": {
          "type": "string",
          "description": "本地项目路径"
        },
        "remote_path": {
          "type": "string",
          "description": "远程项目路径"
        },
        "exclude_patterns": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "default": [".git", "node_modules", "__pycache__"]
        },
        "auto_sync": {
          "type": "boolean",
          "default": false
        }
      },
      "required": ["local_path", "remote_path"]
    },
    "cluster": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": false
        },
        "servers": {
          "type": "array",
          "items": {
            "$ref": "#/definitions/server"
          }
        },
        "load_balancer": {
          "type": "object",
          "properties": {
            "algorithm": {
              "type": "string",
              "enum": ["round_robin", "weighted_round_robin", "least_connections"],
              "default": "weighted_round_robin"
            }
          }
        }
      }
    },
    "monitoring": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": true
        },
        "metrics_port": {
          "type": "integer",
          "default": 9090
        },
        "alert_webhook": {
          "type": "string",
          "format": "uri"
        }
      }
    }
  },
  "definitions": {
    "server": {
      "type": "object",
      "properties": {
        "name": {
          "type": "string"
        },
        "host": {
          "type": "string",
          "format": "hostname"
        },
        "port": {
          "type": "integer",
          "default": 22
        },
        "user": {
          "type": "string"
        },
        "role": {
          "type": "string",
          "enum": ["primary", "secondary", "development"]
        },
        "weight": {
          "type": "integer",
          "minimum": 1,
          "default": 100
        }
      },
      "required": ["name", "host", "user", "role"]
    }
  },
  "required": ["ssh", "docker", "sync"]
}
EOF

    # 插件配置架构
    cat > "$CONFIG_SCHEMAS_DIR/plugins.json" << 'EOF'
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Plugins Configuration",
  "type": "object",
  "properties": {
    "global": {
      "type": "object",
      "properties": {
        "enabled": {
          "type": "boolean",
          "default": true
        },
        "auto_load": {
          "type": "boolean",
          "default": true
        },
        "max_execution_time": {
          "type": "integer",
          "minimum": 1,
          "default": 30
        }
      }
    },
    "installed": {
      "type": "object",
      "additionalProperties": {
        "type": "object",
        "properties": {
          "enabled": {
            "type": "boolean"
          },
          "version": {
            "type": "string"
          },
          "config": {
            "type": "object"
          }
        }
      }
    }
  }
}
EOF
}

# 创建活跃配置
create_active_config() {
    if [[ ! -f "$ACTIVE_CONFIG_FILE" ]]; then
        log_info "创建活跃配置文件..."
        
        cat > "$ACTIVE_CONFIG_FILE" << 'EOF'
{
  "version": "1.0.0",
  "timestamp": "",
  "config": {
    "ssh": {
      "alias": "remote-server",
      "host": "192.168.1.100",
      "port": 22,
      "user": "dev",
      "key_path": "~/.ssh/id_rsa"
    },
    "docker": {
      "compose_project": "workspace",
      "host_port": 8000,
      "container_port": 8000,
      "service_name": "web"
    },
    "sync": {
      "local_path": ".",
      "remote_path": "/home/dev/workspace",
      "exclude_patterns": [".git", "node_modules", "__pycache__", ".DS_Store"],
      "auto_sync": false
    },
    "cluster": {
      "enabled": false,
      "servers": [],
      "load_balancer": {
        "algorithm": "weighted_round_robin"
      }
    },
    "monitoring": {
      "enabled": true,
      "metrics_port": 9090,
      "alert_webhook": ""
    }
  },
  "metadata": {
    "created_by": "system",
    "created_at": "",
    "last_modified_by": "system",
    "last_modified_at": "",
    "revision": 1,
    "checksum": ""
  }
}
EOF
        
        # 更新时间戳和校验和
        update_config_metadata "$ACTIVE_CONFIG_FILE" "system" "initial"
    fi
}

# 更新配置元数据
update_config_metadata() {
    local config_file="$1"
    local modified_by="$2"
    local change_reason="$3"
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local checksum=$(calculate_config_checksum "$config_file")
    local current_revision=$(jq -r '.metadata.revision // 1' "$config_file")
    local new_revision=$((current_revision + 1))
    
    jq --arg timestamp "$timestamp" \
       --arg modified_by "$modified_by" \
       --arg checksum "$checksum" \
       --arg reason "$change_reason" \
       --argjson revision "$new_revision" \
       '.metadata.last_modified_at = $timestamp |
        .metadata.last_modified_by = $modified_by |
        .metadata.checksum = $checksum |
        .metadata.change_reason = $reason |
        .metadata.revision = $revision |
        .timestamp = $timestamp' \
       "$config_file" > "$config_file.tmp"
    mv "$config_file.tmp" "$config_file"
}

# 计算配置校验和
calculate_config_checksum() {
    local config_file="$1"
    
    # 提取配置部分并计算MD5
    jq -S '.config' "$config_file" | md5sum | cut -d' ' -f1
}

# 验证配置
validate_config() {
    local config_file="$1"
    local schema_file="${2:-$CONFIG_SCHEMAS_DIR/main.json}"
    
    log_info "验证配置文件: $config_file"
    
    # 检查文件是否存在
    if [[ ! -f "$config_file" ]]; then
        log_error "配置文件不存在: $config_file"
        return 1
    fi
    
    # 检查JSON格式
    if ! jq empty "$config_file" 2>/dev/null; then
        log_error "配置文件JSON格式错误"
        return 1
    fi
    
    # 使用JSON Schema验证（如果有ajv-cli）
    if command -v ajv &> /dev/null; then
        local config_data=$(jq '.config' "$config_file")
        echo "$config_data" | ajv validate -s "$schema_file" -d -
        
        if [[ $? -eq 0 ]]; then
            log_success "配置验证通过"
            return 0
        else
            log_error "配置验证失败"
            return 1
        fi
    else
        # 基本验证
        basic_config_validation "$config_file"
    fi
}

# 基本配置验证
basic_config_validation() {
    local config_file="$1"
    
    local errors=0
    
    # 检查必需字段
    local required_fields=("ssh.alias" "ssh.host" "ssh.user" "docker.compose_project" "sync.local_path" "sync.remote_path")
    
    for field in "${required_fields[@]}"; do
        local value=$(jq -r ".config.$field" "$config_file" 2>/dev/null)
        if [[ "$value" == "null" || -z "$value" ]]; then
            log_error "缺少必需字段: $field"
            ((errors++))
        fi
    done
    
    # 检查端口范围
    local ports=("ssh.port" "docker.host_port" "docker.container_port")
    for port_field in "${ports[@]}"; do
        local port=$(jq -r ".config.$port_field" "$config_file" 2>/dev/null)
        if [[ "$port" != "null" ]] && [[ $port -lt 1 || $port -gt 65535 ]]; then
            log_error "端口范围错误: $port_field = $port"
            ((errors++))
        fi
    done
    
    if [[ $errors -eq 0 ]]; then
        log_success "基本配置验证通过"
        return 0
    else
        log_error "发现 $errors 个配置错误"
        return 1
    fi
}

# 加载配置
load_config() {
    local config_file="${1:-$ACTIVE_CONFIG_FILE}"
    
    log_info "加载配置: $config_file"
    
    # 验证配置
    if ! validate_config "$config_file"; then
        log_error "配置验证失败，无法加载"
        return 1
    fi
    
    # 备份当前配置
    backup_current_config
    
    # 提取配置数据
    local config_data=$(jq -r '.config' "$config_file")
    
    # 导出环境变量
    export SSH_ALIAS=$(echo "$config_data" | jq -r '.ssh.alias')
    export SSH_HOST=$(echo "$config_data" | jq -r '.ssh.host')
    export SSH_PORT=$(echo "$config_data" | jq -r '.ssh.port')
    export SSH_USER=$(echo "$config_data" | jq -r '.ssh.user')
    export SSH_KEY_PATH=$(echo "$config_data" | jq -r '.ssh.key_path')
    
    export COMPOSE_PROJECT_NAME=$(echo "$config_data" | jq -r '.docker.compose_project')
    export DOCKER_HOST_PORT=$(echo "$config_data" | jq -r '.docker.host_port')
    export DOCKER_CONTAINER_PORT=$(echo "$config_data" | jq -r '.docker.container_port')
    export DOCKER_SERVICE_NAME=$(echo "$config_data" | jq -r '.docker.service_name')
    
    export LOCAL_PROJECT_PATH=$(echo "$config_data" | jq -r '.sync.local_path')
    export REMOTE_PROJECT_PATH=$(echo "$config_data" | jq -r '.sync.remote_path')
    export AUTO_SYNC=$(echo "$config_data" | jq -r '.sync.auto_sync')
    
    # 更新活跃配置
    if [[ "$config_file" != "$ACTIVE_CONFIG_FILE" ]]; then
        cp "$config_file" "$ACTIVE_CONFIG_FILE"
    fi
    
    log_success "配置加载完成"
    
    # 触发配置更新钩子
    source "$(dirname "$0")/../plugins/manager.sh" 2>/dev/null || true
    if declare -f execute_hook > /dev/null; then
        execute_hook "on_config_update" "$config_data"
    fi
}

# 备份当前配置
backup_current_config() {
    if [[ -f "$ACTIVE_CONFIG_FILE" ]]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_file="$CONFIG_HISTORY_DIR/config_$timestamp.json"
        
        cp "$ACTIVE_CONFIG_FILE" "$backup_file"
        log_info "配置已备份: $backup_file"
    fi
}

# 更新配置
update_config() {
    local key="$1"
    local value="$2"
    local modified_by="${3:-user}"
    
    log_info "更新配置: $key = $value"
    
    # 获取配置锁
    acquire_config_lock
    
    # 备份当前配置
    backup_current_config
    
    # 更新配置值
    jq --arg key "$key" \
       --arg value "$value" \
       '.config | setpath($key | split("."); $value)' \
       "$ACTIVE_CONFIG_FILE" > "$ACTIVE_CONFIG_FILE.tmp"
    
    # 重新包装配置
    jq --argjson config "$(cat "$ACTIVE_CONFIG_FILE.tmp")" \
       '.config = $config' \
       "$ACTIVE_CONFIG_FILE" > "$ACTIVE_CONFIG_FILE.new"
    
    rm -f "$ACTIVE_CONFIG_FILE.tmp"
    
    # 验证新配置
    if validate_config "$ACTIVE_CONFIG_FILE.new"; then
        # 更新元数据
        update_config_metadata "$ACTIVE_CONFIG_FILE.new" "$modified_by" "update $key"
        
        # 应用新配置
        mv "$ACTIVE_CONFIG_FILE.new" "$ACTIVE_CONFIG_FILE"
        
        log_success "配置更新成功"
        
        # 重新加载配置
        load_config
        
        # 释放锁
        release_config_lock
        
        return 0
    else
        log_error "新配置验证失败，回滚更改"
        rm -f "$ACTIVE_CONFIG_FILE.new"
        
        # 释放锁
        release_config_lock
        
        return 1
    fi
}

# 回滚配置
rollback_config() {
    local revision="${1:-1}"
    
    log_header "回滚配置到版本 $revision"
    
    # 查找历史配置
    local backup_files=($(ls -t "$CONFIG_HISTORY_DIR"/config_*.json 2>/dev/null))
    
    if [[ ${#backup_files[@]} -eq 0 ]]; then
        log_error "没有可用的配置备份"
        return 1
    fi
    
    local target_index=$((revision - 1))
    if [[ $target_index -ge ${#backup_files[@]} ]]; then
        log_error "指定的版本不存在"
        return 1
    fi
    
    local target_file="${backup_files[$target_index]}"
    
    log_info "回滚到配置文件: $target_file"
    
    # 验证目标配置
    if validate_config "$target_file"; then
        # 备份当前配置
        backup_current_config
        
        # 应用目标配置
        cp "$target_file" "$ACTIVE_CONFIG_FILE"
        update_config_metadata "$ACTIVE_CONFIG_FILE" "system" "rollback to revision $revision"
        
        # 重新加载配置
        load_config
        
        log_success "配置回滚成功"
        return 0
    else
        log_error "目标配置验证失败"
        return 1
    fi
}

# 配置锁管理
acquire_config_lock() {
    local timeout=30
    local elapsed=0
    
    while [[ -f "$CONFIG_LOCK_FILE" ]] && [[ $elapsed -lt $timeout ]]; do
        sleep 1
        ((elapsed++))
    done
    
    if [[ $elapsed -ge $timeout ]]; then
        log_error "获取配置锁超时"
        return 1
    fi
    
    echo $$ > "$CONFIG_LOCK_FILE"
}

release_config_lock() {
    rm -f "$CONFIG_LOCK_FILE"
}

# 启动配置监控
start_config_watcher() {
    local watcher_script="$CONFIG_WATCHERS_DIR/config_watcher.sh"
    
    cat > "$watcher_script" << 'EOF'
#!/bin/bash

# 配置文件监控器

CONFIG_FILE="$1"
CALLBACK_SCRIPT="$2"

if command -v fswatch &> /dev/null; then
    fswatch -o "$CONFIG_FILE" | while read num; do
        echo "$(date): 配置文件已更改"
        if [[ -x "$CALLBACK_SCRIPT" ]]; then
            "$CALLBACK_SCRIPT" "$CONFIG_FILE"
        fi
    done
else
    # 轮询模式
    last_mtime=$(stat -c %Y "$CONFIG_FILE" 2>/dev/null || stat -f %m "$CONFIG_FILE" 2>/dev/null)
    
    while true; do
        sleep 5
        current_mtime=$(stat -c %Y "$CONFIG_FILE" 2>/dev/null || stat -f %m "$CONFIG_FILE" 2>/dev/null)
        
        if [[ "$current_mtime" != "$last_mtime" ]]; then
            echo "$(date): 配置文件已更改"
            if [[ -x "$CALLBACK_SCRIPT" ]]; then
                "$CALLBACK_SCRIPT" "$CONFIG_FILE"
            fi
            last_mtime="$current_mtime"
        fi
    done
fi
EOF
    
    chmod +x "$watcher_script"
    
    # 创建回调脚本
    local callback_script="$CONFIG_WATCHERS_DIR/on_config_change.sh"
    
    cat > "$callback_script" << 'EOF'
#!/bin/bash

CONFIG_FILE="$1"

echo "配置文件变更检测: $CONFIG_FILE"

# 验证配置
source "$(dirname "$0")/../dynamic/config_manager.sh"

if validate_config "$CONFIG_FILE"; then
    echo "配置验证通过，重新加载..."
    load_config "$CONFIG_FILE"
else
    echo "配置验证失败，忽略更改"
fi
EOF
    
    chmod +x "$callback_script"
}

# 显示配置状态
show_config_status() {
    log_header "配置状态"
    
    if [[ ! -f "$ACTIVE_CONFIG_FILE" ]]; then
        log_warning "活跃配置文件不存在"
        return 1
    fi
    
    local metadata=$(jq -r '.metadata' "$ACTIVE_CONFIG_FILE")
    local timestamp=$(echo "$metadata" | jq -r '.last_modified_at')
    local modified_by=$(echo "$metadata" | jq -r '.last_modified_by')
    local revision=$(echo "$metadata" | jq -r '.revision')
    local checksum=$(echo "$metadata" | jq -r '.checksum')
    
    log_info "当前版本: $revision"
    log_info "最后修改: $timestamp"
    log_info "修改者: $modified_by"
    log_info "校验和: $checksum"
    
    # 显示配置摘要
    echo ""
    echo "配置摘要:"
    jq -r '.config | to_entries[] | "  \(.key): \(.value | type)"' "$ACTIVE_CONFIG_FILE"
}

# 导出函数
export -f init_dynamic_config validate_config load_config update_config
export -f rollback_config show_config_status 