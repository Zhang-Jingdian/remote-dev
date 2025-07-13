#!/bin/bash

# =============================================================================
# 插件系统管理器 - 动态扩展架构
# =============================================================================

# 获取脚本目录
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"

source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"

# 插件系统配置
PLUGINS_DIR="$CONFIG_DIR/plugins"
PLUGINS_REGISTRY_FILE="$PLUGINS_DIR/registry.json"
PLUGINS_CONFIG_FILE="$PLUGINS_DIR/config.yml"
PLUGIN_HOOKS_DIR="$PLUGINS_DIR/hooks"
INSTALLED_PLUGINS_DIR="$PLUGINS_DIR/installed"

# 插件钩子类型 (兼容macOS bash 3.2)
get_hook_description() {
    case "$1" in
        "before_sync") echo "同步前钩子" ;;
        "after_sync") echo "同步后钩子" ;;
        "before_deploy") echo "部署前钩子" ;;
        "after_deploy") echo "部署后钩子" ;;
        "on_server_connect") echo "服务器连接钩子" ;;
        "on_server_disconnect") echo "服务器断开钩子" ;;
        "on_error") echo "错误处理钩子" ;;
        "custom_command") echo "自定义命令钩子" ;;
        *) echo "未知钩子类型" ;;
    esac
}

# 获取所有可用的钩子类型
get_available_hooks() {
    echo "before_sync after_sync before_deploy after_deploy on_server_connect on_server_disconnect on_error custom_command"
}

# 初始化插件系统
init_plugin_system() {
    log_header "初始化插件系统"
    
    # 创建插件目录结构
    mkdir -p "$PLUGINS_DIR"/{installed,hooks,templates,cache}
    
    # 创建插件注册表
    create_plugin_registry
    
    # 创建插件配置模板
    create_plugin_config_template
    
    # 创建示例插件
    create_example_plugins
    
    log_success "插件系统初始化完成"
}

# 创建插件注册表
create_plugin_registry() {
    if [[ ! -f "$PLUGINS_REGISTRY_FILE" ]]; then
        log_info "创建插件注册表..."
        
        cat > "$PLUGINS_REGISTRY_FILE" << 'EOF'
{
  "version": "1.0.0",
  "plugins": {},
  "hooks": {},
  "metadata": {
    "created": "",
    "last_updated": "",
    "total_plugins": 0,
    "active_plugins": 0
  }
}
EOF
        
        # 更新时间戳
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        jq --arg timestamp "$timestamp" \
           '.metadata.created = $timestamp | .metadata.last_updated = $timestamp' \
           "$PLUGINS_REGISTRY_FILE" > "$PLUGINS_REGISTRY_FILE.tmp"
        mv "$PLUGINS_REGISTRY_FILE.tmp" "$PLUGINS_REGISTRY_FILE"
    fi
}

# 创建插件配置模板
create_plugin_config_template() {
    if [[ ! -f "$PLUGINS_CONFIG_FILE" ]]; then
        log_info "创建插件配置模板..."
        
        cat > "$PLUGINS_CONFIG_FILE" << 'EOF'
# =============================================================================
# 插件系统配置
# =============================================================================

plugins:
  # 全局插件设置
  global:
    enabled: true
    auto_load: true
    hot_reload: true
    max_execution_time: 30
    
  # 插件源配置
  sources:
    - name: "official"
      url: "https://github.com/dev-env-plugins/official"
      type: "git"
      branch: "main"
      
    - name: "community"
      url: "https://github.com/dev-env-plugins/community"
      type: "git"
      branch: "main"

  # 已安装插件
  installed:
    notification:
      enabled: true
      version: "1.0.0"
      config:
        slack_webhook: ""
        email_smtp: ""
        
    code_quality:
      enabled: true
      version: "1.2.0"
      config:
        eslint: true
        prettier: true
        sonarqube: false

# 钩子配置
hooks:
  before_sync:
    - plugin: "code_quality"
      function: "lint_check"
      
  after_deploy:
    - plugin: "notification"
      function: "send_deploy_notification"
      
  on_error:
    - plugin: "notification"
      function: "send_error_alert"
EOF
    fi
}

# 创建示例插件
create_example_plugins() {
    # 通知插件
    create_notification_plugin
    
    # 代码质量插件
    create_code_quality_plugin
    
    # 性能监控插件
    create_performance_plugin
}

