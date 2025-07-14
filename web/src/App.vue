<template>
  <div id="app">
    <router-view />
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useSystemStore } from '@/stores/system'

const systemStore = useSystemStore()

onMounted(() => {
  // 初始化WebSocket连接
  systemStore.initWebSocket()
  
  // 获取初始数据
  systemStore.fetchSystemInfo()
})
</script>

<style>
#app {
  font-family: 'Helvetica Neue', Helvetica, 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei', '微软雅黑', Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: var(--el-text-color-primary);
  min-height: 100vh;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  margin: 0;
  background-color: var(--el-bg-color-page);
}

.page-container {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.status-indicator {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  margin-right: 8px;
}

.status-success {
  background-color: var(--el-color-success);
}

.status-warning {
  background-color: var(--el-color-warning);
}

.status-danger {
  background-color: var(--el-color-danger);
}

.status-info {
  background-color: var(--el-color-info);
}
</style> 