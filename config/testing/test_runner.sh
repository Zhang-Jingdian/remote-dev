#!/bin/bash

# =============================================================================
# 测试运行器 - 验证所有功能模块
# 作者: Zhang-Jingdian
# 邮箱: 2157429750@qq.com
# 创建时间: 2025年7月14日
# 描述: 提供完整的功能模块测试和验证框架
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

# 测试结果统计
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    
    ((TOTAL_TESTS++))
    
    log_info "运行测试: $test_name"
    
    if eval "$test_command" &>/dev/null; then
        local result=$?
        if [ "$result" -eq "$expected_result" ]; then
            log_success "✅ $test_name - 通过"
            ((PASSED_TESTS++))
            return 0
        else
            log_error "❌ $test_name - 失败 (退出码: $result, 期望: $expected_result)"
            ((FAILED_TESTS++))
            return 1
        fi
    else
        log_error "❌ $test_name - 执行失败"
        ((FAILED_TESTS++))
        return 1
    fi
}

# 跳过测试
skip_test() {
    local test_name="$1"
    local reason="$2"
    
    ((TOTAL_TESTS++))
    ((SKIPPED_TESTS++))
    
    log_warning "⏭️  $test_name - 跳过 ($reason)"
}

# 检查文件是否存在
check_file_exists() {
    local file_path="$1"
    local description="$2"
    
    if [ -f "$file_path" ]; then
        run_test "$description" "test -f '$file_path'"
    else
        log_error "文件不存在: $file_path"
        ((TOTAL_TESTS++))
        ((FAILED_TESTS++))
    fi
}

# 检查目录是否存在
check_dir_exists() {
    local dir_path="$1"
    local description="$2"
    
    if [ -d "$dir_path" ]; then
        run_test "$description" "test -d '$dir_path'"
    else
        log_error "目录不存在: $dir_path"
        ((TOTAL_TESTS++))
        ((FAILED_TESTS++))
    fi
}

# 检查脚本语法
check_script_syntax() {
    local script_path="$1"
    local script_name="$(basename "$script_path")"
    
    if [ -f "$script_path" ]; then
        run_test "检查 $script_name 语法" "bash -n '$script_path'"
    else
        skip_test "检查 $script_name 语法" "文件不存在"
    fi
}

