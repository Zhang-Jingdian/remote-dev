#!/usr/bin/env python3

"""
远程开发环境 Web 管理界面
提供可视化的集群管理、配置管理和监控功能
"""

import os
import sys
import json
import yaml
import subprocess
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path

from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
from flask_socketio import SocketIO, emit
from werkzeug.security import generate_password_hash, check_password_hash

# 添加项目根目录到路径
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key-change-in-production'
socketio = SocketIO(app, cors_allowed_origins="*")

# 配置路径
CONFIG_DIR = project_root / "config"
DYNAMIC_CONFIG_DIR = CONFIG_DIR / "dynamic"
CLUSTER_CONFIG_DIR = CONFIG_DIR / "cluster"
PLUGINS_DIR = CONFIG_DIR / "plugins"

# 全局状态
app_state = {
    'cluster_status': {},
    'system_metrics': {},
    'active_connections': 0,
    'last_update': None
}

class ConfigManager:
    """配置管理器"""
    
    def __init__(self):
        self.active_config_file = DYNAMIC_CONFIG_DIR / "active.json"
        self.cluster_config_file = CLUSTER_CONFIG_DIR / "servers.yml"
    
    def get_active_config(self):
        """获取活跃配置"""
        try:
            if self.active_config_file.exists():
                with open(self.active_config_file, 'r') as f:
                    return json.load(f)
            return {}
        except Exception as e:
            print(f"Error reading active config: {e}")
            return {}
    
    def update_config(self, key, value, modified_by="web"):
        """更新配置"""
        try:
            # 调用配置管理脚本
            script_path = CONFIG_DIR / "dynamic" / "config_manager.sh"
            result = subprocess.run([
                'bash', '-c', 
                f'source {script_path} && update_config "{key}" "{value}" "{modified_by}"'
            ], capture_output=True, text=True)
            
            return result.returncode == 0, result.stdout + result.stderr
        except Exception as e:
            return False, str(e)
    
    def get_cluster_config(self):
        """获取集群配置"""
        try:
            if self.cluster_config_file.exists():
                with open(self.cluster_config_file, 'r') as f:
                    return yaml.safe_load(f)
            return {}
        except Exception as e:
            print(f"Error reading cluster config: {e}")
            return {}

class ClusterManager:
    """集群管理器"""
    
    def __init__(self):
        self.cluster_state_file = Path("/tmp/cluster-state.json")
    
    def get_cluster_status(self):
        """获取集群状态"""
        try:
            if self.cluster_state_file.exists():
                with open(self.cluster_state_file, 'r') as f:
                    return json.load(f)
            return {}
        except Exception as e:
            print(f"Error reading cluster status: {e}")
            return {}
    
    def health_check(self, server_name=None):
        """执行健康检查"""
        try:
            script_path = CONFIG_DIR / "cluster" / "manager.sh"
            if server_name:
                cmd = f'source {script_path} && health_check_server "{server_name}"'
            else:
                cmd = f'source {script_path} && cluster_health_check'
            
            result = subprocess.run([
                'bash', '-c', cmd
            ], capture_output=True, text=True)
            
            return result.returncode == 0, result.stdout + result.stderr
        except Exception as e:
            return False, str(e)

class PluginManager:
    """插件管理器"""
    
    def __init__(self):
        self.registry_file = PLUGINS_DIR / "registry.json"
        self.config_file = PLUGINS_DIR / "config.yml"
    
    def get_plugins(self):
        """获取插件列表"""
        try:
            if self.registry_file.exists():
                with open(self.registry_file, 'r') as f:
                    return json.load(f)
            return {"plugins": {}}
        except Exception as e:
            print(f"Error reading plugins: {e}")
            return {"plugins": {}}
    
    def toggle_plugin(self, plugin_name, enabled):
        """启用/禁用插件"""
        try:
            script_path = CONFIG_DIR / "plugins" / "manager.sh"
            action = "enable_plugin" if enabled else "disable_plugin"
            
            result = subprocess.run([
                'bash', '-c', 
                f'source {script_path} && {action} "{plugin_name}"'
            ], capture_output=True, text=True)
            
            return result.returncode == 0, result.stdout + result.stderr
        except Exception as e:
            return False, str(e)

# 初始化管理器
config_manager = ConfigManager()
cluster_manager = ClusterManager()
plugin_manager = PluginManager()

@app.route('/')
def dashboard():
    """仪表板"""
    config = config_manager.get_active_config()
    cluster_status = cluster_manager.get_cluster_status()
    plugins = plugin_manager.get_plugins()
    
    return render_template('dashboard.html', 
                         config=config,
                         cluster_status=cluster_status,
                         plugins=plugins,
                         app_state=app_state)

@app.route('/config')
def config_page():
    """配置管理页面"""
    config = config_manager.get_active_config()
    return render_template('config.html', config=config)

@app.route('/api/config', methods=['GET', 'POST'])
def api_config():
    """配置API"""
    if request.method == 'GET':
        return jsonify(config_manager.get_active_config())
    
    elif request.method == 'POST':
        data = request.json
        key = data.get('key')
        value = data.get('value')
        
        if not key:
            return jsonify({'error': 'Missing key'}), 400
        
        success, message = config_manager.update_config(key, value)
        
        if success:
            # 通知所有连接的客户端配置已更新
            socketio.emit('config_updated', {'key': key, 'value': value})
            return jsonify({'success': True, 'message': message})
        else:
            return jsonify({'error': message}), 500

