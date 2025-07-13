#!/bin/bash

# =============================================================================
# 代码质量管理系统 - 保持代码整洁
# =============================================================================

# 获取脚本目录
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"

source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"

# 代码质量配置
QUALITY_DIR="$CONFIG_DIR/quality"
REPORTS_DIR="$QUALITY_DIR/reports"
TEMP_DIR="$QUALITY_DIR/temp"

# 初始化质量管理
init_quality_system() {
    log_header "初始化代码质量系统"
    
    mkdir -p "$REPORTS_DIR" "$TEMP_DIR"
    
    # 创建质量配置文件
    create_quality_configs
    
    log_success "代码质量系统初始化完成"
}

# 创建质量配置文件
create_quality_configs() {
    # ShellCheck配置
    cat > "$QUALITY_DIR/.shellcheckrc" << 'EOF'
# ShellCheck配置
disable=SC1091,SC2034,SC2154
source-path=SCRIPTDIR
EOF

    # EditorConfig配置
    cat > "$PROJECT_ROOT/.editorconfig" << 'EOF'
# EditorConfig配置
root = true

[*]
charset = utf-8
end_of_line = lf
indent_style = space
indent_size = 2
insert_final_newline = true
trim_trailing_whitespace = true

[*.{sh,bash}]
indent_size = 4

[*.{py,python}]
indent_size = 4

[*.{md,markdown}]
trim_trailing_whitespace = false

[*.{json,yml,yaml}]
indent_size = 2
EOF

    # Prettier配置
    cat > "$PROJECT_ROOT/.prettierrc" << 'EOF'
{
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "semi": true,
  "singleQuote": true,
  "quoteProps": "as-needed",
  "trailingComma": "es5",
  "bracketSpacing": true,
  "arrowParens": "avoid"
}
EOF
}

# Shell脚本格式化
format_shell_scripts() {
    log_header "格式化Shell脚本"
    
    local formatted_count=0
    
    # 查找所有Shell脚本
    find "$PROJECT_ROOT" -name "*.sh" -type f | while read -r script; do
        # 跳过隐藏文件和node_modules
        if [[ "$script" =~ /\.|node_modules ]]; then
            continue
        fi
        
        log_info "格式化: $(basename "$script")"
        
        # 使用shfmt格式化（如果可用）
        if command -v shfmt &> /dev/null; then
            shfmt -w -i 4 -ci "$script"
            ((formatted_count++))
        else
            # 基本格式化
            sed -i.bak 's/[[:space:]]*$//' "$script"  # 删除行尾空格
            rm -f "$script.bak"
        fi
    done
    
    log_success "格式化完成，处理了 $formatted_count 个文件"
}

# 代码质量检查
check_code_quality() {
    log_header "代码质量检查"
    
    local issues=0
    local report_file="$REPORTS_DIR/quality_report_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "代码质量检查报告 - $(date)" > "$report_file"
    echo "==============================" >> "$report_file"
    
    # Shell脚本检查
    check_shell_scripts "$report_file"
    
    # Python代码检查
    check_python_code "$report_file"
    
    # 配置文件检查
    check_config_files "$report_file"
    
    # 生成总结
    echo "" >> "$report_file"
    echo "检查完成 - $(date)" >> "$report_file"
    
    log_success "质量检查完成，报告保存到: $report_file"
}

# Shell脚本检查
check_shell_scripts() {
    local report_file="$1"
    
    echo "" >> "$report_file"
    echo "Shell脚本检查:" >> "$report_file"
    echo "---------------" >> "$report_file"
    
    find "$PROJECT_ROOT" -name "*.sh" -type f | while read -r script; do
        if [[ "$script" =~ /\.|node_modules ]]; then
            continue
        fi
        
        echo "检查: $script" >> "$report_file"
        
        # 使用shellcheck检查（如果可用）
        if command -v shellcheck &> /dev/null; then
            shellcheck "$script" >> "$report_file" 2>&1
        else
            # 基本检查
            if ! bash -n "$script" 2>/dev/null; then
                echo "  语法错误!" >> "$report_file"
            fi
        fi
    done
}

# Python代码检查
check_python_code() {
    local report_file="$1"
    
    echo "" >> "$report_file"
    echo "Python代码检查:" >> "$report_file"
    echo "---------------" >> "$report_file"
    
    find "$PROJECT_ROOT" -name "*.py" -type f | while read -r pyfile; do
        if [[ "$pyfile" =~ /\.|node_modules|__pycache__ ]]; then
            continue
        fi
        
        echo "检查: $pyfile" >> "$report_file"
        
        # 语法检查
        if ! python3 -m py_compile "$pyfile" 2>/dev/null; then
            echo "  语法错误!" >> "$report_file"
        fi
        
        # 使用flake8检查（如果可用）
        if command -v flake8 &> /dev/null; then
            flake8 "$pyfile" >> "$report_file" 2>&1
        fi
    done
}

