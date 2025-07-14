#!/usr/bin/env python3
"""
🚀 远程开发环境 - 简单测试
作者: Zhang-Jingdian (2157429750@qq.com)
创建时间: 2025年7月14日

简单的测试来验证重构后的功能
"""

import os
import sys
import subprocess
import tempfile
from pathlib import Path

def test_config_exists():
    """测试配置文件是否存在"""
    config_file = Path("config.env")
    assert config_file.exists(), "配置文件不存在"
    print("✓ 配置文件存在")

def test_dev_script_executable():
    """测试dev脚本是否可执行"""
    dev_script = Path("dev")
    assert dev_script.exists(), "dev脚本不存在"
    assert os.access(dev_script, os.X_OK), "dev脚本不可执行"
    print("✓ dev脚本可执行")

def test_dev_help():
    """测试dev帮助命令"""
    try:
        result = subprocess.run(["./dev", "help"], capture_output=True, text=True)
        assert result.returncode == 0, "help命令执行失败"
        assert "远程开发环境" in result.stdout, "help输出内容不正确"
        print("✓ dev help命令正常")
    except Exception as e:
        print(f"✗ dev help命令失败: {e}")
        sys.exit(1)

def test_config_loading():
    """测试配置加载"""
    try:
        # 创建临时配置文件
        with tempfile.NamedTemporaryFile(mode='w', suffix='.env', delete=False) as f:
            f.write("TEST_KEY=test_value\n")
            f.write("SSH_ALIAS=test-server\n")
            temp_config = f.name
        
        # 读取配置
        config = {}
        with open(temp_config, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    config[key.strip()] = value.strip()
        
        assert config.get('TEST_KEY') == 'test_value', "配置读取失败"
        assert config.get('SSH_ALIAS') == 'test-server', "配置读取失败"
        
        # 清理
        os.unlink(temp_config)
        print("✓ 配置加载功能正常")
    except Exception as e:
        print(f"✗ 配置加载测试失败: {e}")
        sys.exit(1)

def test_python_backend_syntax():
    """测试Python后端语法"""
    try:
        result = subprocess.run([
            sys.executable, "-m", "py_compile", "main.py"
        ], capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"✗ Python后端语法错误: {result.stderr}")
            sys.exit(1)
        else:
            print("✓ Python后端语法正确")
    except Exception as e:
        print(f"✗ Python后端测试失败: {e}")
        sys.exit(1)

def test_requirements_file():
    """测试requirements.txt文件"""
    req_file = Path("docker/requirements.txt")
    assert req_file.exists(), "requirements.txt不存在"
    
    with open(req_file, 'r') as f:
        content = f.read()
        assert "Flask" in content, "Flask依赖缺失"
        assert "psutil" in content, "psutil依赖缺失"
        
    print("✓ requirements.txt文件正确")

def test_docker_files():
    """测试Docker配置文件"""
    dockerfile = Path("docker/Dockerfile")
    compose_file = Path("docker/docker-compose.yml")
    
    assert dockerfile.exists(), "Dockerfile不存在"
    assert compose_file.exists(), "docker-compose.yml不存在"
    
    print("✓ Docker配置文件存在")

def main():
    """运行所有测试"""
    print("🧪 开始运行简单测试...")
    print("=" * 40)
    
    tests = [
        test_config_exists,
        test_dev_script_executable,
        test_dev_help,
        test_config_loading,
        test_python_backend_syntax,
        test_requirements_file,
        test_docker_files
    ]
    
    failed_tests = 0
    
    for test in tests:
        try:
            test()
        except Exception as e:
            print(f"✗ {test.__name__} 失败: {e}")
            failed_tests += 1
    
    print("=" * 40)
    
    if failed_tests == 0:
        print("🎉 所有测试通过！")
        print("💡 项目重构成功，可以开始使用了")
        print("\n🚀 下一步:")
        print("  1. 运行 './dev setup' 初始化环境")
        print("  2. 运行 'python main.py' 启动后端API")
        print("  3. 运行 'cd web && npm run dev' 启动前端")
        return 0
    else:
        print(f"❌ {failed_tests} 个测试失败")
        return 1

if __name__ == "__main__":
    sys.exit(main()) 