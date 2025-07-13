#!/usr/bin/env python3
"""
远程开发环境示例应用
这是一个简单的Python应用，演示如何在远程容器中开发和运行代码
"""

import os
import sys
import datetime
from http.server import HTTPServer, BaseHTTPRequestHandler
import json


class SimpleHandler(BaseHTTPRequestHandler):
    """简单的HTTP请求处理器"""

    def do_GET(self):
        """处理GET请求"""
        if self.path == '/':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()

            # 使用 f-string 提高可读性
            html = f"""
            <!DOCTYPE html>
            <html>
            <head>
                <title>远程开发环境 🚀</title>
                <style>
                    body {{ font-family: Arial, sans-serif; margin: 40px; }}
                    h1 {{ color: #333; }}
                    .info {{ background: #f0f0f0; padding: 20px; border-radius: 8px; }}
                    .success {{ color: #28a745; }}
                </style>
            </head>
            <body>
                <h1>🎉 远程开发环境运行成功！</h1>
                <div class="info">
                    <p><strong>时间:</strong> {datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
                    <p><strong>Python版本:</strong> {sys.version}</p>
                    <p><strong>运行环境:</strong> 远程Docker容器</p>
                    <p class="success">✅ 本地编写代码，远程运行成功！</p>
                </div>
                <p><a href="/api/status">查看API状态</a></p>
            </body>
            </html>
            """
            self.wfile.write(html.encode())

        elif self.path == '/api/status':
            self.send_response(200)
            self.send_header('Content-type', 'application/json; charset=utf-8')
            self.end_headers()

            status = {
                "status": "running",
                "timestamp": datetime.datetime.now().isoformat(),
                "python_version": sys.version,
                "platform": sys.platform,
                "cwd": os.getcwd(),
                "message": "远程开发环境运行正常 🚀"
            }

            self.wfile.write(json.dumps(
                status, indent=2, ensure_ascii=False
            ).encode('utf-8'))

        else:
            self.send_response(404)
            self.end_headers()
            self.wfile.write(b'404 Not Found')


def main():
    """主函数"""
    print("🚀 启动远程开发环境示例应用...")
    print(f"📅 时间: {datetime.datetime.now()}")
    print(f"🐍 Python版本: {sys.version}")
    print(f"💻 运行平台: {sys.platform}")
    print(f"📁 当前目录: {os.getcwd()}")

    # 启动HTTP服务器
    port = int(os.environ.get('PORT', 8000))
    server = HTTPServer(('0.0.0.0', port), SimpleHandler)

    print(f"🌐 HTTP服务器启动在端口 {port}")
    print(f"🔗 访问地址: http://localhost:{port}")
    print("📝 在本地编写代码，在远程容器中运行！")
    print("🛑 按 Ctrl+C 停止服务器")

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n👋 服务器已停止")
        server.server_close()


if __name__ == "__main__":
    main()
