#!/bin/bash

# =============================================================================
# 监控告警系统 - 系统监控与告警管理
# 作者: Zhang-Jingdian
# 邮箱: 2157429750@qq.com
# 创建时间: 2025年7月14日
# 描述: 提供关键指标监控、告警规则配置、通知机制和事件处理功能
# =============================================================================

# 加载基础库
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"
source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"

# 监控配置
MONITORING_CONFIG_DIR="$SCRIPT_DIR/monitoring"
MONITORING_LOG_DIR="$SCRIPT_DIR/logs/monitoring"
MONITORING_METRICS_DIR="$SCRIPT_DIR/metrics"
ALERT_RULES_FILE="$MONITORING_CONFIG_DIR/alert_rules.conf"
NOTIFICATION_CONFIG="$MONITORING_CONFIG_DIR/notifications.conf"

# 确保目录存在
ensure_dir "$MONITORING_CONFIG_DIR"
ensure_dir "$MONITORING_LOG_DIR"
ensure_dir "$MONITORING_METRICS_DIR"

# 初始化监控告警系统
init_monitoring() {
    log_step "初始化监控告警系统"
    
    # 创建告警规则配置
    create_alert_rules
    
    # 创建通知配置
    create_notification_config
    
    # 创建Prometheus配置
    create_prometheus_config
    
    # 创建Grafana配置
    create_grafana_config
    
    # 启动监控服务
    start_monitoring_services
    
    log_info "监控告警系统初始化完成"
}

# 创建告警规则配置
create_alert_rules() {
    log_info "创建告警规则配置..."
    
    cat > "$ALERT_RULES_FILE" << 'EOF'
# 告警规则配置
# 格式: 指标名 阈值 比较操作 持续时间 严重级别 启用状态

# 系统资源监控
cpu_usage 80 > 300 warning true
memory_usage 85 > 300 warning true
disk_usage 90 > 300 critical true
load_average 4.0 > 600 warning true

# 网络监控
network_latency 500 > 300 warning true
network_packet_loss 5 > 300 critical true
connection_failures 10 > 300 critical true

# 应用监控
response_time 2000 > 300 warning true
error_rate 5 > 300 critical true
request_rate 1000 < 300 warning true

# 安全监控
failed_login_attempts 5 > 60 critical true
security_scan_alerts 1 > 0 critical true
suspicious_activity 3 > 300 warning true

# 业务监控
sync_failures 3 > 300 critical true
build_failures 2 > 300 warning true
deployment_failures 1 > 0 critical true
EOF
    
    log_info "告警规则配置已创建: $ALERT_RULES_FILE"
}

# 创建通知配置
create_notification_config() {
    log_info "创建通知配置..."
    
    cat > "$NOTIFICATION_CONFIG" << 'EOF'
# 通知配置
# 格式: 通知类型 配置参数

# 邮件通知
email_enabled true
email_smtp_server smtp.gmail.com
email_smtp_port 587
email_username your-email@gmail.com
email_password your-app-password
email_recipients admin@example.com,dev@example.com

# Slack通知
slack_enabled true
slack_webhook_url https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
slack_channel #alerts
slack_username monitoring-bot

# 企业微信通知
wechat_enabled false
wechat_webhook_url https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=YOUR_KEY

# 钉钉通知
dingtalk_enabled false
dingtalk_webhook_url https://oapi.dingtalk.com/robot/send?access_token=YOUR_TOKEN

# 短信通知
sms_enabled false
sms_provider aliyun
sms_access_key your-access-key
sms_secret_key your-secret-key
sms_phone_numbers +86-13800138000,+86-13900139000

# 通知级别映射
critical_notifications email,slack,sms
warning_notifications email,slack
info_notifications slack
EOF
    
    log_info "通知配置已创建: $NOTIFICATION_CONFIG"
}

