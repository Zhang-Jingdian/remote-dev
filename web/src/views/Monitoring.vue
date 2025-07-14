<template>
  <div class="monitoring-page">
    <el-card>
      <template #header>
        <span><el-icon><TrendCharts /></el-icon> 系统监控</span>
      </template>
      <el-alert title="Vue3系统监控页面" type="info" description="系统监控功能开发中..." show-icon :closable="false" />
    </el-card>
  </div>
</template>

<script setup>
// 监控逻辑
</script>

<style scoped>
.monitoring-page { padding: 0; }
</style> 