# 主测试函数
main() {
    log_info "🚀 开始运行远程开发环境测试套件"
    echo "========================================"
    
    # 1. 基础结构测试
    log_info "📁 测试基础目录结构"
    check_dir_exists "$SCRIPT_DIR" "config根目录存在"
    check_file_exists "$SCRIPT_DIR/constants.sh" "constants.sh文件存在"
    
    # 2. 核心模块测试
    log_info "🔧 测试核心模块"
    check_dir_exists "$SCRIPT_DIR/core" "core目录存在"
    check_file_exists "$SCRIPT_DIR/core/lib.sh" "核心库文件存在"
    check_script_syntax "$SCRIPT_DIR/core/lib.sh" "核心库语法检查"
    
    # 3. 安全模块测试
    log_info "🔒 测试安全模块"
    check_dir_exists "$SCRIPT_DIR/security" "security目录存在"
    check_file_exists "$SCRIPT_DIR/security/security_hardening.sh" "安全加固脚本存在"
    check_script_syntax "$SCRIPT_DIR/security/security_hardening.sh" "安全加固脚本语法检查"
    
    # 4. 监控模块测试
    log_info "📊 测试监控模块"
    check_dir_exists "$SCRIPT_DIR/monitoring" "monitoring目录存在"
    check_file_exists "$SCRIPT_DIR/monitoring/alerting.sh" "告警脚本存在"
    check_script_syntax "$SCRIPT_DIR/monitoring/alerting.sh" "告警脚本语法检查"
    
    # 5. 备份模块测试
    log_info "💾 测试备份模块"
    check_dir_exists "$SCRIPT_DIR/backup" "backup目录存在"
    check_file_exists "$SCRIPT_DIR/backup/backup_strategy.sh" "备份策略脚本存在"
    check_script_syntax "$SCRIPT_DIR/backup/backup_strategy.sh" "备份策略脚本语法检查"
    
    # 6. 开发模块测试
    log_info "🔧 测试开发模块"
    check_dir_exists "$SCRIPT_DIR/dev" "dev目录存在"
    check_file_exists "$SCRIPT_DIR/dev/cicd_integration.sh" "CI/CD集成脚本存在"
    check_script_syntax "$SCRIPT_DIR/dev/cicd_integration.sh" "CI/CD集成脚本语法检查"
    
    # 7. 高级功能测试
    log_info "🚀 测试高级功能"
    check_dir_exists "$SCRIPT_DIR/advanced" "advanced目录存在"
    check_file_exists "$SCRIPT_DIR/advanced/advanced_manager.sh" "高级管理器脚本存在"
    check_script_syntax "$SCRIPT_DIR/advanced/advanced_manager.sh" "高级管理器脚本语法检查"
    
    # 8. 文档模块测试
    log_info "📚 测试文档模块"
    check_dir_exists "$SCRIPT_DIR/docs" "docs目录存在"
    check_file_exists "$SCRIPT_DIR/docs/documentation_manager.sh" "文档管理器脚本存在"
    check_script_syntax "$SCRIPT_DIR/docs/documentation_manager.sh" "文档管理器脚本语法检查"
    
    # 9. 网络模块测试
    log_info "🌐 测试网络模块"
    check_dir_exists "$SCRIPT_DIR/network" "network目录存在"
    check_file_exists "$SCRIPT_DIR/network/connection_pool.sh" "连接池脚本存在"
    check_script_syntax "$SCRIPT_DIR/network/connection_pool.sh" "连接池脚本语法检查"
    
    # 10. 集群模块测试
    log_info "🔗 测试集群模块"
    check_dir_exists "$SCRIPT_DIR/cluster" "cluster目录存在"
    check_file_exists "$SCRIPT_DIR/cluster/manager.sh" "集群管理器脚本存在"
    check_script_syntax "$SCRIPT_DIR/cluster/manager.sh" "集群管理器脚本语法检查"
    
    # 11. 插件模块测试
    log_info "🔌 测试插件模块"
    check_dir_exists "$SCRIPT_DIR/plugins" "plugins目录存在"
    check_file_exists "$SCRIPT_DIR/plugins/manager.sh" "插件管理器脚本存在"
    check_script_syntax "$SCRIPT_DIR/plugins/manager.sh" "插件管理器脚本语法检查"
    
    # 12. 动态配置测试
    log_info "⚙️ 测试动态配置"
    check_dir_exists "$SCRIPT_DIR/dynamic" "dynamic目录存在"
    check_file_exists "$SCRIPT_DIR/dynamic/config_manager.sh" "动态配置管理器脚本存在"
    check_script_syntax "$SCRIPT_DIR/dynamic/config_manager.sh" "动态配置管理器脚本语法检查"
    
    # 13. 功能测试
    log_info "🧪 运行功能测试"
    
    # 测试constants.sh是否可以正常加载
    run_test "加载constants.sh" "source '$SCRIPT_DIR/constants.sh'"
    
    # 测试核心库函数
    if [ -f "$SCRIPT_DIR/core/lib.sh" ]; then
        run_test "加载核心库" "source '$SCRIPT_DIR/core/lib.sh'"
    fi
    
    # 测试环境变量
    run_test "检查PROJECT_NAME变量" "[ -n \"\${PROJECT_NAME:-}\" ]"
    run_test "检查CONFIG_DIR变量" "[ -n \"\${CONFIG_DIR:-}\" ]"
    
    # 14. 权限测试
    log_info "🔐 测试文件权限"
    find "$SCRIPT_DIR" -name "*.sh" -type f | while read -r script; do
        if [ -x "$script" ]; then
            log_success "✅ $(basename "$script") - 可执行"
        else
            log_warning "⚠️  $(basename "$script") - 不可执行"
        fi
    done
    
    # 输出测试结果
    echo "========================================"
    log_info "📊 测试结果统计"
    echo "总测试数: $TOTAL_TESTS"
    echo -e "通过: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "失败: ${RED}$FAILED_TESTS${NC}"
    echo -e "跳过: ${YELLOW}$SKIPPED_TESTS${NC}"
    
    if [ "$FAILED_TESTS" -eq 0 ]; then
        log_success "🎉 所有测试通过！"
        return 0
    else
        log_error "❌ 有 $FAILED_TESTS 个测试失败"
        return 1
    fi
}

# 运行主函数
main "$@" 