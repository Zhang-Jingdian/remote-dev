# 使用官方Python基础镜像，并安装Node.js和其他开发工具
FROM python:3.11-slim

# 安装系统依赖和Node.js
RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim \
    nano \
    htop \
    wget \
    unzip \
    && curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置工作目录
WORKDIR /workspace

# 复制测试应用
COPY docker/test_app.py /workspace/test_app.py

# 暴露端口
EXPOSE 9000

# 默认运行测试应用（产生日志）
CMD ["python", "/workspace/test_app.py"] 