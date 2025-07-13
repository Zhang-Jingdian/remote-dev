#!/bin/bash

# 手动安装依赖脚本
# 在容器内部运行，解决网络代理问题

echo "🛠️  手动安装开发环境依赖..."
echo "================================"

# 清除代理设置
echo "🔧 清除代理设置..."
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY

# 更新pip
echo "📦 更新pip..."
pip install --upgrade pip --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org

# 安装Python依赖
echo "🐍 安装Python依赖包..."
pip install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org -r config/docker/requirements.txt

# 安装系统工具（可选）
echo "🔧 安装系统工具..."
echo "如果需要安装系统工具，请运行："
echo "  apt-get update && apt-get install -y git curl wget vim htop"

echo ""
echo "✅ 依赖安装完成！"
echo "💡 如果遇到网络问题，请检查网络连接或联系管理员" 