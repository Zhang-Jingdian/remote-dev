<template>
  <div>
    <el-row :gutter="20">
      <el-col :span="24">
        <el-card shadow="never" class="mb-5">
          <div class="flex items-center">
            <div class="flex-1">
              <h1 class="text-2xl font-bold">仪表盘</h1>
              <p class="text-gray-500">实时系统状态概览</p>
            </div>
            <div>
              <el-tag :type="systemStore.isConnected ? 'success' : 'danger'">
                {{ systemStore.isConnected ? '● 已连接' : '○ 已断开' }}
              </el-tag>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
    <el-row :gutter="20">
      <!-- CPU -->
      <el-col :xs="24" :sm="8" :lg="8">
        <el-card shadow="hover">
          <template #header>
            <div class="flex justify-between items-center">
              <span>CPU</span>
              <el-tag type="info">{{ systemStore.metrics.cpu_usage.toFixed(1) }}%</el-tag>
            </div>
          </template>
          <v-chart class="h-48" :option="cpuChartOption" autoresize />
        </el-card>
      </el-col>
      <!-- Memory -->
      <el-col :xs="24" :sm="8" :lg="8">
        <el-card shadow="hover">
          <template #header>
            <span>内存</span>
          </template>
          <div class="h-48 flex flex-col justify-center items-center">
            <el-progress type="dashboard" :percentage="systemStore.metrics.memory.percent" :width="130">
              <template #default="{ percentage }">
                <span class="font-bold text-xl">{{ percentage }}%</span>
              </template>
            </el-progress>
            <div class="mt-3 text-sm text-gray-500">
              {{ systemStore.formatBytes(systemStore.metrics.memory.used) }} / {{ systemStore.formatBytes(systemStore.metrics.memory.total) }}
            </div>
          </div>
        </el-card>
      </el-col>
      <!-- Disk -->
      <el-col :xs="24" :sm="8" :lg="8">
        <el-card shadow="hover">
          <template #header>
            <span>磁盘</span>
          </template>
          <div class="h-48 flex flex-col justify-center items-center">
            <el-progress type="dashboard" :percentage="systemStore.metrics.disk.percent" :width="130">
               <template #default="{ percentage }">
                <span class="font-bold text-xl">{{ percentage }}%</span>
              </template>
            </el-progress>
             <div class="mt-3 text-sm text-gray-500">
              {{ systemStore.formatBytes(systemStore.metrics.disk.used) }} / {{ systemStore.formatBytes(systemStore.metrics.disk.total) }}
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { onMounted, onUnmounted, computed } from 'vue';
import { useSystemStore } from '@/stores/system';
import { use } from 'echarts/core';
import { CanvasRenderer } from 'echarts/renderers';
import { LineChart } from 'echarts/charts';
import { GridComponent, TooltipComponent, TitleComponent } from 'echarts/components';
import VChart from 'vue-echarts';

use([
  CanvasRenderer,
  LineChart,
  GridComponent,
  TooltipComponent,
  TitleComponent,
]);

const systemStore = useSystemStore();

onMounted(() => {
  systemStore.connectSocket();
});

onUnmounted(() => {
  systemStore.disconnectSocket();
});

const cpuChartOption = computed(() => ({
  grid: {
    left: '3%',
    right: '4%',
    bottom: '3%',
    top: '10%',
    containLabel: true,
  },
  tooltip: {
    trigger: 'axis',
    formatter: '{c0}%'
  },
  xAxis: {
    type: 'category',
    boundaryGap: false,
    data: Array.from({ length: systemStore.cpuHistory.length }, (_, i) => i + 1),
    axisLabel: { show: false },
    axisTick: { show: false },
  },
  yAxis: {
    type: 'value',
    min: 0,
    max: 100,
    axisLabel: {
      formatter: '{value}%'
    }
  },
  series: [
    {
      name: 'CPU Usage',
      type: 'line',
      smooth: true,
      showSymbol: false,
      data: systemStore.cpuHistory,
      areaStyle: {},
      lineStyle: {
        width: 0,
      },
    },
  ],
}));
</script>

<style scoped>
.mb-5 {
  margin-bottom: 1.25rem;
}
.h-48 {
  height: 12rem;
}
.flex { display: flex; }
.flex-1 { flex: 1; }
.items-center { align-items: center; }
.justify-between { justify-content: space-between; }
.justify-center { justify-content: center; }
.flex-col { flex-direction: column; }
.font-bold { font-weight: 700; }
.text-2xl { font-size: 1.5rem; }
.text-xl { font-size: 1.25rem; }
.text-sm { font-size: 0.875rem; }
.text-gray-500 { color: #6b7280; }
.mt-3 { margin-top: 0.75rem; }
</style> 