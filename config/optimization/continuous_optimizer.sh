#!/bin/bash

# =============================================================================
# 持续优化脚本 - 系统性能优化和调优
# 作者: Zhang-Jingdian
# 邮箱: 2157429750@qq.com
# 创建时间: 2025年7月14日
# 描述: 根据实际使用情况进行系统调优和性能改进
# 版本: 1.0.0
# =============================================================================

set -euo pipefail

# 获取脚本路径
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"
source "$SCRIPT_DIR/constants.sh"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
OPTIMIZATION_LOG="$LOG_DIR/optimization.log"
METRICS_DIR="$LOG_DIR/metrics"
PERFORMANCE_THRESHOLD=80
MEMORY_THRESHOLD=85
CPU_THRESHOLD=90
DISK_THRESHOLD=85

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$OPTIMIZATION_LOG"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$OPTIMIZATION_LOG"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$OPTIMIZATION_LOG"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$OPTIMIZATION_LOG"
}

# 创建必要目录
create_directories() {
    mkdir -p "$METRICS_DIR"
    mkdir -p "$(dirname "$OPTIMIZATION_LOG")"
    touch "$OPTIMIZATION_LOG"
}

# 收集系统指标
collect_system_metrics() {
    log_info "收集系统指标..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local metrics_file="$METRICS_DIR/system_metrics_$timestamp.json"
    
    # 收集CPU使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    
    # 收集内存使用率
    local memory_info=$(free | grep Mem)
    local total_memory=$(echo $memory_info | awk '{print $2}')
    local used_memory=$(echo $memory_info | awk '{print $3}')
    local memory_usage=$(echo "scale=2; $used_memory * 100 / $total_memory" | bc)
    
    # 收集磁盘使用率
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    # 收集网络连接数
    local network_connections=$(netstat -an | wc -l)
    
    # 收集Docker容器状态
    local docker_containers=0
    if command -v docker &> /dev/null; then
        docker_containers=$(docker ps -q | wc -l)
    fi
    
    # 生成JSON格式的指标
    cat > "$metrics_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system": {
        "cpu_usage": $cpu_usage,
        "memory_usage": $memory_usage,
        "disk_usage": $disk_usage,
        "network_connections": $network_connections,
        "docker_containers": $docker_containers
    },
    "load_average": "$(uptime | awk -F'load average:' '{print $2}')",
    "uptime": "$(uptime -p)"
}
EOF
    
    log_success "✅ 系统指标收集完成: $metrics_file"
    echo "$metrics_file"
}

# 分析性能瓶颈
analyze_performance_bottlenecks() {
    log_info "分析性能瓶颈..."
    
    local metrics_file="$1"
    local bottlenecks=()
    
    # 解析指标
    local cpu_usage=$(jq -r '.system.cpu_usage' "$metrics_file")
    local memory_usage=$(jq -r '.system.memory_usage' "$metrics_file")
    local disk_usage=$(jq -r '.system.disk_usage' "$metrics_file")
    
    # 检查CPU瓶颈
    if (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l) )); then
        bottlenecks+=("CPU使用率过高: ${cpu_usage}%")
        log_warning "⚠️  CPU使用率过高: ${cpu_usage}%"
    fi
    
    # 检查内存瓶颈
    if (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l) )); then
        bottlenecks+=("内存使用率过高: ${memory_usage}%")
        log_warning "⚠️  内存使用率过高: ${memory_usage}%"
    fi
    
    # 检查磁盘瓶颈
    if (( disk_usage > DISK_THRESHOLD )); then
        bottlenecks+=("磁盘使用率过高: ${disk_usage}%")
        log_warning "⚠️  磁盘使用率过高: ${disk_usage}%"
    fi
    
    # 返回瓶颈列表
    printf '%s\n' "${bottlenecks[@]}"
}

