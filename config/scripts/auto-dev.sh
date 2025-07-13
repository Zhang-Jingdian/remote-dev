#!/bin/bash

# 智能开发模式自动选择脚本
# 根据环境自动检测并启用最佳开发模式

echo "🤖 智能检测最佳开发模式..."
echo "================================"

# 检测远程SSH连接
echo "🔍 检测远程服务器连接..."
REMOTE_AVAILABLE=false
if ssh -o ConnectTimeout=3 -o BatchMode=yes zjd "echo 'test'" > /dev/null 2>&1; then
    echo "✅ 远程服务器 'zjd' 可达"
    REMOTE_AVAILABLE=true
else
    echo "❌ 远程服务器 'zjd' 不可达"
fi

# 检测远程Docker服务
REMOTE_DOCKER=false
if [ "$REMOTE_AVAILABLE" = true ]; then
    echo "🐳 检测远程Docker服务..."
    if ssh zjd "docker --version" > /dev/null 2>&1; then
        echo "✅ 远程Docker服务可用"
        REMOTE_DOCKER=true
    else
        echo "❌ 远程Docker服务不可用"
    fi
fi

# 检测本地Docker
echo "🏠 检测本地Docker..."
LOCAL_DOCKER=false
if command -v docker &> /dev/null && docker info > /dev/null 2>&1; then
    echo "✅ 本地Docker可用"
    LOCAL_DOCKER=true
else
    echo "❌ 本地Docker不可用"
fi

# 检测网络质量
echo "📶 检测网络质量..."
NETWORK_QUALITY="unknown"
if [ "$REMOTE_AVAILABLE" = true ]; then
    # 测试网络延迟
    PING_TIME=$(ssh zjd "echo 'ping test'" 2>/dev/null | { time cat > /dev/null; } 2>&1 | grep real | awk '{print $2}' | sed 's/[^0-9.]//g' | head -1)
    if [ -n "$PING_TIME" ]; then
        echo "✅ 网络延迟检测完成"
        NETWORK_QUALITY="good"
    else
        NETWORK_QUALITY="slow"
    fi
fi

echo ""
echo "📊 环境检测结果："
echo "   远程服务器: $([ "$REMOTE_AVAILABLE" = true ] && echo "✅ 可用" || echo "❌ 不可用")"
echo "   远程Docker: $([ "$REMOTE_DOCKER" = true ] && echo "✅ 可用" || echo "❌ 不可用")"
echo "   本地Docker: $([ "$LOCAL_DOCKER" = true ] && echo "✅ 可用" || echo "❌ 不可用")"
echo "   网络质量: $NETWORK_QUALITY"

echo ""
echo "🎯 推荐模式："

# 智能选择逻辑
if [ "$REMOTE_AVAILABLE" = true ] && [ "$REMOTE_DOCKER" = true ] && [ "$NETWORK_QUALITY" = "good" ]; then
    echo "🥇 SSH + Dev Container 模式"
    echo "   理由：远程环境完整，网络良好，推荐一体化开发"
    echo ""
    echo "🚀 自动启用 SSH + Dev Container 模式..."
    echo ""
    echo "📋 接下来请："
    echo "1. 在VS Code中按 Ctrl+Shift+P (或 Cmd+Shift+P)"
    echo "2. 输入 'Remote-SSH: Connect to Host'"
    echo "3. 选择 'zjd'"
    echo "4. 打开文件夹 '/home/zjd/workspace'"
    echo "5. 点击 'Reopen in Container'"
    
elif [ "$REMOTE_DOCKER" = true ] && [ "$LOCAL_DOCKER" = true ]; then
    echo "🥈 远程Docker服务器模式"
    echo "   理由：本地和远程Docker都可用，推荐混合开发"
    echo ""
    echo "🚀 自动启用远程Docker服务器模式..."
    export DOCKER_HOST=ssh://zjd
    echo "export DOCKER_HOST=ssh://zjd" >> ~/.zshrc
    echo ""
    echo "✅ 已设置环境变量，重启终端后生效"
    echo "💡 现在可以使用: docker-compose up -d"
    
elif [ "$LOCAL_DOCKER" = true ]; then
    echo "🥉 本地Docker模式"
    echo "   理由：远程不可用，使用本地Docker开发"
    echo ""
    echo "🚀 自动启用本地Docker模式..."
    unset DOCKER_HOST
    echo ""
    echo "✅ 已清除远程Docker设置"
    echo "💡 现在可以在VS Code中使用 'Dev Containers: Reopen in Container'"
    
else
    echo "⚠️  无可用的Docker环境"
    echo "   建议：安装Docker Desktop或修复远程连接"
    echo ""
    echo "🛠️  解决方案："
    echo "1. 安装Docker Desktop: https://www.docker.com/products/docker-desktop/"
    echo "2. 检查远程服务器状态"
    echo "3. 检查SSH配置"
    exit 1
fi

echo ""
echo "🎉 自动配置完成！"
    echo "💡 如需手动切换，运行: bash config/scripts/dev-mode-selector.sh" 