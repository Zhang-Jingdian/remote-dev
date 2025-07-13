# 🔌 API文档

> 远程开发环境的完整API参考文档，包含Web API和CLI API

## 🌐 Web API

### API架构

```mermaid
graph TB
    A[Web API] --> B[认证层]
    A --> C[路由层]
    A --> D[业务逻辑层]
    A --> E[数据访问层]
    
    B --> F[Token验证]
    B --> G[权限检查]
    B --> H[会话管理]
    
    C --> I[RESTful路由]
    C --> J[WebSocket路由]
    C --> K[静态资源]
    
    D --> L[配置管理]
    D --> M[集群管理]
    D --> N[插件管理]
    D --> O[日志管理]
    
    E --> P[文件系统]
    E --> Q[配置文件]
    E --> R[日志文件]
    
    style A fill:#e8f5e8
    style B fill:#ffebee
    style C fill:#e3f2fd
    style D fill:#fff3e0
    style E fill:#f3e5f5
```

### API端点总览

```mermaid
mindmap
  root((API端点))
    认证相关
      POST /api/auth/login
      POST /api/auth/logout
      GET /api/auth/status
    配置管理
      GET /api/config
      POST /api/config
      PUT /api/config/{key}
      DELETE /api/config/{key}
    集群管理
      GET /api/cluster/status
      POST /api/cluster/health-check
      PUT /api/cluster/server/{id}
    插件管理
      GET /api/plugins
      POST /api/plugins/{name}/toggle
      GET /api/plugins/{name}/config
    监控相关
      GET /api/metrics
      GET /api/logs
      WebSocket /ws/realtime
```

### 认证API

#### 登录认证

```mermaid
sequenceDiagram
    participant Client as 客户端
    participant Auth as 认证服务
    participant Session as 会话管理
    participant Response as 响应
    
    Client->>Auth: POST /api/auth/login
    Auth->>Auth: 验证凭据
    
    alt 认证成功
        Auth->>Session: 创建会话
        Session->>Response: 返回Token
        Response->>Client: 200 OK + Token
    else 认证失败
        Auth->>Response: 认证错误
        Response->>Client: 401 Unauthorized
    end
```

**接口详情:**
- **URL**: `POST /api/auth/login`
- **请求体**:
```json
{
  "username": "admin",
  "password": "password123"
}
```
- **响应**:
```json
{
  "status": "success",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600
}
```

### 配置管理API

#### 获取配置

```mermaid
graph LR
    A[GET /api/config] --> B[配置管理器]
    B --> C[读取配置文件]
    C --> D[配置验证]
    D --> E[返回配置]
    
    style A fill:#e8f5e8
    style E fill:#e8f5e8
```

**接口详情:**
- **URL**: `GET /api/config`
- **响应**:
```json
{
  "ssh_alias": "remote-server",
  "remote_host": "192.168.0.105",
  "remote_project_path": "/home/user/workspace",
  "docker_service_name": "web",
  "debug_mode": false
}
```

#### 更新配置

```mermaid
flowchart TD
    A[POST /api/config] --> B[参数验证]
    B --> C{验证通过?}
    C -->|否| D[返回错误]
    C -->|是| E[更新配置文件]
    E --> F[重新加载配置]
    F --> G[返回成功]
    
    style A fill:#e8f5e8
    style G fill:#e8f5e8
    style D fill:#ffebee
```

### 集群管理API

#### 集群状态

```mermaid
graph TB
    A[GET /api/cluster/status] --> B[集群管理器]
    B --> C[检查各服务器]
    C --> D[收集状态信息]
    D --> E[汇总结果]
    
    C --> F[服务器1]
    C --> G[服务器2]
    C --> H[服务器3]
    
    F --> I[CPU: 45%]
    F --> J[内存: 60%]
    F --> K[状态: 正常]
    
    style A fill:#e8f5e8
    style E fill:#e8f5e8
    style I fill:#e8f5e8
    style J fill:#fff3e0
    style K fill:#e8f5e8
```

