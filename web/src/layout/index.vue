<template>
  <div class="common-layout">
    <el-container>
      <el-aside width="200px">
        <el-menu
          default-active="/"
          class="el-menu-vertical-demo"
          router
        >
          <el-menu-item index="/">
            <el-icon><DataLine /></el-icon>
            <span>仪表盘</span>
          </el-menu-item>
          <el-menu-item index="/config">
            <el-icon><Setting /></el-icon>
            <span>配置管理</span>
          </el-menu-item>
           <el-menu-item index="/logs">
            <el-icon><Document /></el-icon>
            <span>日志查看</span>
          </el-menu-item>
        </el-menu>
      </el-aside>
      <el-main>
        <router-view></router-view>
      </el-main>
    </el-container>
  </div>
</template>

<script setup>
import { DataLine, Setting, Document } from '@element-plus/icons-vue'
</script>

<style>
.common-layout, .el-container, .el-menu {
  height: 100vh;
}
.el-aside {
  border-right: 1px solid var(--el-border-color);
}
</style> 