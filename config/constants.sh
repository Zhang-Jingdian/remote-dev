#!/bin/bash

# =============================================================================
# 项目常量定义
# 作者: Zhang-Jingdian
# 邮箱: 2157429750@qq.com
# 创建时间: 2025年7月14日
# 描述: 远程开发环境项目的全局常量定义
# =============================================================================

# 防止重复加载
[ -n "${CONSTANTS_LOADED:-}" ] && return 0
CONSTANTS_LOADED=1

# 项目常量定义

# 项目基础信息
PROJECT_NAME="${PROJECT_NAME:-remote-dev-env}"
PROJECT_VERSION="${PROJECT_VERSION:-1.0.0}"
PROJECT_AUTHOR="${PROJECT_AUTHOR:-Zhang-Jingdian}"
PROJECT_EMAIL="${PROJECT_EMAIL:-2157429750@qq.com}"
PROJECT_GITHUB="${PROJECT_GITHUB:-https://github.com/Zhang-Jingdian/remote-dev.git}"
PROJECT_CREATE_DATE="${PROJECT_CREATE_DATE:-2025-07-14}"
PROJECT_ROOT="${PROJECT_ROOT:-$(dirname "$SCRIPT_DIR")}"

# 目录常量
CONFIG_DIR="${CONFIG_DIR:-$SCRIPT_DIR}"
LOG_DIR="${LOG_DIR:-$PROJECT_ROOT/logs}"
DATA_DIR="${DATA_DIR:-$PROJECT_ROOT/data}"
BACKUP_DIR="${BACKUP_DIR:-$PROJECT_ROOT/backups}"

# 默认配置常量
DEFAULT_SSH_ALIAS="remote-server"
DEFAULT_REMOTE_PROJECT_PATH="/home/user/workspace"
DEFAULT_COMPOSE_PROJECT_NAME="workspace"
DEFAULT_DOCKER_HOST_PORT="8000"
DEFAULT_DOCKER_CONTAINER_PORT="8000"
DEFAULT_DOCKER_SERVICE_NAME="web"

# 网络相关常量
DEFAULT_LOCAL_PROXY_HOST="127.0.0.1"
DEFAULT_LOCAL_PROXY_PORT="7897"
DEFAULT_REMOTE_DOCKER_PROXY_PORT="7897"
DEFAULT_SSH_TUNNEL_NAME="ssh-tunnel"

# 文件路径常量
CONFIG_DIR="config"
CORE_CONFIG_DIR="config/core"
DOCKER_CONFIG_DIR="config/docker"
DEV_CONFIG_DIR="config/dev"
NETWORK_CONFIG_DIR="config/network"

# 配置文件名常量
CONFIG_FILE="config.env"
DOCKER_COMPOSE_FILE="docker-compose.yml"
DOCKERFILE_NAME="Dockerfile"
LIB_FILE="lib.sh"

# Docker相关常量
DOCKER_COMPOSE_FILE_PATH="config/docker/docker-compose.yml"
DOCKERFILE_PATH="config/docker/Dockerfile"
DOCKER_BUILD_TARGET_DEV="development"
DOCKER_BUILD_TARGET_PROD="production"

# 同步相关常量
AUTO_SYNC_INTERVAL=5
RSYNC_EXCLUDE_PATTERNS=(
    ".git"
    ".gitignore"
    "node_modules"
    ".DS_Store"
    "*.log"
    "*.tmp"
    ".env"
    ".env.local"
)

# 日志相关常量
LOG_LEVEL_DEBUG="debug"
LOG_LEVEL_INFO="info"
LOG_LEVEL_WARN="warn"
LOG_LEVEL_ERROR="error"

# 状态码常量
EXIT_SUCCESS=0
EXIT_FAILURE=1
EXIT_CONFIG_ERROR=2
EXIT_NETWORK_ERROR=3
EXIT_DOCKER_ERROR=4

# 超时设置常量 - 默认值
DEFAULT_SSH_TIMEOUT=10
DEFAULT_DOCKER_TIMEOUT=30
DEFAULT_TUNNEL_TIMEOUT=15
DEFAULT_SYNC_TIMEOUT=60

# PID文件路径常量
PID_DIR="/tmp"
SSH_TUNNEL_PID_FILE="${PID_DIR}/ssh-tunnel.pid"

# 命令相关常量
REQUIRED_COMMANDS=("docker" "rsync" "ssh")
OPTIONAL_COMMANDS=("curl" "wget" "git")

# 环境变量名常量
ENV_SSH_ALIAS="SSH_ALIAS"
ENV_REMOTE_HOST="REMOTE_HOST"
ENV_REMOTE_PROJECT_PATH="REMOTE_PROJECT_PATH"
ENV_COMPOSE_PROJECT_NAME="COMPOSE_PROJECT_NAME"
ENV_DOCKER_HOST_PORT="DOCKER_HOST_PORT"
ENV_DOCKER_CONTAINER_PORT="DOCKER_CONTAINER_PORT"
ENV_PROXY_URL="PROXY_URL"
ENV_NODE_ENV="NODE_ENV"
ENV_DEBUG_MODE="DEBUG_MODE" 