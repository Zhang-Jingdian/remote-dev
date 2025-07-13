#!/bin/bash

# 一键自动化设置脚本
# 自动配置整个远程开发环境，包括别名、智能检测等

echo "🎯 一键自动化设置开始！"
echo "================================"
echo ""
echo "这个脚本将为你："
echo "✅ 设置便利的命令别名"
echo "✅ 智能检测最佳开发模式"
echo "✅ 配置VS Code任务"
echo "✅ 让你以后只需要输入 'dev' 就能启动开发环境"
echo ""

read -p "🤔 是否继续？(y/n): " confirm
if [[ $confirm != [yY] ]]; then
    echo "❌ 设置已取消"
    exit 0
fi

echo ""
echo "🚀 开始自动化设置..."
echo ""

# 1. 设置别名
echo "📝 1. 设置命令别名..."
bash ./setup-aliases.sh

echo ""

# 2. 智能检测并设置最佳模式
echo "🤖 2. 智能检测最佳开发模式..."
bash ./auto-dev.sh

echo ""

# 3. 创建快速启动脚本
echo "⚡ 3. 创建快速启动脚本..."
cat > quick-dev.sh << 'EOF'
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
EOF

chmod +x quick-dev.sh

echo "✅ 已创建 quick-dev.sh"

echo ""

# 4. 显示使用说明
echo "🎊 设置完成！你现在拥有以下超级能力："
echo ""
echo "🎯 一键命令："
echo "   dev          - 🤖 智能启动（推荐！）"
echo "   dev1         - 🔗 SSH + Dev Container"
echo "   dev2         - 🏭 远程Docker服务器"
echo "   dev3         - 🏠 本地Docker"
echo ""
echo "🛠️  Docker管理："
echo "   devup        - ⬆️  启动服务"
echo "   devdown      - ⬇️  停止服务"
echo "   devlogs      - 📄 查看日志"
echo "   devstatus    - 📊 查看状态"
echo "   devreset     - 🔄 重启服务"
echo ""
echo "⚡ VS Code任务："
echo "   按 Ctrl+Shift+P，输入 'Tasks: Run Task'"
echo "   选择你想要的开发模式任务"
echo ""
echo "💡 重新打开终端，然后直接输入 'dev' 即可智能启动！"
echo ""
echo "🎉 从现在开始，你的开发环境启动就是一个命令的事情！"

# 5. 提示刷新shell
echo ""
echo "🔄 请重新打开终端或运行以下命令来激活别名："
echo "   source ~/.zshrc" 