# 创建Prometheus配置
create_prometheus_config() {
    log_info "创建Prometheus配置..."
    
    cat > "$MONITORING_CONFIG_DIR/prometheus.yml" << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "alert_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'remote-dev'
    static_configs:
      - targets: ['localhost:8000']
    metrics_path: '/metrics'
    scrape_interval: 5s

  - job_name: 'docker'
    static_configs:
      - targets: ['localhost:9323']

  - job_name: 'ssh-monitoring'
    static_configs:
      - targets: ['localhost:9200']
EOF
    
    # 创建Prometheus告警规则
    cat > "$MONITORING_CONFIG_DIR/alert_rules.yml" << 'EOF'
groups:
- name: system_alerts
  rules:
  - alert: HighCPUUsage
    expr: cpu_usage > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "CPU使用率过高"
      description: "CPU使用率已超过80%，当前值: {{ $value }}%"

  - alert: HighMemoryUsage
    expr: memory_usage > 85
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "内存使用率过高"
      description: "内存使用率已超过85%，当前值: {{ $value }}%"

  - alert: HighDiskUsage
    expr: disk_usage > 90
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "磁盘使用率过高"
      description: "磁盘使用率已超过90%，当前值: {{ $value }}%"

- name: application_alerts
  rules:
  - alert: HighResponseTime
    expr: response_time > 2000
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "应用响应时间过长"
      description: "应用响应时间已超过2秒，当前值: {{ $value }}ms"

  - alert: HighErrorRate
    expr: error_rate > 5
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "错误率过高"
      description: "错误率已超过5%，当前值: {{ $value }}%"

- name: security_alerts
  rules:
  - alert: FailedLoginAttempts
    expr: failed_login_attempts > 5
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "登录失败次数过多"
      description: "检测到{{ $value }}次失败登录尝试"
EOF
    
    log_info "Prometheus配置已创建"
}

