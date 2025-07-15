<template>
  <el-card class="box-card">
    <template #header>
      <div class="card-header">
        <span><el-icon><Setting /></el-icon> 配置管理</span>
      </div>
    </template>
    <div v-if="loading" class="loading-text">正在加载配置...</div>
    <div v-else-if="error" class="error-text">加载配置失败: {{ error }}</div>
    <div v-else class="config-grid">
      <div v-for="(value, key) in config" :key="key" class="config-item">
        <span class="config-key">{{ key }}</span>
        <span class="config-value">{{ value }}</span>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import axios from 'axios';
import { Setting } from '@element-plus/icons-vue';

const config = ref({});
const loading = ref(true);
const error = ref(null);

const fetchConfig = async () => {
  try {
    const response = await axios.get('/api/config');
    config.value = response.data;
  } catch (err) {
    error.value = err.message;
  } finally {
    loading.value = false;
  }
};

onMounted(fetchConfig);
</script>

<style scoped>
.box-card {
  min-height: 400px;
}
.card-header {
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
.config-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 1rem;
}
.config-item {
  display: flex;
  justify-content: space-between;
  padding: 0.75rem;
  border: 1px solid #e2e8f0;
  border-radius: 0.375rem;
  background-color: #f8f9fa;
  font-family: 'Courier New', Courier, monospace;
}
.config-key {
  font-weight: bold;
  color: #4a5568;
}
.config-value {
  color: #2d3748;
}
</style> 