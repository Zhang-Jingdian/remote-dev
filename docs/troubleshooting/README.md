# 🔧 故障排除指南

> 远程开发环境常见问题的诊断和解决方案，快速定位和修复系统故障

## 🚨 故障诊断流程

### 故障处理总览

```mermaid
graph TB
    A[故障报告] --> B[初步诊断]
    B --> C[问题分类]
    C --> D[深度分析]
    D --> E[解决方案]
    E --> F[问题修复]
    F --> G[验证修复]
    G --> H[文档更新]
    
    B --> I[收集信息]
    B --> J[环境检查]
    B --> K[日志分析]
    
    C --> L[系统问题]
    C --> M[网络问题]
    C --> N[应用问题]
    C --> O[配置问题]
    
    style A fill:#ffebee
    style H fill:#e8f5e8
    style I fill:#fff3e0
    style J fill:#fff3e0
    style K fill:#fff3e0
```

### 诊断决策树

```mermaid
flowchart TD
    A[系统故障] --> B{服务能启动?}
    B -->|否| C[检查依赖]
    B -->|是| D{能正常访问?}
    
    C --> E[安装缺失依赖]
    C --> F[检查配置文件]
    C --> G[检查权限设置]
    
    D -->|否| H[检查网络连接]
    D -->|是| I{性能正常?}
    
    H --> J[检查防火墙]
    H --> K[检查端口占用]
    H --> L[检查DNS解析]
    
    I -->|否| M[检查资源使用]
    I -->|是| N[检查应用逻辑]
    
    M --> O[CPU/内存优化]
    M --> P[磁盘空间清理]
    
    N --> Q[检查日志错误]
    N --> R[检查数据库连接]
    
    style A fill:#ffebee
    style E fill:#e8f5e8
    style F fill:#e8f5e8
    style G fill:#e8f5e8
    style J fill:#e8f5e8
    style K fill:#e8f5e8
    style L fill:#e8f5e8
    style O fill:#e8f5e8
    style P fill:#e8f5e8
    style Q fill:#e8f5e8
    style R fill:#e8f5e8
```

## 🔍 常见问题分类

### 问题类型分布

```mermaid
pie title 故障类型分布
    "网络连接问题" : 35
    "配置错误" : 25
    "权限问题" : 20
    "性能问题" : 15
    "其他问题" : 5
```

### 问题严重程度

```mermaid
graph LR
    A[问题严重程度] --> B[紧急]
    A --> C[高]
    A --> D[中]
    A --> E[低]
    
    B --> F[系统完全不可用<br/>影响所有用户<br/>需要立即处理]
    C --> G[核心功能异常<br/>影响大部分用户<br/>4小时内处理]
    D --> H[部分功能异常<br/>影响部分用户<br/>24小时内处理]
    E --> I[轻微问题<br/>影响很少用户<br/>72小时内处理]
    
    style B fill:#ffebee
    style C fill:#fff3e0
    style D fill:#f3e5f5
    style E fill:#e8f5e8
```

## 🌐 网络连接问题

### SSH连接故障

```mermaid
graph TB
    A[SSH连接失败] --> B[检查网络连通性]
    B --> C[ping测试]
    B --> D[telnet端口测试]
    B --> E[traceroute路由测试]
    
    C --> F{ping通?}
    F -->|否| G[网络不可达]
    F -->|是| H[网络正常]
    
    D --> I{端口开放?}
    I -->|否| J[端口被封锁]
    I -->|是| K[端口正常]
    
    G --> L[检查网络配置]
    G --> M[检查防火墙]
    
    J --> N[开放SSH端口]
    J --> O[检查SSH服务]
    
    style A fill:#ffebee
    style G fill:#ffebee
    style J fill:#ffebee
    style L fill:#fff3e0
    style M fill:#fff3e0
    style N fill:#e8f5e8
    style O fill:#e8f5e8
```

**解决方案:**

1. **网络连通性检查**
```bash
# 检查网络连接
ping -c 4 192.168.0.105

# 检查端口连通性
telnet 192.168.0.105 22

# 路由追踪
traceroute 192.168.0.105
```

2. **SSH服务检查**
```bash
# 检查SSH服务状态
sudo systemctl status sshd

# 重启SSH服务
sudo systemctl restart sshd

# 检查SSH配置
sudo sshd -t
```

3. **防火墙配置**
```bash
# 检查防火墙状态
sudo ufw status

# 开放SSH端口
sudo ufw allow 22

# 检查iptables规则
sudo iptables -L
```

### 隧道连接问题