# 创建Grafana配置
create_grafana_config() {
    log_info "创建Grafana配置..."
    
    # 创建Grafana仪表板配置
    cat > "$MONITORING_CONFIG_DIR/grafana_dashboard.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "远程开发环境监控",
    "tags": ["remote-dev", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "CPU使用率",
        "type": "graph",
        "targets": [
          {
            "expr": "cpu_usage",
            "legendFormat": "CPU使用率"
          }
        ]
      },
      {
        "id": 2,
        "title": "内存使用率",
        "type": "graph",
        "targets": [
          {
            "expr": "memory_usage",
            "legendFormat": "内存使用率"
          }
        ]
      },
      {
        "id": 3,
        "title": "磁盘使用率",
        "type": "graph",
        "targets": [
          {
            "expr": "disk_usage",
            "legendFormat": "磁盘使用率"
          }
        ]
      },
      {
        "id": 4,
        "title": "网络延迟",
        "type": "graph",
        "targets": [
          {
            "expr": "network_latency",
            "legendFormat": "网络延迟"
          }
        ]
      },
      {
        "id": 5,
        "title": "应用响应时间",
        "type": "graph",
        "targets": [
          {
            "expr": "response_time",
            "legendFormat": "响应时间"
          }
        ]
      },
      {
        "id": 6,
        "title": "错误率",
        "type": "graph",
        "targets": [
          {
            "expr": "error_rate",
            "legendFormat": "错误率"
          }
        ]
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
EOF
    
    log_info "Grafana配置已创建"
}

# 启动监控服务
start_monitoring_services() {
    log_info "启动监控服务..."
    
    # 创建docker-compose文件
    cat > "$MONITORING_CONFIG_DIR/docker-compose.monitoring.yml" << 'EOF'
version: '3.8'

services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--web.console.libraries=/etc/prometheus/console_libraries'
      - '--web.console.templates=/etc/prometheus/consoles'
      - '--storage.tsdb.retention.time=200h'
      - '--web.enable-lifecycle'
    restart: unless-stopped
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./alert_rules.yml:/etc/prometheus/alert_rules.yml
      - prometheus_data:/prometheus
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
    volumes:
      - grafana_data:/var/lib/grafana
    networks:
      - monitoring

  alertmanager:
    image: prom/alertmanager:latest
    container_name: alertmanager
    restart: unless-stopped
    ports:
      - "9093:9093"
    volumes:
      - ./alertmanager.yml:/etc/alertmanager/alertmanager.yml
      - alertmanager_data:/alertmanager
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    restart: unless-stopped
    ports:
      - "9100:9100"
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.rootfs=/rootfs'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)'
    networks:
      - monitoring

volumes:
  prometheus_data:
  grafana_data:
  alertmanager_data:

networks:
  monitoring:
    driver: bridge
EOF
    
    # 创建AlertManager配置
    cat > "$MONITORING_CONFIG_DIR/alertmanager.yml" << 'EOF'
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'your-email@gmail.com'
  smtp_auth_password: 'your-app-password'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
- name: 'web.hook'
  email_configs:
  - to: 'admin@example.com'
    subject: '[ALERT] {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}
  
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    channel: '#alerts'
    title: '[ALERT] {{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'
    text: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF
    
    log_info "监控服务配置已创建"
}

# 收集系统指标
collect_metrics() {
    log_debug "收集系统指标..."
    
    local timestamp=$(date +%s)
    local metrics_file="$MONITORING_METRICS_DIR/metrics_$(date +%Y%m%d_%H%M%S).json"
    
    # CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    
    # 内存使用率
    local memory_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
    
    # 磁盘使用率
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    # 负载平均值
    local load_average=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    # 网络延迟
    local network_latency=$(ping -c 1 "$SSH_HOST" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}' || echo "0")
    
    # 生成指标JSON
    cat > "$metrics_file" << EOF
{
    "timestamp": $timestamp,
    "cpu_usage": ${cpu_usage:-0},
    "memory_usage": ${memory_usage:-0},
    "disk_usage": ${disk_usage:-0},
    "load_average": ${load_average:-0},
    "network_latency": ${network_latency:-0}
}
EOF
    
    # 写入Prometheus格式指标
    cat > "$MONITORING_METRICS_DIR/metrics.prom" << EOF
# HELP cpu_usage CPU使用率
# TYPE cpu_usage gauge
cpu_usage ${cpu_usage:-0}

# HELP memory_usage 内存使用率
# TYPE memory_usage gauge
memory_usage ${memory_usage:-0}

# HELP disk_usage 磁盘使用率
# TYPE disk_usage gauge
disk_usage ${disk_usage:-0}

# HELP load_average 负载平均值
# TYPE load_average gauge
load_average ${load_average:-0}

# HELP network_latency 网络延迟
# TYPE network_latency gauge
network_latency ${network_latency:-0}
EOF
}

# 检查告警规则
check_alerts() {
    log_debug "检查告警规则..."
    
    # 收集当前指标
    collect_metrics
    
    # 读取告警规则
    while IFS=' ' read -r metric_name threshold operator duration severity enabled; do
        # 跳过注释和空行
        [[ "$metric_name" =~ ^#.*$ ]] && continue
        [[ -z "$metric_name" ]] && continue
        [[ "$enabled" != "true" ]] && continue
        
        # 获取当前指标值
        local current_value=$(get_metric_value "$metric_name")
        
        # 检查阈值
        if check_threshold "$current_value" "$threshold" "$operator"; then
            # 检查持续时间
            if check_duration "$metric_name" "$duration"; then
                # 触发告警
                trigger_alert "$metric_name" "$current_value" "$threshold" "$severity"
            fi
        else
            # 清除告警状态
            clear_alert_state "$metric_name"
        fi
    done < "$ALERT_RULES_FILE"
}

# 获取指标值
get_metric_value() {
    local metric_name="$1"
    
    case "$metric_name" in
        "cpu_usage")
            top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//'
            ;;
        "memory_usage")
            free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}'
            ;;
        "disk_usage")
            df / | tail -1 | awk '{print $5}' | sed 's/%//'
            ;;
        "load_average")
            uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//'
            ;;
        "network_latency")
            ping -c 1 "$SSH_HOST" 2>/dev/null | grep "time=" | awk -F'time=' '{print $2}' | awk '{print $1}' || echo "0"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# 检查阈值
