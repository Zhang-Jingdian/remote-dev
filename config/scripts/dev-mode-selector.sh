#!/bin/bash

# 开发模式选择脚本
# 让用户在SSH+DevContainer和远程Docker服务器之间选择

echo "🚀 选择你的开发模式"
echo "================================"
echo ""
echo "1️⃣  SSH + Dev Container 模式"
echo "   📍 特点：代码在远程，一体化开发体验"
echo "   🎯 适合：长期开发会话，不想管理本地Docker"
echo ""
echo "2️⃣  远程Docker服务器模式"
echo "   📍 特点：代码在本地，构建在远程"
echo "   🎯 适合：快速本地编辑，强大远程构建"
echo ""
echo "3️⃣  恢复本地Docker模式"
echo "   📍 特点：完全本地开发"
echo "   🎯 适合：离线开发，网络不稳定时"
echo ""

read -p "请选择模式 (1/2/3): " choice

case $choice in
    1)
        echo ""
        echo "🔧 选择了：SSH + Dev Container 模式"
        echo "================================"
        echo ""
        echo "✅ 这是你当前的默认模式！"
        echo ""
        echo "🎯 接下来请："
        echo "1. 在VS Code中按 F1"
        echo "2. 输入 'Remote-SSH: Connect to Host'"
        echo "3. 选择 'zjd'"
        echo "4. 打开文件夹 '/home/zjd/workspace'"
        echo "5. 在提示中点击 'Reopen in Container'"
        echo ""
        echo "💡 提示：代码会在远程服务器上，通过SSH编辑"
        ;;
    2)
        echo ""
        echo "🔧 选择了：远程Docker服务器模式"
        echo "================================"
        echo ""
        echo "🔍 检查本地Docker..."
        if ! command -v docker &> /dev/null; then
            echo "❌ 本地Docker未安装"
            echo "💡 请先安装Docker Desktop：https://www.docker.com/products/docker-desktop/"
            exit 1
        fi
        
        echo "✅ 本地Docker已安装"
        
        echo "🔍 检查远程Docker服务器..."
        if ! ssh -o ConnectTimeout=5 -o BatchMode=yes zjd "docker --version" > /dev/null 2>&1; then
            echo "❌ 远程Docker服务器不可用"
            echo "💡 请确保远程服务器Docker服务正在运行"
            exit 1
        fi
        
        echo "✅ 远程Docker服务器可用"
        
        # 配置Docker使用远程服务器
        export DOCKER_HOST=ssh://zjd
        echo "export DOCKER_HOST=ssh://zjd" >> ~/.bashrc
        echo "export DOCKER_HOST=ssh://zjd" >> ~/.zshrc
        
        echo ""
        echo "🎉 远程Docker服务器模式已启用！"
        echo ""
        echo "🧪 测试连接..."
        docker info | grep -E "(Server Version|Operating System)" || echo "连接测试失败"
        
        echo ""
        echo "🎯 现在你可以："
        echo "1. 在本地VS Code中正常打开项目"
        echo "2. 使用 'docker-compose up' 等命令（会在远程执行）"
        echo "3. 享受本地编辑 + 远程构建的体验"
        echo ""
        echo "💡 提示：重新打开终端后设置会自动生效"
        ;;
    3)
        echo ""
        echo "🔧 选择了：本地Docker模式"
        echo "================================"
        echo ""
        echo "🔄 恢复本地Docker设置..."
        
        # 清除远程Docker设置
        unset DOCKER_HOST
        
        # 从配置文件中移除（如果存在）
        if [[ -f ~/.bashrc ]]; then
            sed -i '' '/export DOCKER_HOST=ssh:\/\/zjd/d' ~/.bashrc
        fi
        if [[ -f ~/.zshrc ]]; then
            sed -i '' '/export DOCKER_HOST=ssh:\/\/zjd/d' ~/.zshrc
        fi
        
        echo "✅ 已恢复本地Docker模式"
        echo ""
        echo "🎯 现在你可以："
        echo "1. 使用本地Docker进行开发"
        echo "2. 在VS Code中使用 'Dev Containers: Reopen in Container'"
        echo "3. 完全离线开发"
        echo ""
        echo "💡 提示：重新打开终端后设置会自动生效"
        ;;
    *)
        echo "❌ 无效选择，请重新运行脚本"
        exit 1
        ;;
esac

echo ""
echo "🎊 配置完成！享受你的开发体验！" 