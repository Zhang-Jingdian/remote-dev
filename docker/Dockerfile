# 使用官方Python基础镜像 
FROM python:3.11-slim

# 设置工作目录
WORKDIR /workspace

# 复制测试应用
COPY docker/test_app.py /workspace/test_app.py

# 暴露端口
EXPOSE 9000

# 默认运行测试应用（产生日志）
CMD ["python", "/workspace/test_app.py"] 