check_threshold() {
    local current_value="$1"
    local threshold="$2"
    local operator="$3"
    
    case "$operator" in
        ">")
            [ "$(echo "$current_value > $threshold" | bc -l 2>/dev/null || echo "0")" -eq 1 ]
            ;;
        "<")
            [ "$(echo "$current_value < $threshold" | bc -l 2>/dev/null || echo "0")" -eq 1 ]
            ;;
        ">=")
            [ "$(echo "$current_value >= $threshold" | bc -l 2>/dev/null || echo "0")" -eq 1 ]
            ;;
        "<=")
            [ "$(echo "$current_value <= $threshold" | bc -l 2>/dev/null || echo "0")" -eq 1 ]
            ;;
        "==")
            [ "$(echo "$current_value == $threshold" | bc -l 2>/dev/null || echo "0")" -eq 1 ]
            ;;
        *)
            false
            ;;
    esac
}

# 检查持续时间
check_duration() {
    local metric_name="$1"
    local duration="$2"
    
    local state_file="$MONITORING_LOG_DIR/alert_state_$metric_name"
    local current_time=$(date +%s)
    
    if [ -f "$state_file" ]; then
        local start_time=$(cat "$state_file")
        local elapsed=$((current_time - start_time))
        [ "$elapsed" -ge "$duration" ]
    else
        echo "$current_time" > "$state_file"
        false
    fi
}

# 清除告警状态
clear_alert_state() {
    local metric_name="$1"
    local state_file="$MONITORING_LOG_DIR/alert_state_$metric_name"
    
    [ -f "$state_file" ] && rm -f "$state_file"
}

# 触发告警
trigger_alert() {
    local metric_name="$1"
    local current_value="$2"
    local threshold="$3"
    local severity="$4"
    
    log_warn "触发告警: $metric_name = $current_value (阈值: $threshold)"
    
    # 生成告警消息
    local alert_message="[${severity^^}] $metric_name 告警"
    local alert_description="指标 $metric_name 当前值 $current_value 超过阈值 $threshold"
    
    # 记录告警日志
    local alert_log="$MONITORING_LOG_DIR/alerts_$(date +%Y%m%d).log"
    echo "[$(date)] $alert_message - $alert_description" >> "$alert_log"
    
    # 发送通知
    send_notification "$severity" "$alert_message" "$alert_description"
}

# 发送通知
send_notification() {
    local severity="$1"
    local title="$2"
    local message="$3"
    
    # 读取通知配置
    source "$NOTIFICATION_CONFIG" 2>/dev/null || return 1
    
    # 根据严重级别确定通知方式
    local notification_methods
    case "$severity" in
        "critical")
            notification_methods="$critical_notifications"
            ;;
        "warning")
            notification_methods="$warning_notifications"
            ;;
        "info")
            notification_methods="$info_notifications"
            ;;
        *)
            notification_methods="email"
            ;;
    esac
    
    # 发送通知
    IFS=',' read -ra methods <<< "$notification_methods"
    for method in "${methods[@]}"; do
        case "$method" in
            "email")
                send_email_notification "$title" "$message"
                ;;
            "slack")
                send_slack_notification "$title" "$message"
                ;;
            "wechat")
                send_wechat_notification "$title" "$message"
                ;;
            "dingtalk")
                send_dingtalk_notification "$title" "$message"
                ;;
            "sms")
                send_sms_notification "$title" "$message"
                ;;
        esac
    done
}

# 发送邮件通知
send_email_notification() {
    local title="$1"
    local message="$2"
    
    if [ "$email_enabled" = "true" ]; then
        echo "$message" | mail -s "$title" "$email_recipients" 2>/dev/null || {
            log_warn "邮件发送失败"
        }
    fi
}

