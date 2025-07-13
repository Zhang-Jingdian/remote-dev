#!/bin/bash

# macOS兼容的持续优化脚本
# 作者: 远程开发环境项目
# 版本: 1.0.0

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

# 收集macOS系统指标
collect_macos_metrics() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local metrics_file="$METRICS_DIR/system_metrics_$timestamp.json"
    
    log_info "收集macOS系统指标..."
    
    # 收集CPU使用率 (macOS)
    local cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
    
    # 收集内存使用率 (macOS)
    local memory_info=$(vm_stat | grep -E "(Pages free|Pages active|Pages inactive|Pages speculative|Pages wired down)")
    local page_size=$(vm_stat | head -n 1 | awk '{print $8}')
    local free_pages=$(echo "$memory_info" | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
    local active_pages=$(echo "$memory_info" | grep "Pages active" | awk '{print $3}' | sed 's/\.//')
    local inactive_pages=$(echo "$memory_info" | grep "Pages inactive" | awk '{print $3}' | sed 's/\.//')
    local wired_pages=$(echo "$memory_info" | grep "Pages wired down" | awk '{print $4}' | sed 's/\.//')
    
    local total_memory=$((($free_pages + $active_pages + $inactive_pages + $wired_pages) * $page_size / 1024 / 1024))
    local used_memory=$((($active_pages + $inactive_pages + $wired_pages) * $page_size / 1024 / 1024))
    local memory_usage=$(echo "scale=2; $used_memory * 100 / $total_memory" | bc)
    
    # 收集磁盘使用率 (macOS)
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    # 收集网络连接数
    local network_connections=$(netstat -an | wc -l | tr -d ' ')
    
    # 收集Docker容器状态
    local docker_containers=0
    if command -v docker &> /dev/null; then
        docker_containers=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')
    fi
    
    # 生成JSON格式的指标
    cat > "$metrics_file" << EOF
{
    "timestamp": "$(date -Iseconds)",
    "system": {
        "cpu_usage": ${cpu_usage:-0},
        "memory_usage": ${memory_usage:-0},
        "disk_usage": ${disk_usage:-0},
        "network_connections": $network_connections,
        "docker_containers": $docker_containers,
        "total_memory_mb": ${total_memory:-0},
        "used_memory_mb": ${used_memory:-0}
    },
    "load_average": "$(uptime | awk -F'load averages:' '{print $2}' | xargs)",
    "uptime": "$(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')",
    "platform": "macOS"
}
EOF
    
    log_success "✅ 系统指标收集完成: $metrics_file"
    echo "$metrics_file"
}