# 创建通知插件
create_notification_plugin() {
    local plugin_dir="$INSTALLED_PLUGINS_DIR/notification"
    mkdir -p "$plugin_dir"
    
    cat > "$plugin_dir/plugin.yml" << 'EOF'
name: "notification"
version: "1.0.0"
description: "多渠道通知插件"
author: "Dev Team"
license: "MIT"
homepage: "https://github.com/dev-env/notification-plugin"

# 插件元数据
metadata:
  category: "communication"
  tags: ["notification", "slack", "email", "webhook"]
  min_system_version: "2.0.0"
  
# 依赖
dependencies:
  - name: "curl"
    version: ">=7.0"
    required: true
  - name: "jq"
    version: ">=1.6"
    required: true

# 配置架构
config_schema:
  slack:
    webhook_url:
      type: "string"
      required: false
      description: "Slack Webhook URL"
  email:
    smtp_server:
      type: "string"
      required: false
    smtp_port:
      type: "integer"
      default: 587
    username:
      type: "string"
      required: false
    password:
      type: "string"
      required: false
      sensitive: true

# 钩子函数
hooks:
  - name: "send_deploy_notification"
    description: "发送部署通知"
    hook_type: "after_deploy"
  - name: "send_error_alert"
    description: "发送错误告警"
    hook_type: "on_error"
  - name: "send_custom_message"
    description: "发送自定义消息"
    hook_type: "custom_command"
EOF

    cat > "$plugin_dir/notification.sh" << 'EOF'
#!/bin/bash

# 通知插件实现

# 发送Slack通知
send_slack_notification() {
    local message="$1"
    local webhook_url="$2"
    
    if [[ -n "$webhook_url" ]]; then
        curl -X POST -H 'Content-type: application/json' \
             --data "{\"text\":\"$message\"}" \
             "$webhook_url" 2>/dev/null
        
        log_info "Slack通知已发送"
    fi
}

# 发送邮件通知
send_email_notification() {
    local subject="$1"
    local body="$2"
    local to_email="$3"
    local smtp_config="$4"
    
    # 使用sendmail或其他邮件工具
    if command -v sendmail &> /dev/null; then
        echo -e "Subject: $subject\n\n$body" | sendmail "$to_email"
        log_info "邮件通知已发送到: $to_email"
    fi
}

# 钩子函数：部署后通知
send_deploy_notification() {
    local deploy_info="$1"
    local config="$2"
    
    local message="🚀 部署完成: $deploy_info"
    
    # 解析配置
    local slack_webhook=$(echo "$config" | jq -r '.slack.webhook_url // empty')
    
    if [[ -n "$slack_webhook" ]]; then
        send_slack_notification "$message" "$slack_webhook"
    fi
}

# 钩子函数：错误告警
send_error_alert() {
    local error_info="$1"
    local config="$2"
    
    local message="🚨 错误告警: $error_info"
    
    # 解析配置
    local slack_webhook=$(echo "$config" | jq -r '.slack.webhook_url // empty')
    
    if [[ -n "$slack_webhook" ]]; then
        send_slack_notification "$message" "$slack_webhook"
    fi
}

# 自定义命令：发送消息
send_custom_message() {
    local message="$1"
    local channel="$2"
    local config="$3"
    
    case "$channel" in
        "slack")
            local slack_webhook=$(echo "$config" | jq -r '.slack.webhook_url // empty')
            send_slack_notification "$message" "$slack_webhook"
            ;;
        "email")
            local to_email=$(echo "$config" | jq -r '.email.to // empty')
            send_email_notification "Dev Environment Message" "$message" "$to_email" "$config"
            ;;
        *)
            log_error "未知的通知渠道: $channel"
            return 1
            ;;
    esac
}

# 导出函数
export -f send_deploy_notification send_error_alert send_custom_message
EOF

    chmod +x "$plugin_dir/notification.sh"
}

# 插件加载器
load_plugin() {
    local plugin_name="$1"
    local plugin_dir="$INSTALLED_PLUGINS_DIR/$plugin_name"
    
    if [[ ! -d "$plugin_dir" ]]; then
        log_error "插件不存在: $plugin_name"
        return 1
    fi
    
    log_info "加载插件: $plugin_name"
    
    # 检查插件配置
    local plugin_config="$plugin_dir/plugin.yml"
    if [[ ! -f "$plugin_config" ]]; then
        log_error "插件配置文件不存在: $plugin_config"
        return 1
    fi
    
    # 验证插件依赖
    if ! validate_plugin_dependencies "$plugin_config"; then
        log_error "插件依赖验证失败: $plugin_name"
        return 1
    fi
    
    # 加载插件脚本
    local plugin_script="$plugin_dir/$plugin_name.sh"
    if [[ -f "$plugin_script" ]]; then
        source "$plugin_script"
        log_success "插件加载成功: $plugin_name"
        
        # 注册插件
        register_plugin "$plugin_name" "$plugin_config"
        
        return 0
    else
        log_error "插件脚本不存在: $plugin_script"
        return 1
    fi
}