**响应格式:**
```json
{
  "cluster_status": "healthy",
  "servers": [
    {
      "id": "primary",
      "host": "192.168.0.105",
      "status": "online",
      "cpu_usage": 45.2,
      "memory_usage": 60.1,
      "disk_usage": 35.8,
      "last_check": "2024-07-14T06:30:00Z"
    }
  ]
}
```

### 插件管理API

#### 插件列表

```mermaid
graph LR
    A[GET /api/plugins] --> B[插件管理器]
    B --> C[扫描插件目录]
    C --> D[读取插件信息]
    D --> E[返回插件列表]
    
    C --> F[已安装插件]
    C --> G[可用插件]
    
    style A fill:#e8f5e8
    style E fill:#e8f5e8
    style F fill:#e8f5e8
    style G fill:#fff3e0
```

#### 插件切换

```mermaid
sequenceDiagram
    participant Client as 客户端
    participant API as API服务
    participant Plugin as 插件管理器
    participant System as 系统
    
    Client->>API: POST /api/plugins/{name}/toggle
    API->>Plugin: 切换插件状态
    
    alt 启用插件
        Plugin->>System: 加载插件
        System->>Plugin: 注册钩子
        Plugin->>API: 启用成功
    else 禁用插件
        Plugin->>System: 卸载插件
        System->>Plugin: 清理钩子
        Plugin->>API: 禁用成功
    end
    
    API->>Client: 返回结果
```

### 监控API

#### 系统指标

```mermaid
graph TB
    A[GET /api/metrics] --> B[指标收集器]
    B --> C[系统指标]
    B --> D[应用指标]
    B --> E[业务指标]
    
    C --> F[CPU使用率]
    C --> G[内存使用率]
    C --> H[磁盘I/O]
    
    D --> I[响应时间]
    D --> J[错误率]
    D --> K[吞吐量]
    
    E --> L[同步成功率]
    E --> M[用户活跃度]
    
    style A fill:#e8f5e8
    style F fill:#e8f5e8
    style G fill:#fff3e0
    style H fill:#f3e5f5
    style I fill:#e3f2fd
    style J fill:#ffebee
    style K fill:#e8f5e8
    style L fill:#e8f5e8
    style M fill:#fff3e0
```

### WebSocket API

#### 实时通信

```mermaid
sequenceDiagram
    participant Client as 客户端
    participant WS as WebSocket服务
    participant Monitor as 监控系统
    participant System as 系统
    
    Client->>WS: 建立WebSocket连接
    WS->>Client: 连接确认
    
    Client->>WS: 订阅实时数据
    WS->>Monitor: 注册监听器
    
    loop 实时数据推送
        System->>Monitor: 系统事件
        Monitor->>WS: 推送数据
        WS->>Client: 实时更新
    end
    
    Client->>WS: 断开连接
    WS->>Monitor: 清理监听器
```

**WebSocket消息格式:**
```json
{
  "type": "metrics_update",
  "timestamp": "2024-07-14T06:30:00Z",
  "data": {
    "cpu_usage": 45.2,
    "memory_usage": 60.1,
    "active_connections": 12
  }
}
```

## 🖥️ CLI API

### CLI架构

```mermaid
graph TB
    A[CLI工具] --> B[命令解析器]
    A --> C[参数验证器]
    A --> D[功能调度器]
    
    B --> E[命令识别]
    B --> F[子命令处理]
    B --> G[帮助系统]
    
    C --> H[参数类型检查]
    C --> I[必选参数验证]
    C --> J[默认值设置]
    
    D --> K[环境管理]
    D --> L[同步管理]
    D --> M[网络管理]
    D --> N[监控管理]
    
    style A fill:#e8f5e8
    style B fill:#e3f2fd
    style C fill:#fff3e0
    style D fill:#f3e5f5
```

### 命令分类

