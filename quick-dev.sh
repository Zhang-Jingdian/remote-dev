#!/bin/bash
# 快速开发环境启动脚本 - 智能自动化版本

echo "🚀 快速启动开发环境..."

# 智能检测并启动
if command -v code &> /dev/null; then
    echo "🎯 检测到VS Code，准备启动..."
    # 运行智能检测
    bash ./auto-dev.sh
    echo ""
    echo "💡 如果选择了SSH + Dev Container模式："
    echo "   请在VS Code中按 Ctrl+Shift+P，然后选择 'Remote-SSH: Connect to Host'"
    echo ""
    echo "💡 如果选择了远程Docker服务器模式："
    echo "   现在可以直接使用: docker-compose up -d"
else
    echo "⚠️  未检测到VS Code，仅设置Docker环境"
    bash ./auto-dev.sh
fi