```mermaid
sequenceDiagram
    participant Client as 客户端
    participant Tunnel as SSH隧道
    participant Server as 远程服务器
    participant Service as 目标服务
    
    Client->>Tunnel: 建立隧道
    Tunnel->>Server: SSH连接
    
    alt 连接成功
        Server->>Tunnel: 连接确认
        Tunnel->>Client: 隧道建立
        Client->>Service: 通过隧道访问
    else 连接失败
        Server->>Tunnel: 连接拒绝
        Tunnel->>Client: 隧道失败
        Client->>Client: 错误处理
    end
```

**诊断命令:**
```bash
# 检查隧道状态
./dev tunnel status

# 重新建立隧道
./dev tunnel restart

# 检查端口转发
netstat -tlnp | grep :8080
```

## ⚙️ 配置问题

### 配置文件错误

```mermaid
graph TB
    A[配置错误] --> B[语法错误]
    A --> C[路径错误]
    A --> D[权限错误]
    A --> E[值错误]
    
    B --> F[检查配置语法]
    C --> G[验证文件路径]
    D --> H[检查文件权限]
    E --> I[验证配置值]
    
    F --> J[修复语法错误]
    G --> K[更正文件路径]
    H --> L[设置正确权限]
    I --> M[更新配置值]
    
    style A fill:#ffebee
    style B fill:#ffebee
    style C fill:#ffebee
    style D fill:#ffebee
    style E fill:#ffebee
    style J fill:#e8f5e8
    style K fill:#e8f5e8
    style L fill:#e8f5e8
    style M fill:#e8f5e8
```

**配置验证工具:**

```bash
# 验证配置文件语法
./dev config validate

# 检查配置文件内容
./dev config show

# 测试配置文件
./dev config test
```

### 环境变量问题

```mermaid
flowchart TD
    A[环境变量问题] --> B[变量未设置]
    A --> C[变量值错误]
    A --> D[变量冲突]
    
    B --> E[检查.env文件]
    B --> F[检查系统环境变量]
    
    C --> G[验证变量格式]
    C --> H[检查变量类型]
    
    D --> I[检查变量优先级]
    D --> J[解决变量冲突]
    
    E --> K[设置缺失变量]
    F --> K
    G --> L[修正变量值]
    H --> L
    I --> M[调整变量优先级]
    J --> M
    
    style A fill:#ffebee
    style K fill:#e8f5e8
    style L fill:#e8f5e8
    style M fill:#e8f5e8
```

## 🔒 权限问题

### 文件权限错误

```mermaid
graph TB
    A[权限问题] --> B[文件权限]
    A --> C[目录权限]
    A --> D[用户权限]
    A --> E[组权限]
    
    B --> F[检查文件权限]
    C --> G[检查目录权限]
    D --> H[检查用户权限]
    E --> I[检查组权限]
    
    F --> J[chmod修改文件权限]
    G --> K[chmod修改目录权限]
    H --> L[sudo提升权限]
    I --> M[chgrp修改组权限]
    
    style A fill:#ffebee
    style J fill:#e8f5e8
    style K fill:#e8f5e8
    style L fill:#e8f5e8
    style M fill:#e8f5e8
```

**权限诊断命令:**

```bash
# 检查文件权限
ls -la config/

# 检查目录权限
ls -ld logs/

# 修改文件权限
chmod 755 config/dev/cli.sh

# 修改目录权限
chmod 755 logs/

# 检查用户权限
id
groups

# 检查sudo权限
sudo -l
```

### SSH密钥权限

```mermaid
sequenceDiagram
    participant User as 用户
    participant SSH as SSH客户端
    participant Key as 密钥文件
    participant Server as 远程服务器
    
    User->>SSH: 尝试连接
    SSH->>Key: 读取私钥
    
    alt 权限正确
        Key->>SSH: 返回私钥
        SSH->>Server: 公钥认证
        Server->>SSH: 认证成功
    else 权限错误
        Key->>SSH: 权限拒绝
        SSH->>User: 认证失败
    end
```

**SSH密钥权限修复:**

```bash
# 设置正确的密钥权限
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
chmod 700 ~/.ssh/

# 检查密钥权限
ls -la ~/.ssh/

# 测试密钥连接
ssh -i ~/.ssh/id_ed25519 user@192.168.0.105
```

## 🚀 性能问题

### 系统资源监控