```mermaid
mindmap
  root((CLI命令))
    环境管理
      setup
        --force
        --config=path
      up
        --env=prod
        --detach
      down
        --remove-volumes
      status
        --detailed
        --json
      health
        --verbose
    同步管理
      sync
        --direction=to-remote
        --exclude=pattern
      watch
        start
          --interval=3
        stop
        status
          --stats
    网络管理
      tunnel
        start
          --port=8080
        stop
        status
      pool
        init
          --size=10
        status
        cleanup
    监控管理
      logs
        --tail=100
        --grep=pattern
        --container=name
      metrics
        --format=json
        --interval=5
```

### 命令执行流程

```mermaid
flowchart TD
    A[用户输入命令] --> B[解析命令行]
    B --> C[加载配置]
    C --> D[验证参数]
    D --> E{参数有效?}
    E -->|否| F[显示错误]
    E -->|是| G[执行命令]
    G --> H[调用相应模块]
    H --> I[执行业务逻辑]
    I --> J[返回结果]
    J --> K[格式化输出]
    K --> L[显示结果]
    
    style A fill:#e8f5e8
    style L fill:#e8f5e8
    style F fill:#ffebee
```

### 环境管理命令

#### setup命令

```mermaid
graph TD
    A[./dev setup] --> B[检查系统依赖]
    B --> C[创建必要目录]
    C --> D[初始化配置文件]
    D --> E[设置SSH密钥]
    E --> F[测试远程连接]
    F --> G[启动基础服务]
    G --> H[验证安装]
    
    style A fill:#e8f5e8
    style H fill:#e8f5e8
```

**命令格式:**
```bash
./dev setup [OPTIONS]

OPTIONS:
  --force              强制重新初始化
  --config=PATH        指定配置文件路径
  --ssh-key=PATH       指定SSH密钥路径
  --remote-host=HOST   指定远程主机
  --help               显示帮助信息
```

#### status命令

```mermaid
graph LR
    A[./dev status] --> B[检查本地服务]
    A --> C[检查远程连接]
    A --> D[检查容器状态]
    A --> E[检查同步状态]
    
    B --> F[CLI服务: 运行中]
    C --> G[SSH连接: 正常]
    D --> H[Docker容器: 3个运行中]
    E --> I[文件监控: 活跃]
    
    style A fill:#e8f5e8
    style F fill:#e8f5e8
    style G fill:#e8f5e8
    style H fill:#e8f5e8
    style I fill:#e8f5e8
```

### 同步管理命令

#### sync命令

```mermaid
sequenceDiagram
    participant User as 用户
    participant CLI as CLI工具
    participant Sync as 同步引擎
    participant Remote as 远程服务器
    
    User->>CLI: ./dev sync
    CLI->>Sync: 启动同步
    Sync->>Sync: 扫描文件变化
    Sync->>Remote: 传输文件
    Remote->>Sync: 确认接收
    Sync->>CLI: 同步完成
    CLI->>User: 显示结果
```

**命令格式:**
```bash
./dev sync [OPTIONS]

OPTIONS:
  --direction=DIRECTION    同步方向 (to-remote|from-remote|bidirectional)
  --exclude=PATTERN        排除文件模式
  --dry-run               预览模式，不实际同步
  --verbose               详细输出
  --force                 强制同步
```

### 网络管理命令

#### tunnel命令

```mermaid
graph TB
    A[./dev tunnel start] --> B[建立SSH连接]
    B --> C[创建隧道]
    C --> D[配置端口转发]
    D --> E[测试连接]
    E --> F[启动监控]
    
    style A fill:#e8f5e8
    style F fill:#e8f5e8
```

### 错误处理

#### 错误分类

```mermaid
graph TB
    A[错误类型] --> B[系统错误]
    A --> C[网络错误]
    A --> D[配置错误]
    A --> E[权限错误]
    
    B --> F[1xx: 系统相关]
    C --> G[2xx: 网络相关]
    D --> H[3xx: 配置相关]
    E --> I[4xx: 权限相关]
    
    F --> J[101: 命令不存在]
    F --> K[102: 依赖缺失]
    
    G --> L[201: 连接超时]
    G --> M[202: 连接被拒绝]
    
    H --> N[301: 配置文件不存在]
    H --> O[302: 配置格式错误]
    
    I --> P[401: 权限不足]
    I --> Q[402: 认证失败]
    
    style B fill:#ffebee
    style C fill:#ffebee
    style D fill:#ffebee
    style E fill:#ffebee
    style J fill:#ffebee
    style K fill:#ffebee
    style L fill:#ffebee
    style M fill:#ffebee
    style N fill:#ffebee
    style O fill:#ffebee
    style P fill:#ffebee
    style Q fill:#ffebee
```