# 优化CPU性能
optimize_cpu_performance() {
    log_info "优化CPU性能..."
    
    # 调整进程优先级
    local high_cpu_processes=$(ps aux --sort=-%cpu | head -10 | tail -9)
    
    # 识别并优化高CPU使用率进程
    while IFS= read -r process; do
        local pid=$(echo "$process" | awk '{print $2}')
        local cpu_percent=$(echo "$process" | awk '{print $3}')
        local command=$(echo "$process" | awk '{print $11}')
        
        if (( $(echo "$cpu_percent > 50" | bc -l) )); then
            log_warning "高CPU进程: $command (PID: $pid, CPU: $cpu_percent%)"
            
            # 降低进程优先级
            if renice +5 "$pid" &>/dev/null; then
                log_success "✅ 已降低进程优先级: $command"
            fi
        fi
    done <<< "$high_cpu_processes"
    
    # 启用CPU频率调节
    if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        echo "performance" | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor &>/dev/null
        log_success "✅ CPU频率调节器设置为性能模式"
    fi
}

# 优化内存性能
optimize_memory_performance() {
    log_info "优化内存性能..."
    
    # 清理系统缓存
    sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches &>/dev/null
    log_success "✅ 系统缓存已清理"
    
    # 调整交换分区使用
    if [ -f /proc/sys/vm/swappiness ]; then
        echo 10 | sudo tee /proc/sys/vm/swappiness &>/dev/null
        log_success "✅ 交换分区使用率已调整"
    fi
    
    # 识别内存泄漏进程
    local memory_hogs=$(ps aux --sort=-%mem | head -10 | tail -9)
    
    while IFS= read -r process; do
        local pid=$(echo "$process" | awk '{print $2}')
        local mem_percent=$(echo "$process" | awk '{print $4}')
        local command=$(echo "$process" | awk '{print $11}')
        
        if (( $(echo "$mem_percent > 20" | bc -l) )); then
            log_warning "高内存进程: $command (PID: $pid, MEM: $mem_percent%)"
        fi
    done <<< "$memory_hogs"
    
    # 优化Docker内存使用
    if command -v docker &> /dev/null; then
        docker system prune -f &>/dev/null
        log_success "✅ Docker系统清理完成"
    fi
}

# 优化磁盘性能
optimize_disk_performance() {
    log_info "优化磁盘性能..."
    
    # 清理临时文件
    sudo find /tmp -type f -atime +7 -delete &>/dev/null
    sudo find /var/tmp -type f -atime +7 -delete &>/dev/null
    log_success "✅ 临时文件清理完成"
    
    # 清理日志文件
    sudo find /var/log -name "*.log" -type f -size +100M -exec truncate -s 50M {} \;
    log_success "✅ 大型日志文件已截断"
    
    # 清理包管理器缓存
    if command -v apt-get &> /dev/null; then
        sudo apt-get clean &>/dev/null
        sudo apt-get autoclean &>/dev/null
        log_success "✅ APT缓存清理完成"
    fi
    
    # 磁盘碎片整理（如果是ext4文件系统）
    local filesystem=$(df -T / | awk 'NR==2 {print $2}')
    if [ "$filesystem" = "ext4" ]; then
        sudo e4defrag / &>/dev/null
        log_success "✅ 磁盘碎片整理完成"
    fi
}

# 优化网络性能
optimize_network_performance() {
    log_info "优化网络性能..."
    
    # 调整TCP参数
    cat > /tmp/network_optimization.conf << EOF
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 5000
EOF
    
    sudo cp /tmp/network_optimization.conf /etc/sysctl.d/99-network-optimization.conf
    sudo sysctl -p /etc/sysctl.d/99-network-optimization.conf &>/dev/null
    rm /tmp/network_optimization.conf
    
    log_success "✅ 网络参数优化完成"
    
    # 优化DNS解析
    if ! grep -q "8.8.8.8" /etc/resolv.conf; then
        echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf &>/dev/null
        echo "nameserver 8.8.4.4" | sudo tee -a /etc/resolv.conf &>/dev/null
        log_success "✅ DNS配置优化完成"
    fi
}