# 验证插件依赖
validate_plugin_dependencies() {
    local plugin_config="$1"
    
    # 使用yq或python解析YAML
    if command -v yq &> /dev/null; then
        local dependencies=$(yq eval '.dependencies[]' "$plugin_config" 2>/dev/null)
    else
        local dependencies=$(python3 -c "
import yaml
with open('$plugin_config', 'r') as f:
    data = yaml.safe_load(f)
    deps = data.get('dependencies', [])
    for dep in deps:
        print(f\"{dep['name']} {dep.get('version', '')} {dep.get('required', False)}\")
" 2>/dev/null)
    fi
    
    if [[ -z "$dependencies" ]]; then
        return 0
    fi
    
    while IFS= read -r dep_line; do
        if [[ -n "$dep_line" ]]; then
            local dep_name=$(echo "$dep_line" | cut -d' ' -f1)
            local dep_required=$(echo "$dep_line" | cut -d' ' -f3)
            
            if [[ "$dep_required" == "True" ]] && ! command -v "$dep_name" &> /dev/null; then
                log_error "缺少必需依赖: $dep_name"
                return 1
            fi
        fi
    done <<< "$dependencies"
    
    return 0
}

# 注册插件
register_plugin() {
    local plugin_name="$1"
    local plugin_config="$2"
    
    # 读取插件信息
    local plugin_info=$(python3 -c "
import yaml, json
with open('$plugin_config', 'r') as f:
    data = yaml.safe_load(f)
    print(json.dumps(data))
" 2>/dev/null)
    
    # 更新注册表
    jq --arg name "$plugin_name" \
       --argjson info "$plugin_info" \
       --arg timestamp "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
       '.plugins[$name] = $info | 
        .plugins[$name].status = "loaded" |
        .plugins[$name].loaded_at = $timestamp |
        .metadata.last_updated = $timestamp |
        .metadata.total_plugins = (.plugins | length)' \
       "$PLUGINS_REGISTRY_FILE" > "$PLUGINS_REGISTRY_FILE.tmp"
    mv "$PLUGINS_REGISTRY_FILE.tmp" "$PLUGINS_REGISTRY_FILE"
    
    # 注册钩子
    register_plugin_hooks "$plugin_name" "$plugin_info"
}

# 注册插件钩子
register_plugin_hooks() {
    local plugin_name="$1"
    local plugin_info="$2"
    
    # 提取钩子信息
    local hooks=$(echo "$plugin_info" | jq -r '.hooks[]? | "\(.name):\(.hook_type)"' 2>/dev/null)
    
    while IFS= read -r hook_line; do
        if [[ -n "$hook_line" ]]; then
            local hook_name=$(echo "$hook_line" | cut -d':' -f1)
            local hook_type=$(echo "$hook_line" | cut -d':' -f2)
            
            # 更新钩子注册表
            jq --arg plugin "$plugin_name" \
               --arg hook "$hook_name" \
               --arg type "$hook_type" \
               '.hooks[$type] = (.hooks[$type] // []) + [{"plugin": $plugin, "function": $hook}]' \
               "$PLUGINS_REGISTRY_FILE" > "$PLUGINS_REGISTRY_FILE.tmp"
            mv "$PLUGINS_REGISTRY_FILE.tmp" "$PLUGINS_REGISTRY_FILE"
            
            log_info "注册钩子: $hook_type -> $plugin_name::$hook_name"
        fi
    done <<< "$hooks"
}

# 执行钩子
execute_hook() {
    local hook_type="$1"
    shift
    local hook_args=("$@")
    
    log_info "执行钩子: $hook_type"
    
    # 获取注册的钩子
    local hooks=$(jq -r ".hooks[\"$hook_type\"][]? | \"\(.plugin):\(.function)\"" "$PLUGINS_REGISTRY_FILE" 2>/dev/null)
    
    while IFS= read -r hook_line; do
        if [[ -n "$hook_line" ]]; then
            local plugin_name=$(echo "$hook_line" | cut -d':' -f1)
            local function_name=$(echo "$hook_line" | cut -d':' -f2)
            
            log_info "执行: $plugin_name::$function_name"
            
            # 检查函数是否存在
            if declare -f "$function_name" > /dev/null; then
                # 获取插件配置
                local plugin_config=$(get_plugin_config "$plugin_name")
                
                # 执行钩子函数
                "$function_name" "${hook_args[@]}" "$plugin_config"
            else
                log_warning "钩子函数不存在: $function_name"
            fi
        fi
    done <<< "$hooks"
}

# 获取插件配置
get_plugin_config() {
    local plugin_name="$1"
    
    if command -v yq &> /dev/null; then
        yq eval ".plugins.installed.$plugin_name.config" "$PLUGINS_CONFIG_FILE" -o json 2>/dev/null
    else
        python3 -c "
import yaml, json
with open('$PLUGINS_CONFIG_FILE', 'r') as f:
    data = yaml.safe_load(f)
    config = data.get('plugins', {}).get('installed', {}).get('$plugin_name', {}).get('config', {})
    print(json.dumps(config))
" 2>/dev/null
    fi
}

# 列出所有插件
list_plugins() {
    log_header "已安装插件列表"
    
    if [[ ! -f "$PLUGINS_REGISTRY_FILE" ]]; then
        log_warning "插件注册表不存在"
        return 1
    fi
    
    local plugins=$(jq -r '.plugins | keys[]' "$PLUGINS_REGISTRY_FILE" 2>/dev/null)
    
    if [[ -z "$plugins" ]]; then
        log_info "没有已安装的插件"
        return 0
    fi
    
    while IFS= read -r plugin; do
        local info=$(jq -r ".plugins[\"$plugin\"]" "$PLUGINS_REGISTRY_FILE")
        local version=$(echo "$info" | jq -r '.version')
        local status=$(echo "$info" | jq -r '.status')
        local description=$(echo "$info" | jq -r '.description')
        
        printf "%-20s %-10s %-10s %s\n" "$plugin" "$version" "$status" "$description"
    done <<< "$plugins"
}

# 启用插件
enable_plugin() {
    local plugin_name="$1"
    
    log_info "启用插件: $plugin_name"
    
    # 更新配置文件
    if command -v yq &> /dev/null; then
        yq eval ".plugins.installed.$plugin_name.enabled = true" -i "$PLUGINS_CONFIG_FILE"
    else
        python3 -c "
import yaml
with open('$PLUGINS_CONFIG_FILE', 'r') as f:
    data = yaml.safe_load(f)
data.setdefault('plugins', {}).setdefault('installed', {}).setdefault('$plugin_name', {})['enabled'] = True
with open('$PLUGINS_CONFIG_FILE', 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
"
    fi
    
    # 加载插件
    load_plugin "$plugin_name"
}

# 禁用插件
disable_plugin() {
    local plugin_name="$1"
    
    log_info "禁用插件: $plugin_name"
    
    # 更新配置文件
    if command -v yq &> /dev/null; then
        yq eval ".plugins.installed.$plugin_name.enabled = false" -i "$PLUGINS_CONFIG_FILE"
    else
        python3 -c "
import yaml
with open('$PLUGINS_CONFIG_FILE', 'r') as f:
    data = yaml.safe_load(f)
data.setdefault('plugins', {}).setdefault('installed', {}).setdefault('$plugin_name', {})['enabled'] = False
with open('$PLUGINS_CONFIG_FILE', 'w') as f:
    yaml.dump(data, f, default_flow_style=False)
"
    fi
    
    # 从注册表移除
    jq --arg name "$plugin_name" \
       'del(.plugins[$name]) | del(.hooks[][] | select(.plugin == $name))' \
       "$PLUGINS_REGISTRY_FILE" > "$PLUGINS_REGISTRY_FILE.tmp"
    mv "$PLUGINS_REGISTRY_FILE.tmp" "$PLUGINS_REGISTRY_FILE"
    
    log_success "插件已禁用: $plugin_name"
}

# 加载所有启用的插件
load_all_plugins() {
    log_header "加载所有启用的插件"
    
    if [[ ! -f "$PLUGINS_CONFIG_FILE" ]]; then
        log_warning "插件配置文件不存在"
        return 0
    fi
    
    # 获取启用的插件列表
    local enabled_plugins
    if command -v yq &> /dev/null; then
        enabled_plugins=$(yq eval '.plugins.installed | to_entries[] | select(.value.enabled == true) | .key' "$PLUGINS_CONFIG_FILE" 2>/dev/null)
    else
        enabled_plugins=$(python3 -c "
import yaml
with open('$PLUGINS_CONFIG_FILE', 'r') as f:
    data = yaml.safe_load(f)
    installed = data.get('plugins', {}).get('installed', {})
    for name, config in installed.items():
        if config.get('enabled', False):
            print(name)
" 2>/dev/null)
    fi
    
    if [[ -z "$enabled_plugins" ]]; then
        log_info "没有启用的插件"
        return 0
    fi
    
    local loaded_count=0
    while IFS= read -r plugin; do
        if [[ -n "$plugin" ]]; then
            if load_plugin "$plugin"; then
                ((loaded_count++))
            fi
        fi
    done <<< "$enabled_plugins"
    
    log_success "已加载 $loaded_count 个插件"
}

# 导出函数
export -f init_plugin_system load_plugin execute_hook list_plugins
export -f enable_plugin disable_plugin load_all_plugins 