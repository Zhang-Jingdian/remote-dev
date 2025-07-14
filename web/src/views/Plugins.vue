<template>
  <div class="plugins-page">
    <el-card>
      <template #header>
        <span><el-icon><Grid /></el-icon> 插件管理</span>
      </template>
      <el-alert title="Vue3插件管理页面" type="info" description="插件管理功能开发中..." show-icon :closable="false" />
    </el-card>
  </div>
</template>

<script setup>
// 插件管理逻辑
</script>

<style scoped>
.plugins-page { padding: 0; }
</style> 