# 发送Slack通知
send_slack_notification() {
    local title="$1"
    local message="$2"
    
    if [ "$slack_enabled" = "true" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"channel\":\"$slack_channel\",\"username\":\"$slack_username\",\"text\":\"$title\n$message\"}" \
            "$slack_webhook_url" 2>/dev/null || {
            log_warn "Slack通知发送失败"
        }
    fi
}

# 发送企业微信通知
send_wechat_notification() {
    local title="$1"
    local message="$2"
    
    if [ "$wechat_enabled" = "true" ]; then
        curl -X POST -H 'Content-Type: application/json' \
            --data "{\"msgtype\":\"text\",\"text\":{\"content\":\"$title\n$message\"}}" \
            "$wechat_webhook_url" 2>/dev/null || {
            log_warn "企业微信通知发送失败"
        }
    fi
}

# 发送钉钉通知
send_dingtalk_notification() {
    local title="$1"
    local message="$2"
    
    if [ "$dingtalk_enabled" = "true" ]; then
        curl -X POST -H 'Content-Type: application/json' \
            --data "{\"msgtype\":\"text\",\"text\":{\"content\":\"$title\n$message\"}}" \
            "$dingtalk_webhook_url" 2>/dev/null || {
            log_warn "钉钉通知发送失败"
        }
    fi
}

# 发送短信通知
send_sms_notification() {
    local title="$1"
    local message="$2"
    
    if [ "$sms_enabled" = "true" ]; then
        # 这里需要根据具体的短信服务商API实现
        log_info "短信通知: $title - $message"
    fi
}

# 启动监控守护进程
start_monitoring_daemon() {
    log_step "启动监控守护进程"
    
    local pid_file="$MONITORING_LOG_DIR/monitoring.pid"
    
    # 检查是否已经运行
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            log_warn "监控守护进程已经运行 (PID: $pid)"
            return 0
        fi
    fi
    
    # 启动守护进程
    (
        while true; do
            collect_metrics
            check_alerts
            sleep 30
        done
    ) &
    
    local daemon_pid=$!
    echo "$daemon_pid" > "$pid_file"
    
    log_info "监控守护进程已启动 (PID: $daemon_pid)"
}

# 停止监控守护进程
stop_monitoring_daemon() {
    log_step "停止监控守护进程"
    
    local pid_file="$MONITORING_LOG_DIR/monitoring.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm -f "$pid_file"
            log_info "监控守护进程已停止"
        else
            log_warn "监控守护进程未运行"
            rm -f "$pid_file"
        fi
    else
        log_warn "未找到监控守护进程PID文件"
    fi
}

# 查看监控状态
monitoring_status() {
    log_step "查看监控状态"
    
    local pid_file="$MONITORING_LOG_DIR/monitoring.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            log_info "监控守护进程运行中 (PID: $pid)"
        else
            log_warn "监控守护进程未运行"
        fi
    else
        log_warn "监控守护进程未启动"
    fi
    
    # 显示最近的指标
    log_info "最近的系统指标:"
    collect_metrics
    
    # 显示活跃的告警
    log_info "活跃的告警:"
    local alert_states=$(find "$MONITORING_LOG_DIR" -name "alert_state_*" -type f)
    if [ -n "$alert_states" ]; then
        for state_file in $alert_states; do
            local metric_name=$(basename "$state_file" | sed 's/alert_state_//')
            local start_time=$(cat "$state_file")
            local current_time=$(date +%s)
            local duration=$((current_time - start_time))
            log_warn "  $metric_name: 持续 ${duration}秒"
        done
    else
        log_info "  无活跃告警"
    fi
}

# 主函数
main() {
    case "${1:-help}" in
        "init")
            init_monitoring
            ;;
        "start")
            start_monitoring_daemon
            ;;
        "stop")
            stop_monitoring_daemon
            ;;
        "status")
            monitoring_status
            ;;
        "metrics")
            collect_metrics
            ;;
        "check")
            check_alerts
            ;;
        "test")
            trigger_alert "test_metric" "100" "50" "warning"
            ;;
        "help"|*)
            echo "监控告警系统 📊"
            echo ""
            echo "用法: $0 <命令>"
            echo ""
            echo "命令:"
            echo "  init     - 初始化监控告警系统"
            echo "  start    - 启动监控守护进程"
            echo "  stop     - 停止监控守护进程"
            echo "  status   - 查看监控状态"
            echo "  metrics  - 收集系统指标"
            echo "  check    - 检查告警规则"
            echo "  test     - 测试告警通知"
            echo "  help     - 显示帮助信息"
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 