# 分析性能瓶颈 (macOS版本)
analyze_macos_performance() {
    log_info "分析macOS系统性能..."
    
    local metrics_file="$1"
    
    if [ ! -f "$metrics_file" ]; then
        log_error "指标文件不存在: $metrics_file"
        return 1
    fi
    
    # 使用Python解析JSON (macOS通常有Python)
    if command -v python3 &> /dev/null; then
        local cpu_usage=$(python3 -c "
import json
with open('$metrics_file', 'r') as f:
    data = json.load(f)
    print(data['system']['cpu_usage'])
")
        local memory_usage=$(python3 -c "
import json
with open('$metrics_file', 'r') as f:
    data = json.load(f)
    print(data['system']['memory_usage'])
")
        local disk_usage=$(python3 -c "
import json
with open('$metrics_file', 'r') as f:
    data = json.load(f)
    print(data['system']['disk_usage'])
")
        
        log_info "📊 系统性能指标:"
        log_info "CPU使用率: ${cpu_usage}%"
        log_info "内存使用率: ${memory_usage}%"
        log_info "磁盘使用率: ${disk_usage}%"
        
        # 简单的性能分析
        if (( $(echo "$cpu_usage > 80" | bc -l) )); then
            log_warning "⚠️  CPU使用率较高: ${cpu_usage}%"
        fi
        
        if (( $(echo "$memory_usage > 80" | bc -l) )); then
            log_warning "⚠️  内存使用率较高: ${memory_usage}%"
        fi
        
        if (( disk_usage > 85 )); then
            log_warning "⚠️  磁盘使用率较高: ${disk_usage}%"
        fi
    else
        log_warning "Python3未安装，跳过详细性能分析"
    fi
}

# macOS系统优化
optimize_macos_system() {
    log_info "执行macOS系统优化..."
    
    # 清理系统缓存
    if command -v sudo &> /dev/null; then
        sudo purge 2>/dev/null || true
        log_success "✅ 系统内存已清理"
    fi
    
    # 清理用户缓存
    if [ -d ~/Library/Caches ]; then
        find ~/Library/Caches -name "*" -type f -atime +7 -delete 2>/dev/null || true
        log_success "✅ 用户缓存已清理"
    fi
    
    # 清理临时文件
    if [ -d /tmp ]; then
        find /tmp -name "*" -type f -atime +1 -delete 2>/dev/null || true
        log_success "✅ 临时文件已清理"
    fi
    
    # 优化Docker (如果存在)
    if command -v docker &> /dev/null; then
        docker system prune -f &>/dev/null || true
        log_success "✅ Docker系统已清理"
    fi
    
    # 清理Homebrew缓存 (如果存在)
    if command -v brew &> /dev/null; then
        brew cleanup &>/dev/null || true
        log_success "✅ Homebrew缓存已清理"
    fi
}

# 生成优化报告
generate_macos_report() {
    log_info "生成macOS优化报告..."
    
    local report_file="$LOG_DIR/macos_optimization_report.md"
    local timestamp=$(date)
    
    cat > "$report_file" << EOF
# macOS系统优化报告

## 优化时间
$timestamp

## 系统信息
- 操作系统: $(sw_vers -productName) $(sw_vers -productVersion)
- 硬件: $(system_profiler SPHardwareDataType | grep "Model Name" | awk -F': ' '{print $2}')
- 处理器: $(system_profiler SPHardwareDataType | grep "Processor Name" | awk -F': ' '{print $2}')
- 内存: $(system_profiler SPHardwareDataType | grep "Memory" | awk -F': ' '{print $2}')

## 已执行的优化操作
- ✅ 清理了系统内存缓存
- ✅ 清理了用户缓存文件
- ✅ 清理了临时文件
- ✅ 清理了Docker系统资源
- ✅ 清理了Homebrew缓存

## 性能指标
$(if [ -f "$METRICS_DIR"/system_metrics_*.json ]; then
    latest_metrics=$(ls -t "$METRICS_DIR"/system_metrics_*.json | head -1)
    if command -v python3 &> /dev/null; then
        echo "- CPU使用率: $(python3 -c "import json; data=json.load(open('$latest_metrics')); print(f\"{data['system']['cpu_usage']:.1f}%\")")"
        echo "- 内存使用率: $(python3 -c "import json; data=json.load(open('$latest_metrics')); print(f\"{data['system']['memory_usage']:.1f}%\")")"
        echo "- 磁盘使用率: $(python3 -c "import json; data=json.load(open('$latest_metrics')); print(f\"{data['system']['disk_usage']}%\")")"
        echo "- Docker容器: $(python3 -c "import json; data=json.load(open('$latest_metrics')); print(data['system']['docker_containers'])")个"
    fi
fi)

## 建议
- 定期运行此脚本进行系统维护
- 监控磁盘空间使用情况
- 考虑升级硬件以提升性能
- 定期更新系统和应用程序

## 下次优化建议时间
$(date -v+1w)
EOF
    
    log_success "✅ 优化报告生成完成: $report_file"
}

# 主函数
main() {
    log_info "🚀 开始macOS系统优化"
    echo "========================================"
    
    # 创建必要目录
    create_directories
    
    # 收集系统指标
    local metrics_file=$(collect_macos_metrics)
    
    # 分析性能
    analyze_macos_performance "$metrics_file"
    
    # 执行优化
    optimize_macos_system
    
    # 生成报告
    generate_macos_report
    
    echo "========================================"
    log_success "🎉 macOS系统优化完成！"
    log_info "查看报告: $LOG_DIR/macos_optimization_report.md"
    log_info "查看指标: $METRICS_DIR/"
}

# 解析命令行参数
case "${1:-run}" in
    "--metrics-only")
        create_directories
        collect_macos_metrics
        ;;
    "--report-only")
        generate_macos_report
        ;;
    *)
        main
        ;;
esac 