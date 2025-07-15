import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import { ElementPlusResolver } from 'unplugin-vue-components/resolvers'
import { resolve } from 'path'
import fs from 'fs'

// 从 ../config.env 文件中解析 API_PORT
function getBackendPort() {
    try {
        const configFile = fs.readFileSync(resolve(__dirname, '../config.env'), 'utf-8');
        const match = configFile.match(/^API_PORT\s*=\s*(\d+)/m);
        if (match && match[1]) {
            console.log(`✅成功读取后端端口: ${match[1]}`);
            return parseInt(match[1], 10);
        }
    } catch (error) {
        console.warn('⚠️  无法读取 config.env 文件, 使用默认端口 9000');
    }
    return 9000; // 默认端口，避免与系统服务冲突
}

const backendPort = getBackendPort();

// https://vitejs.dev/config/
export default defineConfig({
    plugins: [
        vue(),
        AutoImport({
            resolvers: [ElementPlusResolver()],
            imports: ['vue', 'vue-router', 'pinia'],
            dts: true
        }),
        Components({
            resolvers: [ElementPlusResolver()],
            dts: true
        })
    ],
    resolve: {
        alias: {
            '@': resolve(__dirname, 'src')
        }
    },
    server: {
        host: '0.0.0.0',
        port: 3000,
        proxy: {
            '/api': {
                target: `http://localhost:${backendPort}`,
                changeOrigin: true
            },
            '/socket.io': {
                target: `ws://localhost:${backendPort}`,
                ws: true
            }
        }
    },
    build: {
        outDir: '../dist',
        emptyOutDir: true,
        sourcemap: true
    }
}) 