@app.route('/cluster')
def cluster_page():
    """集群管理页面"""
    cluster_config = config_manager.get_cluster_config()
    cluster_status = cluster_manager.get_cluster_status()
    
    return render_template('cluster.html', 
                         cluster_config=cluster_config,
                         cluster_status=cluster_status)

@app.route('/api/cluster/status')
def api_cluster_status():
    """获取集群状态API"""
    return jsonify(cluster_manager.get_cluster_status())

@app.route('/api/cluster/health-check', methods=['POST'])
def api_cluster_health_check():
    """集群健康检查API"""
    data = request.json or {}
    server_name = data.get('server_name')
    
    success, message = cluster_manager.health_check(server_name)
    
    if success:
        # 更新状态并通知客户端
        cluster_status = cluster_manager.get_cluster_status()
        socketio.emit('cluster_status_updated', cluster_status)
        return jsonify({'success': True, 'message': message})
    else:
        return jsonify({'error': message}), 500

@app.route('/plugins')
def plugins_page():
    """插件管理页面"""
    plugins = plugin_manager.get_plugins()
    return render_template('plugins.html', plugins=plugins)

@app.route('/api/plugins')
def api_plugins():
    """获取插件列表API"""
    return jsonify(plugin_manager.get_plugins())

@app.route('/api/plugins/<plugin_name>/toggle', methods=['POST'])
def api_toggle_plugin(plugin_name):
    """启用/禁用插件API"""
    data = request.json
    enabled = data.get('enabled', False)
    
    success, message = plugin_manager.toggle_plugin(plugin_name, enabled)
    
    if success:
        # 通知所有客户端插件状态已更新
        socketio.emit('plugin_toggled', {
            'plugin_name': plugin_name, 
            'enabled': enabled
        })
        return jsonify({'success': True, 'message': message})
    else:
        return jsonify({'error': message}), 500

@app.route('/monitoring')
def monitoring_page():
    """监控页面"""
    return render_template('monitoring.html')

@app.route('/api/metrics')
def api_metrics():
    """获取系统指标API"""
    # 这里可以集成Prometheus或其他监控系统
    metrics = {
        'timestamp': datetime.now().isoformat(),
        'cpu_usage': 45.2,
        'memory_usage': 67.8,
        'disk_usage': 34.1,
        'network_io': {
            'bytes_sent': 1024000,
            'bytes_recv': 2048000
        },
        'active_connections': app_state['active_connections'],
        'uptime': str(timedelta(seconds=int(time.time() - app.start_time)))
    }
    
    app_state['system_metrics'] = metrics
    return jsonify(metrics)

@app.route('/logs')
def logs_page():
    """日志查看页面"""
    return render_template('logs.html')

@app.route('/api/logs')
def api_logs():
    """获取日志API"""
    log_type = request.args.get('type', 'system')
    lines = int(request.args.get('lines', 100))
    
    try:
        if log_type == 'system':
            # 读取系统日志
            result = subprocess.run(['tail', '-n', str(lines), '/var/log/syslog'], 
                                  capture_output=True, text=True)
        elif log_type == 'docker':
            # 读取Docker日志
            result = subprocess.run(['docker', 'logs', '--tail', str(lines), 'workspace_web_1'], 
                                  capture_output=True, text=True)
        else:
            return jsonify({'error': 'Invalid log type'}), 400
        
        logs = result.stdout.split('\n')
        return jsonify({'logs': logs})
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# WebSocket事件处理
@socketio.on('connect')
def handle_connect():
    """客户端连接"""
    app_state['active_connections'] += 1
    emit('connected', {'message': 'Connected to Dev Environment Manager'})
    print(f'Client connected. Active connections: {app_state["active_connections"]}')

@socketio.on('disconnect')
def handle_disconnect():
    """客户端断开连接"""
    app_state['active_connections'] -= 1
    print(f'Client disconnected. Active connections: {app_state["active_connections"]}')

@socketio.on('request_status')
def handle_status_request():
    """客户端请求状态更新"""
    config = config_manager.get_active_config()
    cluster_status = cluster_manager.get_cluster_status()
    plugins = plugin_manager.get_plugins()
    
    emit('status_update', {
        'config': config,
        'cluster_status': cluster_status,
        'plugins': plugins,
        'app_state': app_state
    })

def background_tasks():
    """后台任务"""
    while True:
        try:
            # 更新集群状态
            cluster_status = cluster_manager.get_cluster_status()
            if cluster_status != app_state.get('cluster_status'):
                app_state['cluster_status'] = cluster_status
                socketio.emit('cluster_status_updated', cluster_status)
            
            # 更新系统指标
            metrics = {
                'timestamp': datetime.now().isoformat(),
                'active_connections': app_state['active_connections']
            }
            socketio.emit('metrics_updated', metrics)
            
            app_state['last_update'] = datetime.now().isoformat()
            
        except Exception as e:
            print(f"Background task error: {e}")
        
        time.sleep(10)  # 每10秒更新一次

if __name__ == '__main__':
    # 记录启动时间
    app.start_time = time.time()
    
    # 启动后台任务
    background_thread = threading.Thread(target=background_tasks, daemon=True)
    background_thread.start()
    
    # 启动Web服务器
    print("🚀 启动远程开发环境 Web 管理界面...")
    print("📱 访问地址: http://localhost:8080")
    
    socketio.run(app, 
                host='0.0.0.0', 
                port=8080, 
                debug=False,
                allow_unsafe_werkzeug=True) 