#### 错误处理流程

```mermaid
flowchart TD
    A[命令执行] --> B[捕获异常]
    B --> C[错误分类]
    C --> D{错误类型}
    
    D -->|系统错误| E[检查系统状态]
    D -->|网络错误| F[检查网络连接]
    D -->|配置错误| G[验证配置文件]
    D -->|权限错误| H[检查权限设置]
    
    E --> I[提供解决建议]
    F --> I
    G --> I
    H --> I
    
    I --> J[记录错误日志]
    J --> K[显示错误信息]
    K --> L[退出程序]
    
    style A fill:#e8f5e8
    style L fill:#ffebee
```

## 📊 API监控

### 性能指标

```mermaid
graph TB
    A[API性能监控] --> B[响应时间]
    A --> C[吞吐量]
    A --> D[错误率]
    A --> E[可用性]
    
    B --> F[平均响应时间: 150ms]
    B --> G[95%响应时间: 300ms]
    B --> H[99%响应时间: 500ms]
    
    C --> I[QPS: 1000]
    C --> J[并发数: 100]
    
    D --> K[4xx错误率: 2%]
    D --> L[5xx错误率: 0.1%]
    
    E --> M[可用性: 99.9%]
    E --> N[故障时间: 8.76小时/年]
    
    style F fill:#e8f5e8
    style G fill:#e8f5e8
    style H fill:#fff3e0
    style I fill:#e8f5e8
    style J fill:#e8f5e8
    style K fill:#fff3e0
    style L fill:#e8f5e8
    style M fill:#e8f5e8
    style N fill:#e8f5e8
```

### 监控告警

```mermaid
sequenceDiagram
    participant API as API服务
    participant Monitor as 监控系统
    participant Alert as 告警系统
    participant Admin as 管理员
    
    API->>Monitor: 上报指标
    Monitor->>Monitor: 检查阈值
    
    alt 超过阈值
        Monitor->>Alert: 触发告警
        Alert->>Admin: 发送通知
        Admin->>API: 处理问题
    else 正常范围
        Monitor->>Monitor: 继续监控
    end
```

## 🔗 SDK和客户端

### Python SDK

```python
from remote_dev_env import RemoteDevEnvClient

# 创建客户端
client = RemoteDevEnvClient(
    base_url="http://localhost:8080",
    api_key="your-api-key"
)

# 获取集群状态
cluster_status = client.cluster.get_status()

# 同步文件
sync_result = client.sync.sync_files(
    direction="to-remote",
    exclude=["*.log", "*.tmp"]
)

# 获取实时指标
def on_metrics(data):
    print(f"CPU: {data['cpu_usage']}%")

client.realtime.subscribe("metrics", on_metrics)
```

### JavaScript SDK

```javascript
import { RemoteDevEnvClient } from '@remote-dev-env/client';

const client = new RemoteDevEnvClient({
  baseUrl: 'http://localhost:8080',
  apiKey: 'your-api-key'
});

// 获取配置
const config = await client.config.get();

// 更新配置
await client.config.update({
  debug_mode: true
});

// WebSocket连接
const ws = client.realtime.connect();
ws.on('metrics', (data) => {
  console.log('Metrics:', data);
});
```

## 🔗 相关资源

- [用户手册](../user/README.md) - 基础使用指南
- [开发指南](../development/README.md) - 开发者文档
- [部署指南](../deployment/README.md) - 部署操作手册
- [故障排除](../troubleshooting/README.md) - 问题解决方案

---

> 🔌 **API文档**: 本文档提供了完整的API参考，包含所有接口的详细说明和示例代码！ 