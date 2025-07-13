#!/bin/bash

# 自动化别名设置脚本
# 为各种开发模式创建简短的命令别名

echo "⚙️  设置开发环境别名..."
echo "================================"

# 获取当前项目路径
PROJECT_PATH=$(pwd)

# 创建别名内容
ALIASES="
# 🚀 远程开发环境别名 (Auto-generated)
alias dev='cd $PROJECT_PATH && bash config/scripts/auto-dev.sh'                    # 智能选择模式
alias dev1='cd $PROJECT_PATH && bash config/scripts/start-dev.sh'                  # SSH + Dev Container
alias dev2='export DOCKER_HOST=ssh://zjd && echo \"✅ 远程Docker模式已启用\"'  # 远程Docker服务器
alias dev3='unset DOCKER_HOST && echo \"✅ 本地Docker模式已启用\"'           # 本地Docker
alias devup='docker-compose up -d'                               # 启动Docker服务
alias devdown='docker-compose down'                              # 停止Docker服务
alias devlogs='docker-compose logs -f'                           # 查看Docker日志
alias devstatus='docker-compose ps'                              # 查看服务状态
alias devreset='docker-compose down && docker-compose up -d'     # 重启服务
"

# 检测shell类型并添加别名
if [[ $SHELL == *"zsh"* ]]; then
    echo "🐚 检测到 Zsh，添加别名到 ~/.zshrc"
    
    # 移除旧的别名（如果存在）
    if [[ -f ~/.zshrc ]]; then
        sed -i '' '/# 🚀 远程开发环境别名/,/^$/d' ~/.zshrc
    fi
    
    # 添加新别名
    echo "$ALIASES" >> ~/.zshrc
    
    echo "✅ 已添加到 ~/.zshrc"
    
elif [[ $SHELL == *"bash"* ]]; then
    echo "🐚 检测到 Bash，添加别名到 ~/.bashrc"
    
    # 移除旧的别名（如果存在）
    if [[ -f ~/.bashrc ]]; then
        sed -i '' '/# 🚀 远程开发环境别名/,/^$/d' ~/.bashrc
    fi
    
    # 添加新别名
    echo "$ALIASES" >> ~/.bashrc
    
    echo "✅ 已添加到 ~/.bashrc"
    
else
    echo "⚠️  未知shell类型，请手动添加以下别名："
    echo "$ALIASES"
fi

echo ""
echo "🎉 别名设置完成！"
echo ""
echo "🚀 可用的命令："
echo "   dev      - 🤖 智能选择最佳模式"
echo "   dev1     - 🔗 SSH + Dev Container 模式"
echo "   dev2     - 🏭 远程Docker服务器模式"
echo "   dev3     - 🏠 本地Docker模式"
echo "   devup    - ⬆️  启动Docker服务"
echo "   devdown  - ⬇️  停止Docker服务"
echo "   devlogs  - 📄 查看服务日志"
echo "   devstatus- 📊 查看服务状态"
echo "   devreset - 🔄 重启所有服务"
echo ""
echo "💡 重新打开终端或运行 'source ~/.zshrc' 使别名生效"
echo ""
echo "🎯 现在你可以直接输入 'dev' 来智能启动开发环境！" 