```mermaid
graph TB
    A[性能监控] --> B[CPU监控]
    A --> C[内存监控]
    A --> D[磁盘监控]
    A --> E[网络监控]
    
    B --> F[top命令]
    B --> G[htop命令]
    B --> H[CPU使用率]
    
    C --> I[free命令]
    C --> J[内存使用率]
    C --> K[交换空间]
    
    D --> L[df命令]
    D --> M[磁盘使用率]
    D --> N[I/O性能]
    
    E --> O[netstat命令]
    E --> P[网络连接]
    E --> Q[带宽使用]
    
    style A fill:#e8f5e8
    style H fill:#fff3e0
    style J fill:#fff3e0
    style M fill:#fff3e0
    style P fill:#fff3e0
```

**性能诊断命令:**

```bash
# CPU监控
top -p $(pgrep -d',' -f "python.*app.py")
htop

# 内存监控
free -h
ps aux --sort=-%mem | head -10

# 磁盘监控
df -h
du -sh logs/
iostat -x 1

# 网络监控
netstat -tuln
ss -tuln
iftop
```

### 性能优化建议

```mermaid
mindmap
  root((性能优化))
    系统层面
      增加内存
      升级CPU
      使用SSD
      优化网络
    应用层面
      代码优化
      数据库优化
      缓存策略
      连接池
    配置层面
      调整参数
      优化配置
      负载均衡
      资源限制
    监控层面
      实时监控
      性能分析
      瓶颈识别
      告警设置
```

## 🐳 Docker问题

### 容器启动失败

```mermaid
flowchart TD
    A[容器启动失败] --> B[检查镜像]
    A --> C[检查配置]
    A --> D[检查资源]
    A --> E[检查网络]
    
    B --> F[镜像是否存在]
    B --> G[镜像是否损坏]
    
    C --> H[docker-compose.yml]
    C --> I[环境变量]
    
    D --> J[内存限制]
    D --> K[磁盘空间]
    
    E --> L[端口冲突]
    E --> M[网络配置]
    
    F --> N[拉取镜像]
    G --> O[重新构建镜像]
    H --> P[修复配置]
    I --> Q[设置环境变量]
    J --> R[增加内存]
    K --> S[清理磁盘]
    L --> T[更改端口]
    M --> U[修复网络]
    
    style A fill:#ffebee
    style N fill:#e8f5e8
    style O fill:#e8f5e8
    style P fill:#e8f5e8
    style Q fill:#e8f5e8
    style R fill:#e8f5e8
    style S fill:#e8f5e8
    style T fill:#e8f5e8
    style U fill:#e8f5e8
```

**Docker诊断命令:**

```bash
# 检查容器状态
docker ps -a

# 查看容器日志
docker logs <container_id>

# 检查镜像
docker images

# 检查Docker守护进程
docker info

# 清理Docker资源
docker system prune -a

# 检查端口占用
docker port <container_id>
```

### 容器网络问题

```mermaid
graph TB
    A[容器网络问题] --> B[网络连接]
    A --> C[端口映射]
    A --> D[DNS解析]
    
    B --> E[容器间通信]
    B --> F[容器与宿主机通信]
    
    C --> G[端口冲突]
    C --> H[端口映射错误]
    
    D --> I[DNS配置]
    D --> J[域名解析]
    
    E --> K[检查网络配置]
    F --> L[检查桥接网络]
    G --> M[更改端口映射]
    H --> N[修复端口配置]
    I --> O[配置DNS]
    J --> P[检查hosts文件]
    
    style A fill:#ffebee
    style K fill:#e8f5e8
    style L fill:#e8f5e8
    style M fill:#e8f5e8
    style N fill:#e8f5e8
    style O fill:#e8f5e8
    style P fill:#e8f5e8
```

## 📝 日志分析

### 日志级别和类型

```mermaid
graph LR
    A[日志分析] --> B[系统日志]
    A --> C[应用日志]
    A --> D[错误日志]
    A --> E[访问日志]
    
    B --> F[/var/log/syslog]
    B --> G[systemd日志]
    
    C --> H[应用运行日志]
    C --> I[调试日志]
    
    D --> J[错误堆栈]
    D --> K[异常信息]
    
    E --> L[HTTP访问]
    E --> M[API调用]
    
    style A fill:#e8f5e8
    style B fill:#e3f2fd
    style C fill:#fff3e0
    style D fill:#ffebee
    style E fill:#f3e5f5
```

### 日志分析流程

```mermaid
sequenceDiagram
    participant User as 用户
    participant CLI as CLI工具
    participant Log as 日志系统
    participant Analysis as 分析工具
    
    User->>CLI: 查看日志
    CLI->>Log: 读取日志文件
    Log->>Analysis: 解析日志
    Analysis->>Analysis: 过滤和分析
    Analysis->>CLI: 返回分析结果
    CLI->>User: 显示结果
```

**日志分析命令:**

