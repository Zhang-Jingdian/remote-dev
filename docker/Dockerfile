# 🚀 远程开发环境 - 简化Dockerfile
# 作者: Zhang-Jingdian (2157429750@qq.com)  
# 创建时间: 2025年7月14日

FROM python:3.11-slim

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    openssh-client \
    rsync \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 复制并安装Python依赖
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 复制应用代码
COPY src/ .
COPY config.env .

# 创建日志目录
RUN mkdir -p logs

# 暴露端口
EXPOSE 8080 5000

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/api/health || exit 1

# 启动应用
CMD ["python", "main.py"] 