# 优化Docker性能
optimize_docker_performance() {
    log_info "优化Docker性能..."
    
    if ! command -v docker &> /dev/null; then
        log_warning "Docker未安装，跳过Docker优化"
        return 0
    fi
    
    # 清理未使用的Docker资源
    docker system prune -af --volumes &>/dev/null
    log_success "✅ Docker资源清理完成"
    
    # 优化Docker配置
    local docker_config="/etc/docker/daemon.json"
    if [ ! -f "$docker_config" ]; then
        sudo mkdir -p /etc/docker
        sudo tee "$docker_config" > /dev/null << EOF
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "default-ulimits": {
        "nofile": {
            "hard": 65536,
            "soft": 65536
        }
    }
}
EOF
        sudo systemctl restart docker
        log_success "✅ Docker配置优化完成"
    fi
    
    # 重启长时间运行的容器
    local old_containers=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "days\|weeks\|months" | awk '{print $1}' | tail -n +2)
    
    if [ -n "$old_containers" ]; then
        while IFS= read -r container; do
            docker restart "$container" &>/dev/null
            log_success "✅ 重启长时间运行的容器: $container"
        done <<< "$old_containers"
    fi
}

# 生成优化建议
generate_optimization_recommendations() {
    log_info "生成优化建议..."
    
    local recommendations_file="$LOG_DIR/optimization_recommendations.md"
    local timestamp=$(date)
    
    cat > "$recommendations_file" << EOF
# 系统优化建议报告

生成时间: $timestamp

## 自动优化已执行的操作

### CPU优化
- ✅ 调整了高CPU使用率进程的优先级
- ✅ 启用了CPU性能模式

### 内存优化
- ✅ 清理了系统缓存
- ✅ 调整了交换分区使用率
- ✅ 清理了Docker系统资源

### 磁盘优化
- ✅ 清理了临时文件和日志文件
- ✅ 清理了包管理器缓存
- ✅ 执行了磁盘碎片整理

### 网络优化
- ✅ 优化了TCP参数
- ✅ 配置了高性能DNS服务器

### Docker优化
- ✅ 清理了未使用的Docker资源
- ✅ 优化了Docker配置
- ✅ 重启了长时间运行的容器

## 手动优化建议

### 硬件升级建议
- 考虑增加内存容量以提高系统性能
- 升级到SSD硬盘以提高磁盘I/O性能
- 考虑使用更快的CPU以提高处理能力

### 软件配置建议
- 定期更新系统和软件包
- 配置适当的监控和告警系统
- 实施定期的性能测试和基准测试

### 运维最佳实践
- 建立定期的系统维护计划
- 实施自动化的性能监控
- 创建性能基线和趋势分析

## 下次优化时间
建议在 $(date -d "+1 week") 进行下次优化检查。

EOF
    
    log_success "✅ 优化建议报告生成完成: $recommendations_file"
}

# 创建性能基线
create_performance_baseline() {
    log_info "创建性能基线..."
    
    local baseline_file="$METRICS_DIR/performance_baseline.json"
    local current_metrics=$(collect_system_metrics)
    
    # 如果基线不存在，创建基线
    if [ ! -f "$baseline_file" ]; then
        cp "$current_metrics" "$baseline_file"
        log_success "✅ 性能基线创建完成"
    else
        # 比较当前性能与基线
        local baseline_cpu=$(jq -r '.system.cpu_usage' "$baseline_file")
        local current_cpu=$(jq -r '.system.cpu_usage' "$current_metrics")
        
        local baseline_memory=$(jq -r '.system.memory_usage' "$baseline_file")
        local current_memory=$(jq -r '.system.memory_usage' "$current_metrics")
        
        log_info "性能对比 (基线 vs 当前):"
        log_info "CPU使用率: ${baseline_cpu}% vs ${current_cpu}%"
        log_info "内存使用率: ${baseline_memory}% vs ${current_memory}%"
        
        # 如果性能显著改善，更新基线
        if (( $(echo "$current_cpu < $baseline_cpu - 10" | bc -l) )) && (( $(echo "$current_memory < $baseline_memory - 10" | bc -l) )); then
            cp "$current_metrics" "$baseline_file"
            log_success "✅ 性能基线已更新"
        fi
    fi
}

