<template>
  <el-card class="box-card">
    <template #header>
      <div class="card-header">
        <span><el-icon><Document /></el-icon> 远程日志</span>
        <el-button @click="fetchLogs" :loading="loading">刷新</el-button>
      </div>
    </template>
    <div v-if="loading && logs.length === 0" class="loading-text">正在加载日志...</div>
    <div v-else-if="error" class="error-text">加载日志失败: {{ error }}</div>
    <pre v-else class="logs-container">{{ logs.join('\n') }}</pre>
  </el-card>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';
import axios from 'axios';
import { Document } from '@element-plus/icons-vue';

const logs = ref([]);
const loading = ref(true);
const error = ref(null);
let intervalId = null;

const fetchLogs = async () => {
  loading.value = true;
  try {
    const response = await axios.get('/api/logs');
    logs.value = response.data.logs || [];
  } catch (err) {
    error.value = err.message;
  } finally {
    loading.value = false;
  }
};

onMounted(() => {
  fetchLogs();
  intervalId = setInterval(fetchLogs, 5000); // 每5秒刷新一次
});

onUnmounted(() => {
  clearInterval(intervalId);
});
</script>

<style scoped>
.box-card {
  min-height: 400px;
}
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 1.2rem;
  font-weight: bold;
}
.loading-text, .error-text {
  text-align: center;
  padding: 2rem;
  color: #909399;
}
.error-text {
  color: #f56c6c;
}
.logs-container {
  background-color: #f4f4f5;
  color: #606266;
  padding: 1rem;
  border-radius: 0.25rem;
  white-space: pre-wrap;
  word-wrap: break-word;
  height: 60vh;
  overflow-y: auto;
  font-family: 'Courier New', Courier, monospace;
}
</style> 