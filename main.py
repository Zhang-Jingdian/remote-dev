#!/usr/bin/env python3
"""
🚀 远程开发环境 - 后端API服务
作者: Zhang-Jingdian (2157429750@qq.com)
简化版本 - 保留核心功能，移除冗余复杂度
"""

import os
import sys
import json
import psutil
import subprocess
import threading
from datetime import datetime
from pathlib import Path

from flask import Flask, request, jsonify, render_template_string
from flask_cors import CORS
from flask_socketio import SocketIO, emit

# =============================================================================
# 应用初始化
# =============================================================================

app = Flask(__name__)
app.config['SECRET_KEY'] = 'remote-dev-env-secret-key'
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

CONFIG = {}
METRICS_HISTORY = []
MAX_HISTORY = 50  # 减少历史记录数量

# =============================================================================
# 配置管理
# =============================================================================

def load_env_config():
    """加载配置文件"""
    # 确定配置文件的绝对路径
    # Path(__file__) -> 当前文件 (main.py)
    # .parent -> 当前文件的父目录 (src/ 或者根目录)
    # .parent -> 再上一级父目录 (根目录)
    # 这样可以确保无论脚本从哪里运行，都能找到正确的config.env
    config_file = Path(__file__).parent / 'config.env'
    if not config_file.exists():
        # 如果在当前目录找不到，尝试在上一级目录找 (兼容旧结构)
        config_file = Path(__file__).parent.parent / 'config.env'
        
    config = {}
    
    if config_file.exists():
        with open(config_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    config[key.strip()] = value.strip().strip('"\'')
    else:
        print("⚠️ 警告: config.env 文件未找到，将使用默认值。")
    
    return config

def save_env_config(config):
    """保存配置文件"""
    config_file = Path(__file__).parent / 'config.env'
    if not config_file.exists():
        config_file = Path(__file__).parent.parent / 'config.env'

    with open(config_file, 'w', encoding='utf-8') as f:
        f.write("# 🚀 远程开发环境 - 简化配置\n\n")
        # 按照预设的顺序和分类写入，提高可读性
        f.write("# 远程服务器配置\n")
        f.write(f"SSH_ALIAS={config.get('SSH_ALIAS', 'remote-server')}\n")
        f.write(f"REMOTE_HOST={config.get('REMOTE_HOST', '192.168.1.100')}\n")
        f.write(f"REMOTE_USER={config.get('REMOTE_USER', 'user')}\n")
        f.write(f"REMOTE_PROJECT_PATH={config.get('REMOTE_PROJECT_PATH', '/tmp/workspace')}\n")
        f.write(f"SSH_PORT={config.get('SSH_PORT', 22)}\n\n")
        
        f.write("# 本地配置\n")
        f.write(f"LOCAL_PATH={config.get('LOCAL_PATH', './work')}\n")
        f.write(f"SYNC_EXCLUDE=\"{config.get('SYNC_EXCLUDE', '.git,node_modules')}\"\n\n")
        
        f.write("# 服务配置\n")
        f.write(f"WEB_PORT={config.get('WEB_PORT', 8080)}\n")
        f.write(f"API_PORT={config.get('API_PORT', 5001)}\n\n")

        f.write("# 日志配置\n")
        f.write(f"LOG_LEVEL={config.get('LOG_LEVEL', 'INFO')}\n")
        f.write(f"LOG_FILE={config.get('LOG_FILE', 'dev.log')}\n")

# =============================================================================
# 系统监控
# =============================================================================

def get_system_metrics():
    """获取系统指标"""
    try:
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        return {
            'timestamp': datetime.now().isoformat(),
            'cpu_percent': psutil.cpu_percent(interval=1),
            'memory': {
                'total': memory.total,
                'used': memory.used,
                'percent': memory.percent
            },
            'disk': {
                'total': disk.total,
                'used': disk.used,
                'percent': (disk.used / disk.total) * 100
            }
        }
    except Exception as e:
        return {'error': str(e)}

def get_docker_status():
    """检查Docker状态"""
    try:
        result = subprocess.run(['docker', 'ps'], capture_output=True, text=True, timeout=5)
        return {'running': result.returncode == 0, 'containers': len(result.stdout.splitlines()) - 1}
    except:
        return {'running': False, 'containers': 0}

def check_ssh_connection():
    """检查SSH连接"""
    remote_host = CONFIG.get('REMOTE_HOST', 'localhost')
    try:
        result = subprocess.run(['ping', '-c', '1', remote_host], 
                              capture_output=True, timeout=3)
        return result.returncode == 0
    except:
        return False

def metrics_broadcaster():
    """定期广播指标"""
    while True:
        try:
            metrics = get_system_metrics()
            METRICS_HISTORY.append(metrics)
            if len(METRICS_HISTORY) > MAX_HISTORY:
                METRICS_HISTORY.pop(0)
            
            socketio.emit('metrics_update', metrics)
            threading.Event().wait(10)  # 每10秒更新一次
        except:
            threading.Event().wait(30)  # 出错时等待30秒

# =============================================================================
# API路由
# =============================================================================

@app.route('/api/health')
def health_check():
    """健康检查"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()})

@app.route('/api/metrics')
def get_metrics():
    """获取当前系统指标"""
    metrics = get_system_metrics()
    docker_status = get_docker_status()
    ssh_status = check_ssh_connection()
    
    return jsonify({
        'system': metrics,
        'docker': docker_status,
        'ssh_connected': ssh_status
    })

@app.route('/api/metrics/history')
def get_metrics_history():
    """获取指标历史"""
    return jsonify(METRICS_HISTORY[-20:])  # 只返回最近20条

@app.route('/api/config', methods=['GET'])
def get_config():
    """获取配置"""
    return jsonify(CONFIG)

@app.route('/api/config', methods=['POST'])
def update_config():
    """更新配置"""
    try:
        data = request.get_json()
        if not data:
            return jsonify({'error': '无效的JSON数据'}), 400
        
        CONFIG.update(data)
        save_env_config(CONFIG)
        return jsonify({'success': True, 'message': '配置更新成功'})
    except Exception as e:
        return jsonify({'error': f'配置更新失败: {str(e)}'}), 500

@app.route('/api/sync', methods=['POST'])
def trigger_sync():
    """触发文件同步"""
    try:
        local_path = CONFIG.get('LOCAL_PATH', '.')
        remote_host = CONFIG.get('REMOTE_HOST', 'localhost')
        remote_path = CONFIG.get('REMOTE_PATH', '/tmp')
        
        cmd = f"rsync -av {local_path}/ {remote_host}:{remote_path}/"
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=30)
        
        return jsonify({
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr
        })
    except Exception as e:
        return jsonify({'error': f'同步失败: {str(e)}'}), 500

@app.route('/api/docker/<action>', methods=['POST'])
def docker_action(action):
    """Docker操作"""
    try:
        if action == 'up':
            cmd = 'docker-compose up -d'
        elif action == 'down':
            cmd = 'docker-compose down'
        elif action == 'restart':
            cmd = 'docker-compose restart'
        else:
            return jsonify({'error': '不支持的操作'}), 400
        
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60)
        
        return jsonify({
            'success': result.returncode == 0,
            'output': result.stdout,
            'error': result.stderr
        })
    except Exception as e:
        return jsonify({'error': f'Docker操作失败: {str(e)}'}), 500

@app.route('/api/status')
def get_status():
    """获取系统状态"""
    return jsonify({
        'server_time': datetime.now().isoformat(),
        'config_loaded': len(CONFIG) > 0,
        'docker': get_docker_status(),
        'ssh_connected': check_ssh_connection(),
        'metrics_history_count': len(METRICS_HISTORY)
    })

# =============================================================================
# WebSocket事件
# =============================================================================

@socketio.on('connect')
def handle_connect():
    """客户端连接"""
    emit('connected', {'message': '已连接到服务器'})

@socketio.on('request_metrics')
def handle_request_metrics():
    """请求指标更新"""
    metrics = get_system_metrics()
    emit('metrics_update', metrics)

# =============================================================================
# 主页面
# =============================================================================

@app.route('/')
def index():
    """首页 - 使用外部模板"""
    template = """
<!DOCTYPE html>
<html>
<head>
    <title>🚀 远程开发环境</title>
    <style>
        body { 
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            margin: 40px auto; max-width: 800px; background: #f5f5f5;
        }
        .container {
            background: white; padding: 30px; border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .btn { 
            display: inline-block; background: #3498db; color: white;
            padding: 10px 20px; text-decoration: none; border-radius: 4px;
            margin: 0 8px;
        }
        .btn:hover { background: #2980b9; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 远程开发环境</h1>
        <p>简化版远程开发环境管理界面</p>
        
        <h3>🔗 快速链接</h3>
        <a href="/api/health" class="btn">健康检查</a>
        <a href="/api/metrics" class="btn">系统指标</a>
        <a href="/api/status" class="btn">运行状态</a>
        
        <h3>🌐 API端点</h3>
        <ul>
            <li><code>GET /api/health</code> - 健康检查</li>
            <li><code>GET /api/metrics</code> - 系统指标</li>
            <li><code>GET /api/config</code> - 获取配置</li>
            <li><code>POST /api/sync</code> - 触发同步</li>
            <li><code>POST /api/docker/up</code> - 启动Docker</li>
        </ul>
    </div>
</body>
</html>
    """
    return render_template_string(template)

# =============================================================================
# 应用启动
# =============================================================================

def main():
    """主函数，加载配置并启动应用"""
    global CONFIG
    print("🚀 启动远程开发环境...")
    
    try:
        CONFIG = load_env_config()
        print(f"⚙️  加载配置: {len(CONFIG)} 项")
    except Exception as e:
        print(f"❌ 加载配置失败: {e}", file=sys.stderr)
        CONFIG = {}

    # 从配置中获取端口，如果失败则使用默认值
    api_port = int(CONFIG.get('API_PORT', 5001))
    print(f"🌐 服务端口: {api_port}")
    
    # 启动后台监控线程
    monitor_thread = threading.Thread(target=metrics_broadcaster, daemon=True)
    monitor_thread.start()

    # 启动Flask-SocketIO服务器
    try:
        socketio.run(app, host='0.0.0.0', port=api_port, debug=False)
    except OSError as e:
        print(f"❌ 启动失败: {e}", file=sys.stderr)
        if "Address already in use" in str(e):
            print(f"端口 {api_port} 已被占用。请检查或在 config.env 中更改 API_PORT。", file=sys.stderr)
            if sys.platform == "darwin":
                 print("在 macOS 上, 可尝试从 '系统偏好设置 -> 通用 -> Airdrop与接力' 中关闭 '隔空播放接收器' 服务。", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()