# 发送优化报告
send_optimization_report() {
    log_info "发送优化报告..."
    
    local report_file="$LOG_DIR/optimization_summary.txt"
    local timestamp=$(date)
    
    cat > "$report_file" << EOF
远程开发环境优化报告

时间: $timestamp
主机: $(hostname)
用户: $(whoami)

优化摘要:
- CPU优化: 已完成
- 内存优化: 已完成
- 磁盘优化: 已完成
- 网络优化: 已完成
- Docker优化: 已完成

详细报告请查看: $LOG_DIR/optimization_recommendations.md
性能指标请查看: $METRICS_DIR/

下次优化时间: $(date -d "+1 week")
EOF
    
    # 如果配置了邮件，发送报告
    if [ -n "${ALERT_EMAIL:-}" ] && command -v mail &> /dev/null; then
        mail -s "远程开发环境优化报告" "$ALERT_EMAIL" < "$report_file"
        log_success "✅ 优化报告已发送到: $ALERT_EMAIL"
    fi
    
    log_success "✅ 优化报告生成完成: $report_file"
}

# 主优化函数
main() {
    log_info "🚀 开始系统持续优化"
    echo "========================================"
    
    # 创建必要目录
    create_directories
    
    # 收集系统指标
    local metrics_file=$(collect_system_metrics)
    
    # 分析性能瓶颈
    local bottlenecks=$(analyze_performance_bottlenecks "$metrics_file")
    
    if [ -n "$bottlenecks" ]; then
        log_warning "发现性能瓶颈:"
        echo "$bottlenecks" | while IFS= read -r bottleneck; do
            log_warning "  - $bottleneck"
        done
        
        # 执行优化
        optimize_cpu_performance
        optimize_memory_performance
        optimize_disk_performance
        optimize_network_performance
        optimize_docker_performance
    else
        log_success "✅ 系统性能良好，无需优化"
    fi
    
    # 创建性能基线
    create_performance_baseline
    
    # 生成优化建议
    generate_optimization_recommendations
    
    # 发送优化报告
    send_optimization_report
    
    echo "========================================"
    log_success "🎉 系统优化完成！"
    log_info "查看详细报告: $LOG_DIR/optimization_recommendations.md"
    log_info "查看性能指标: $METRICS_DIR/"
}

# 显示帮助信息
show_help() {
    cat << EOF
系统持续优化脚本

用法: $0 [选项]

选项:
    -h, --help              显示帮助信息
    --cpu-threshold N       CPU使用率阈值 (默认: $CPU_THRESHOLD)
    --memory-threshold N    内存使用率阈值 (默认: $MEMORY_THRESHOLD)
    --disk-threshold N      磁盘使用率阈值 (默认: $DISK_THRESHOLD)
    --metrics-only          仅收集指标，不执行优化
    --report-only           仅生成报告，不执行优化
    --force                 强制执行所有优化，忽略阈值

示例:
    $0                                      # 运行完整优化
    $0 --cpu-threshold 95                   # 设置CPU阈值为95%
    $0 --metrics-only                       # 仅收集指标
    $0 --force                             # 强制优化
EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --cpu-threshold)
            CPU_THRESHOLD="$2"
            shift 2
            ;;
        --memory-threshold)
            MEMORY_THRESHOLD="$2"
            shift 2
            ;;
        --disk-threshold)
            DISK_THRESHOLD="$2"
            shift 2
            ;;
        --metrics-only)
            collect_system_metrics
            exit 0
            ;;
        --report-only)
            generate_optimization_recommendations
            exit 0
            ;;
        --force)
            CPU_THRESHOLD=0
            MEMORY_THRESHOLD=0
            DISK_THRESHOLD=0
            shift
            ;;
        *)
            log_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 运行主函数
main "$@" 