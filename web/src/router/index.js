/**
 * Vue Router 配置
 * 作者: Zhang-Jingdian
 * 邮箱: 2157429750@qq.com
 * 创建时间: 2025年7月14日
 */

import { createRouter, createWebHistory } from 'vue-router'
import Layout from '@/layout/index.vue'

const routes = [
    {
        path: '/',
        component: Layout,
        children: [
            {
                path: '',
                name: 'Dashboard',
                component: () => import('@/views/Dashboard.vue'),
            },
            {
                path: 'config',
                name: 'Config',
                component: () => import('@/views/Config.vue'),
            },
            {
                path: 'logs',
                name: 'Logs',
                component: () => import('@/views/Logs.vue'),
            },
        ],
    },
]

const router = createRouter({
    history: createWebHistory(),
    routes,
})

export default router 