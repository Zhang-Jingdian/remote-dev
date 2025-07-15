/**
 * 系统状态管理 Store
 * 作者: Zhang-Jingdian
 * 邮箱: 2157429750@qq.com
 * 创建时间: 2025年7月14日
 */

import { defineStore } from 'pinia'
import { io } from 'socket.io-client'
import axios from 'axios'

export const useSystemStore = defineStore('system', {
    state: () => ({
        // WebSocket连接
        socket: null,
        connected: false,

        // 系统信息
        systemInfo: {
            author: 'Zhang-Jingdian',
            email: '2157429750@qq.com',
            version: '1.0.0',
            createDate: '2025-07-14'
        },

        // 系统指标
        metrics: {
            cpu_usage: 0,
            memory: { percent: 0, used: 0, total: 1 },
            disk: { percent: 0, used: 0, total: 1 },
        },
        cpuHistory: [],

        // 集群状态
        clusterStatus: {
            activeServers: [],
            failedServers: [],
            totalNodes: 0,
            onlineNodes: 0
        },

        // 插件状态
        plugins: {
            total: 0,
            enabled: 0,
            available: []
        },

        // 配置信息
        config: {},

        // 日志数据
        logs: [],

        // 加载状态
        loading: {
            metrics: false,
            cluster: false,
            plugins: false,
            config: false,
            logs: false
        }
    }),

    getters: {
        isConnected: (state) => state.connected,

        systemHealth: (state) => {
            const { cpuUsage, memoryUsage, diskUsage } = state.metrics
            if (cpuUsage > 80 || memoryUsage > 80 || diskUsage > 90) {
                return 'danger'
            } else if (cpuUsage > 60 || memoryUsage > 60 || diskUsage > 70) {
                return 'warning'
            }
            return 'success'
        },

        clusterHealth: (state) => {
            const { activeServers, failedServers } = state.clusterStatus
            if (failedServers.length > 0) {
                return 'warning'
            } else if (activeServers.length === 0) {
                return 'danger'
            }
            return 'success'
        },

        formatBytes: () => (bytes, decimals = 2) => {
            if (bytes === 0) return '0 Bytes';
            const k = 1024;
            const dm = decimals < 0 ? 0 : decimals;
            const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
        }
    },

    actions: {
        // 初始化WebSocket连接
        initWebSocket() {
            // 从 window.location 获取主机和端口，更具动态性
            const backendHost = window.location.hostname;
            const backendPort = import.meta.env.VITE_BACKEND_PORT || '9000'; // 使用新的默认端口
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const socketURL = `${protocol}//${backendHost}:${backendPort}`;

            console.log(`尝试连接 WebSocket: ${socketURL}`);

            this.socket = io(socketURL, {
                transports: ['websocket'],
                upgrade: false,
                forceNew: true
            })

            this.socket.on('connect', () => {
                console.log('WebSocket连接已建立')
                this.connected = true
            })

            this.socket.on('disconnect', () => {
                console.log('WebSocket连接已断开')
                this.connected = false
            })

            this.socket.on('error', (error) => {
                console.error('WebSocket连接错误:', error)
                this.connected = false
            })

            this.socket.on('metrics_updated', (data) => {
                this.updateMetrics(data)
            })

            this.socket.on('cluster_status_updated', (data) => {
                this.updateClusterStatus(data)
            })

            this.socket.on('config_updated', (data) => {
                this.updateConfig(data.key, data.value)
            })

            this.socket.on('plugin_toggled', (data) => {
                this.updatePluginStatus(data.plugin_name, data.enabled)
            })
        },

        // 获取系统信息
        async fetchSystemInfo() {
            try {
                const response = await axios.get('/api/system/info')
                this.systemInfo = { ...this.systemInfo, ...response.data }
            } catch (error) {
                console.error('获取系统信息失败:', error)
            }
        },

        // 获取系统指标
        async fetchMetrics() {
            this.loading.metrics = true
            try {
                const response = await axios.get('/api/metrics')
                this.metrics = response.data
            } catch (error) {
                console.error('获取系统指标失败:', error)
            } finally {
                this.loading.metrics = false
            }
        },

        // 获取集群状态
        async fetchClusterStatus() {
            this.loading.cluster = true
            try {
                const response = await axios.get('/api/cluster/status')
                this.clusterStatus = response.data
            } catch (error) {
                console.error('获取集群状态失败:', error)
            } finally {
                this.loading.cluster = false
            }
        },

        // 获取插件列表
        async fetchPlugins() {
            this.loading.plugins = true
            try {
                const response = await axios.get('/api/plugins')
                this.plugins.available = response.data.plugins || []
                this.plugins.total = Object.keys(this.plugins.available).length
                this.plugins.enabled = Object.values(this.plugins.available).filter(p => p.enabled).length
            } catch (error) {
                console.error('获取插件列表失败:', error)
            } finally {
                this.loading.plugins = false
            }
        },

        // 获取配置
        async fetchConfig() {
            this.loading.config = true
            try {
                const response = await axios.get('/api/config')
                this.config = response.data
            } catch (error) {
                console.error('获取配置失败:', error)
            } finally {
                this.loading.config = false
            }
        },

        // 获取日志
        async fetchLogs(params = {}) {
            this.loading.logs = true
            try {
                const response = await axios.get('/api/logs', { params })
                this.logs = response.data.logs || []
            } catch (error) {
                console.error('获取日志失败:', error)
            } finally {
                this.loading.logs = false
            }
        },

        // 更新指标
        updateMetrics(data) {
            this.metrics = { ...this.metrics, ...data }
        },

        // 更新集群状态
        updateClusterStatus(data) {
            this.clusterStatus = { ...this.clusterStatus, ...data }
        },

        // 更新配置
        updateConfig(key, value) {
            this.config[key] = value
        },

        // 更新插件状态
        updatePluginStatus(pluginName, enabled) {
            if (this.plugins.available[pluginName]) {
                this.plugins.available[pluginName].enabled = enabled
                this.plugins.enabled = Object.values(this.plugins.available).filter(p => p.enabled).length
            }
        },

        // 断开WebSocket连接
        disconnectWebSocket() {
            if (this.socket) {
                this.socket.disconnect()
                this.socket = null
                this.connected = false
            }
        },

        connectSocket() {
            if (this.socket && this.connected) return

            const backendHost = window.location.hostname;
            const backendPort = import.meta.env.VITE_BACKEND_PORT || '9000';
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            const socketURL = `${protocol}//${backendHost}:${backendPort}`;
            console.log(`正在重新连接 WebSocket: ${socketURL}`);

            this.socket = io(socketURL, {
                transports: ['websocket'],
                forceNew: true
            })

            this.socket.on('connect', () => {
                this.connected = true
                console.log('WebSocket重新连接成功')
            })

            this.socket.on('disconnect', () => {
                this.connected = false
            })
        },

        disconnectSocket() {
            if (this.socket) {
                this.socket.disconnect()
            }
        },
    }
}) 