#!/bin/bash

# 快速启动开发环境脚本
echo "🚀 启动远程开发环境..."

# 检查SSH连接
echo "🔍 检查远程连接..."
if ! ssh -o ConnectTimeout=5 -o BatchMode=yes zjd "echo 'SSH连接成功'" > /dev/null 2>&1; then
    echo "❌ 无法连接到远程服务器 'zjd'"
    echo "💡 请检查:"
    echo "   - 远程服务器是否启动"
    echo "   - SSH配置是否正确"
    exit 1
fi

echo "✅ 远程连接正常"

# 检查远程Docker服务
echo "🐳 检查远程Docker服务..."
if ! ssh zjd "docker --version" > /dev/null 2>&1; then
    echo "❌ 远程Docker服务未运行"
    echo "💡 请在远程服务器上启动Docker服务"
    exit 1
fi

echo "✅ 远程Docker服务正常"

# 提示用户接下来的步骤
echo ""
echo "🎯 环境检查完成！接下来请:"
echo "1. 在VS Code中按 F1"
echo "2. 输入 'Remote-SSH: Connect to Host'"
echo "3. 选择 'zjd'"
echo "4. 打开文件夹 '/home/zjd/workspace'"
echo "5. 在提示中点击 'Reopen in Container'"
echo ""
echo "🎉 享受你的远程开发环境！" 