```bash
# 查看系统日志
sudo journalctl -u remote-dev-env

# 查看应用日志
./dev logs --tail=100

# 搜索错误日志
./dev logs --grep="ERROR"

# 实时查看日志
./dev logs --follow

# 按时间过滤日志
./dev logs --since="2024-07-14 06:00:00"

# 查看特定容器日志
./dev logs --container=web
```

## 🔧 自动化诊断工具

### 健康检查脚本

```mermaid
graph TB
    A[健康检查] --> B[系统检查]
    A --> C[服务检查]
    A --> D[网络检查]
    A --> E[性能检查]
    
    B --> F[磁盘空间]
    B --> G[内存使用]
    B --> H[CPU负载]
    
    C --> I[进程状态]
    C --> J[端口监听]
    C --> K[服务响应]
    
    D --> L[网络连通性]
    D --> M[DNS解析]
    D --> N[端口连接]
    
    E --> O[响应时间]
    E --> P[吞吐量]
    E --> Q[错误率]
    
    style A fill:#e8f5e8
    style F fill:#e8f5e8
    style G fill:#e8f5e8
    style H fill:#e8f5e8
    style I fill:#e8f5e8
    style J fill:#e8f5e8
    style K fill:#e8f5e8
    style L fill:#e8f5e8
    style M fill:#e8f5e8
    style N fill:#e8f5e8
    style O fill:#e8f5e8
    style P fill:#e8f5e8
    style Q fill:#e8f5e8
```

### 诊断脚本示例

```bash
#!/bin/bash
# 系统健康检查脚本

echo "🔍 开始系统健康检查..."

# 检查磁盘空间
echo "📁 检查磁盘空间..."
df -h | awk '$5 > 80 {print "⚠️  磁盘使用率过高: " $1 " " $5}'

# 检查内存使用
echo "🧠 检查内存使用..."
free -h | awk 'NR==2{printf "内存使用率: %.2f%%\n", $3/$2*100}'

# 检查服务状态
echo "🚀 检查服务状态..."
systemctl is-active --quiet docker && echo "✅ Docker服务正常" || echo "❌ Docker服务异常"

# 检查端口监听
echo "🔌 检查端口监听..."
netstat -tlnp | grep :8080 && echo "✅ 端口8080正常监听" || echo "❌ 端口8080未监听"

# 检查网络连接
echo "🌐 检查网络连接..."
ping -c 1 8.8.8.8 &>/dev/null && echo "✅ 网络连接正常" || echo "❌ 网络连接异常"

echo "✅ 健康检查完成！"
```

## 📞 技术支持

### 问题报告模板

```mermaid
graph TB
    A[问题报告] --> B[基本信息]
    A --> C[问题描述]
    A --> D[复现步骤]
    A --> E[环境信息]
    A --> F[日志信息]
    
    B --> G[报告人]
    B --> H[联系方式]
    B --> I[紧急程度]
    
    C --> J[问题现象]
    C --> K[影响范围]
    C --> L[发生时间]
    
    D --> M[操作步骤]
    D --> N[预期结果]
    D --> O[实际结果]
    
    E --> P[操作系统]
    E --> Q[软件版本]
    E --> R[硬件配置]
    
    F --> S[错误日志]
    F --> T[系统日志]
    F --> U[调试信息]
    
    style A fill:#e8f5e8
    style B fill:#e3f2fd
    style C fill:#fff3e0
    style D fill:#f3e5f5
    style E fill:#fce4ec
    style F fill:#ffebee
```

### 支持渠道

```mermaid
graph LR
    A[技术支持] --> B[在线文档]
    A --> C[社区论坛]
    A --> D[GitHub Issues]
    A --> E[邮件支持]
    
    B --> F[用户手册]
    B --> G[API文档]
    B --> H[常见问题]
    
    C --> I[用户讨论]
    C --> J[经验分享]
    C --> K[问题求助]
    
    D --> L[Bug报告]
    D --> M[功能请求]
    D --> N[代码贡献]
    
    E --> O[技术咨询]
    E --> P[紧急支持]
    E --> Q[定制服务]
    
    style A fill:#e8f5e8
    style B fill:#e3f2fd
    style C fill:#fff3e0
    style D fill:#f3e5f5
    style E fill:#fce4ec
```

## 🔗 相关资源

- [用户手册](../user/README.md) - 基础使用指南
- [开发指南](../development/README.md) - 开发者文档
- [API文档](../api/README.md) - 接口详细说明
- [部署指南](../deployment/README.md) - 部署操作手册

---

> 🔧 **故障排除**: 这份指南提供了全面的故障诊断和解决方案，帮助快速定位和修复问题！ 