# 配置文件检查
check_config_files() {
    local report_file="$1"
    
    echo "" >> "$report_file"
    echo "配置文件检查:" >> "$report_file"
    echo "-------------" >> "$report_file"
    
    # 检查YAML文件
    find "$PROJECT_ROOT" -name "*.yml" -o -name "*.yaml" | while read -r yamlfile; do
        echo "检查YAML: $yamlfile" >> "$report_file"
        
        if command -v yamllint &> /dev/null; then
            yamllint "$yamlfile" >> "$report_file" 2>&1
        else
            # 基本YAML语法检查
            if ! python3 -c "import yaml; yaml.safe_load(open('$yamlfile'))" 2>/dev/null; then
                echo "  YAML语法错误!" >> "$report_file"
            fi
        fi
    done
    
    # 检查JSON文件
    find "$PROJECT_ROOT" -name "*.json" | while read -r jsonfile; do
        echo "检查JSON: $jsonfile" >> "$report_file"
        
        if ! python3 -m json.tool "$jsonfile" >/dev/null 2>&1; then
            echo "  JSON语法错误!" >> "$report_file"
        fi
    done
}

# 清理无用文件
cleanup_project() {
    log_header "清理项目文件"
    
    local cleaned_count=0
    
    # 清理临时文件
    find "$PROJECT_ROOT" -name "*.bak" -delete && ((cleaned_count++))
    find "$PROJECT_ROOT" -name "*.tmp" -delete && ((cleaned_count++))
    find "$PROJECT_ROOT" -name "*.temp" -delete && ((cleaned_count++))
    find "$PROJECT_ROOT" -name "*~" -delete && ((cleaned_count++))
    
    # 清理Python缓存
    find "$PROJECT_ROOT" -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null && ((cleaned_count++))
    find "$PROJECT_ROOT" -name "*.pyc" -delete && ((cleaned_count++))
    find "$PROJECT_ROOT" -name "*.pyo" -delete && ((cleaned_count++))
    
    # 清理macOS文件
    find "$PROJECT_ROOT" -name ".DS_Store" -delete && ((cleaned_count++))
    
    # 清理空目录
    find "$PROJECT_ROOT" -type d -empty -delete 2>/dev/null && ((cleaned_count++))
    
    log_success "清理完成，处理了 $cleaned_count 项"
}

# 代码统计
code_statistics() {
    log_header "代码统计"
    
    local stats_file="$REPORTS_DIR/stats_$(date +%Y%m%d_%H%M%S).txt"
    
    echo "项目代码统计 - $(date)" > "$stats_file"
    echo "========================" >> "$stats_file"
    
    # 文件统计
    echo "" >> "$stats_file"
    echo "文件统计:" >> "$stats_file"
    echo "--------" >> "$stats_file"
    
    find "$PROJECT_ROOT" -type f | grep -E '\.(sh|py|js|html|css|yml|yaml|json|md)$' | \
    awk -F. '{print $NF}' | sort | uniq -c | sort -nr >> "$stats_file"
    
    # 代码行数统计
    echo "" >> "$stats_file"
    echo "代码行数统计:" >> "$stats_file"
    echo "------------" >> "$stats_file"
    
    if command -v cloc &> /dev/null; then
        cloc "$PROJECT_ROOT" >> "$stats_file"
    else
        # 简单统计
        echo "Shell脚本: $(find "$PROJECT_ROOT" -name "*.sh" -exec wc -l {} + | tail -1)" >> "$stats_file"
        echo "Python代码: $(find "$PROJECT_ROOT" -name "*.py" -exec wc -l {} + | tail -1)" >> "$stats_file"
        echo "配置文件: $(find "$PROJECT_ROOT" -name "*.yml" -o -name "*.yaml" -o -name "*.json" -exec wc -l {} + | tail -1)" >> "$stats_file"
    fi
    
    log_success "统计完成，报告保存到: $stats_file"
}

# 依赖检查
check_dependencies() {
    log_header "依赖检查"
    
    local missing_deps=()
    
    # 检查必需工具
    local required_tools=("git" "curl" "rsync" "ssh" "docker")
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_deps+=("$tool")
        fi
    done
    
    # 检查可选工具
    local optional_tools=("shellcheck" "shfmt" "yamllint" "flake8" "cloc")
    
    for tool in "${optional_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_warning "可选工具未安装: $tool"
        else
            log_info "已安装: $tool"
        fi
    done
    
    if [[ ${#missing_deps[@]} -eq 0 ]]; then
        log_success "所有必需依赖都已安装"
    else
        log_error "缺少必需依赖: ${missing_deps[*]}"
        return 1
    fi
}

# 主函数
main() {
    case "$1" in
        "init")
            init_quality_system
            ;;
        "format")
            format_shell_scripts
            ;;
        "check")
            check_code_quality
            ;;
        "cleanup")
            cleanup_project
            ;;
        "stats")
            code_statistics
            ;;
        "deps")
            check_dependencies
            ;;
        "all")
            init_quality_system
            check_dependencies
            format_shell_scripts
            check_code_quality
            cleanup_project
            code_statistics
            ;;
        *)
            echo "用法: $0 {init|format|check|cleanup|stats|deps|all}"
            echo ""
            echo "命令说明:"
            echo "  init    - 初始化质量系统"
            echo "  format  - 格式化代码"
            echo "  check   - 质量检查"
            echo "  cleanup - 清理项目"
            echo "  stats   - 代码统计"
            echo "  deps    - 依赖检查"
            echo "  all     - 执行所有操作"
            exit 1
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 