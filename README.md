# 🚀 远程开发环境管理工具

一个简洁高效的远程开发环境管理工具，支持Python、Node.js等多种开发环境。

## ✨ 特性

- 🚀 **一键启动**: `./dev setup` 完成环境初始化
- 🐳 **Docker容器**: 隔离的开发环境，支持Python、Node.js
- 📁 **智能同步**: 自动同步本地代码到远程容器
- 💻 **交互式Shell**: 美观的远程开发终端
- 🔄 **文件监控**: 实时监控文件变化并自动同步
- 🧪 **内置测试**: 完整的系统测试套件

## 🚀 快速开始

### 1. 初始化环境
```bash
./dev setup
```

### 2. 启动开发环境
```bash
dev up
```

### 3. 进入开发
```bash
dev remote bash
```

## 📋 命令参考

| 命令 | 功能 | 示例 |
|------|------|------|
| `setup` | 初始化环境 | `./dev setup` |
| `up` | 启动容器 | `dev up` |
| `down` | 停止容器 | `dev down` |
| `remote` | 远程执行命令 | `dev remote bash` |
| `sync` | 同步文件 | `dev sync` |
| `watch` | 监控文件变化 | `dev watch` |
| `status` | 查看状态 | `dev status` |
| `logs` | 查看日志 | `dev logs` |

## 🛠️ 开发环境

容器内预装工具：
- **Python 3.11** + pip
- **Node.js 18** + npm
- **Git** + 常用开发工具
- **Vim/Nano** 编辑器
- **htop** 系统监控

## 📁 项目结构

```
workspace/
├── dev                    # 主CLI工具
├── config.env             # 配置文件
├── docker/                # Docker配置
│   ├── Dockerfile         # 容器镜像
│   ├── docker-compose.yml # 容器编排
│   ├── requirements.txt   # Python依赖
│   ├── .remote_bashrc    # Shell配置
│   └── logs/             # 日志目录
├── work/                  # 工作空间
└── README.md             # 文档
```

## ⚙️ 配置

编辑 `config.env` 自定义配置：

```bash
# 远程服务器配置
REMOTE_HOST=192.168.0.105
REMOTE_USER=zjd
REMOTE_PATH=/home/zjd/workspace

# 本地配置
LOCAL_PATH=./work
```

## 🔧 自定义开发环境

### 添加新的开发工具

编辑 `docker/Dockerfile`：

```dockerfile
# 安装Go
RUN wget https://go.dev/dl/go1.21.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.linux-amd64.tar.gz && \
    export PATH=$PATH:/usr/local/go/bin

# 安装Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
```

### 自定义Shell环境

编辑 `docker/.remote_bashrc`：

```bash
# 添加自定义别名
alias mytool='echo "Hello from remote!"'

# 设置环境变量
export MY_VAR="value"
```


## 📝 更新日志

### v4.3 (最新)
- 🚀 **多环境支持**: 添加Node.js、Git等开发工具
- 🎯 **简化提示**: 优化setup后的用户引导
- 📚 **精简文档**: 重写README，更简洁高效
- 🔧 **增强配置**: 支持更多开发环境自定义

### v4.2
- 🎯 **终极简化**: 将所有功能集成到单个`dev`脚本
- 🚀 **一键setup**: 依赖检查+配置创建+别名安装一站式完成
- 🧪 **内置测试**: 完整测试套件集成到dev脚本中

## 📄 许可证

MIT License

## 👨‍💻 作者

Zhang-Jingdian (2157429750@qq.com)

---

🚀 **Happy Coding!** 享受高效的远程开发体验！
