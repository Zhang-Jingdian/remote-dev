# 远程开发环境管理 - Vue3前端

> 基于Vue3 + Element Plus + Vite构建的现代化管理界面

**作者**: Zhang-Jingdian  
**邮箱**: 2157429750@qq.com  
**创建时间**: 2025年7月14日  
**版本**: v1.0.0  

## 🚀 快速开始

### 环境要求
- Node.js 16.0+ 
- npm 8.0+ 或 yarn 1.22+

### 安装依赖
```bash
npm install
# 或
yarn install
```

### 开发模式
```bash
npm run dev
# 或
yarn dev
```

访问: http://localhost:3000

### 构建生产版本
```bash
npm run build
# 或
yarn build
```

构建产物将输出到 `../dist/` 目录

### 代码检查
```bash
npm run lint
# 或
yarn lint
```

## 🛠️ 技术栈

- **Vue 3.4+**: 使用Composition API
- **Element Plus 2.4+**: UI组件库
- **Vite 5.0+**: 构建工具
- **Vue Router 4.2+**: 路由管理
- **Pinia 2.1+**: 状态管理
- **Axios 1.6+**: HTTP客户端
- **ECharts 5.4+**: 图表库
- **Socket.IO Client 4.7+**: 实时通信

## 📁 项目结构

```
src/
├── main.js              # 应用入口
├── App.vue              # 根组件
├── style.css            # 全局样式
├── router/              # 路由配置
│   └── index.js
├── stores/              # Pinia状态管理
│   └── system.js        # 系统状态
├── layout/              # 布局组件
│   └── index.vue        # 主布局
├── views/               # 页面组件
│   ├── Dashboard.vue    # 仪表板
│   ├── Config.vue       # 配置管理
│   ├── Cluster.vue      # 集群管理
│   ├── Plugins.vue      # 插件管理
│   ├── Monitoring.vue   # 系统监控
│   └── Logs.vue         # 日志查看
└── components/          # 通用组件
```

## 🔧 开发指南

### 组件开发
- 使用Vue 3 Composition API
- 遵循Element Plus设计规范
- 组件文件使用PascalCase命名

### 状态管理
- 使用Pinia进行状态管理
- Store按功能模块划分
- 支持TypeScript类型推导

### 路由配置
- 使用Vue Router 4
- 支持路由懒加载
- 自动生成面包屑导航

### API调用
- 使用Axios进行HTTP请求
- 统一的错误处理
- 支持请求拦截和响应拦截

## 🎨 UI/UX设计

### 设计原则
- 现代化的扁平设计
- 响应式布局
- 暗色主题支持
- 无障碍访问支持

### 颜色主题
- 主色调: #409EFF (Element Plus Blue)
- 成功色: #67C23A
- 警告色: #E6A23C
- 危险色: #F56C6C

### 布局特性
- 侧边栏导航
- 顶部工具栏
- 面包屑导航
- 响应式卡片布局

## 🔌 API集成

### WebSocket连接
```javascript
// 在Pinia Store中初始化
initWebSocket() {
  this.socket = io('ws://localhost:8080')
  
  this.socket.on('connect', () => {
    this.connected = true
  })
  
  this.socket.on('metrics_updated', (data) => {
    this.updateMetrics(data)
  })
}
```

### HTTP API调用
```javascript
// 获取系统指标
async fetchMetrics() {
  try {
    const response = await axios.get('/api/metrics')
    this.metrics = response.data
  } catch (error) {
    ElMessage.error('获取数据失败')
  }
}
```

## 📦 构建配置

### Vite配置
- 自动导入Vue和Element Plus组件
- 代理API请求到后端服务
- 支持热模块替换(HMR)
- 优化的生产构建

### 环境变量
```bash
# 开发环境
VITE_API_BASE_URL=http://localhost:8080
VITE_WS_URL=ws://localhost:8080

# 生产环境
VITE_API_BASE_URL=https://your-domain.com
VITE_WS_URL=wss://your-domain.com
```

## 🚀 部署指南

### 开发环境
```bash
npm run dev
```

### 生产环境
```bash
# 构建
npm run build

# 预览构建结果
npm run preview
```

### Docker部署
```dockerfile
FROM node:18-alpine as builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
```

## 🔗 相关链接

- [Vue 3 文档](https://vuejs.org/)
- [Element Plus 文档](https://element-plus.org/)
- [Vite 文档](https://vitejs.dev/)
- [Pinia 文档](https://pinia.vuejs.org/)

---

> 🎨 **现代化界面**: 基于Vue3构建的响应式管理界面，提供优秀的用户体验！ 