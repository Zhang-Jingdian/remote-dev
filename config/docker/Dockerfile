# 高性能多阶段Docker镜像

# 基础镜像阶段
FROM python:3.11-slim as base

# 设置环境变量
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    POETRY_VERSION=1.6.1

# 创建非root用户
RUN groupadd -r appuser && useradd -r -g appuser appuser

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 安装Poetry
RUN pip install poetry==$POETRY_VERSION

# 依赖安装阶段
FROM base as dependencies

WORKDIR /app

# 复制依赖文件
COPY pyproject.toml poetry.lock* ./

# 配置Poetry
RUN poetry config virtualenvs.create false

# 安装依赖
RUN poetry install --no-dev --no-interaction --no-ansi

# 开发环境阶段
FROM dependencies as development

# 安装开发依赖
RUN poetry install --no-interaction --no-ansi

# 复制应用代码
COPY . .

# 设置权限
RUN chown -R appuser:appuser /app

USER appuser

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 启动命令
CMD ["python", "src/main.py"]

# 生产环境阶段
FROM dependencies as production

# 复制应用代码
COPY --chown=appuser:appuser . .

# 安全加固
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && update-ca-certificates

# 移除不必要的包
RUN apt-get purge -y --auto-remove build-essential \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 设置安全权限
RUN chmod -R 755 /app \
    && find /app -name "*.py" -exec chmod 644 {} \;

USER appuser

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# 启动命令
CMD ["python", "-O", "src/main.py"]

# 测试阶段
FROM development as test

# 安装测试依赖
RUN poetry install --with test --no-interaction --no-ansi

# 复制测试文件
COPY tests/ tests/

# 运行测试
RUN python -m pytest tests/ -v --cov=src --cov-report=html

# 压缩阶段 - 最小化镜像
FROM python:3.11-alpine as minimal

# 安装运行时依赖
RUN apk add --no-cache \
    ca-certificates \
    curl \
    && update-ca-certificates

# 创建用户
RUN addgroup -S appuser && adduser -S appuser -G appuser

# 复制应用和依赖
COPY --from=production /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=production --chown=appuser:appuser /app /app

WORKDIR /app
USER appuser

# 暴露端口
EXPOSE 8000

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 启动命令
CMD ["python", "-O", "src/main.py"] 