#!/bin/bash

# CI/CD集成系统
# 提供代码质量检查、自动化测试、部署流程和质量门控

# 加载基础库
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || realpath "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")/.." &>/dev/null && pwd)"
source "$SCRIPT_DIR/constants.sh"
source "$SCRIPT_DIR/core/lib.sh"
source "$SCRIPT_DIR/dev/code_quality.sh"

# CI/CD配置
CICD_CONFIG_DIR="$SCRIPT_DIR/cicd"
CICD_REPORTS_DIR="$SCRIPT_DIR/reports/cicd"
CICD_ARTIFACTS_DIR="$SCRIPT_DIR/artifacts"
QUALITY_GATE_CONFIG="$CICD_CONFIG_DIR/quality_gates.conf"

# 确保目录存在
ensure_dir "$CICD_CONFIG_DIR"
ensure_dir "$CICD_REPORTS_DIR"
ensure_dir "$CICD_ARTIFACTS_DIR"

# 初始化CI/CD环境
init_cicd() {
    log_step "初始化CI/CD环境"
    
    # 创建质量门控配置
    create_quality_gates_config
    
    # 创建GitHub Actions工作流
    create_github_actions_workflow
    
    # 创建GitLab CI配置
    create_gitlab_ci_config
    
    # 创建Jenkins流水线
    create_jenkins_pipeline
    
    # 创建Docker构建配置
    create_docker_build_config
    
    log_info "CI/CD环境初始化完成"
}

# 创建质量门控配置
create_quality_gates_config() {
    log_info "创建质量门控配置..."
    
    cat > "$QUALITY_GATE_CONFIG" << 'EOF'
# 质量门控配置
# 格式: 检查项 阈值 是否阻断

# 代码质量检查
shellcheck_errors 0 true
flake8_errors 0 true
pylint_score 8.0 true
code_coverage 80 true

# 安全检查
security_vulnerabilities 0 true
dependency_vulnerabilities 0 false

# 性能检查
build_time 300 false
test_execution_time 600 false

# 文档检查
documentation_coverage 70 false
readme_exists 1 true
EOF
    
    log_info "质量门控配置已创建: $QUALITY_GATE_CONFIG"
}

# 创建GitHub Actions工作流
create_github_actions_workflow() {
    log_info "创建GitHub Actions工作流..."
    
    local workflow_dir="$SCRIPT_DIR/.github/workflows"
    ensure_dir "$workflow_dir"
    
    cat > "$workflow_dir/ci.yml" << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  quality-check:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install flake8 pylint pytest pytest-cov
        sudo apt-get update
        sudo apt-get install -y shellcheck
    
    - name: Run code quality checks
      run: |
        ./config/dev/code_quality.sh check
    
    - name: Run security checks
      run: |
        ./config/security/security_hardening.sh check
    
    - name: Run tests
      run: |
        pytest --cov=src --cov-report=xml
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
    
    - name: Quality gate check
      run: |
        ./config/dev/cicd_integration.sh quality_gate
  
  build:
    needs: quality-check
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build Docker image
      run: |
        docker build -t remote-dev:${{ github.sha }} .
    
    - name: Push to registry
      if: github.ref == 'refs/heads/main'
      run: |
        echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
        docker push remote-dev:${{ github.sha }}
  
  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Deploy to staging
      run: |
        ./config/dev/cicd_integration.sh deploy staging
    
    - name: Run smoke tests
      run: |
        ./config/dev/cicd_integration.sh smoke_test staging
    
    - name: Deploy to production
      if: success()
      run: |
        ./config/dev/cicd_integration.sh deploy production
EOF
    
    log_info "GitHub Actions工作流已创建"
}

# 创建GitLab CI配置
create_gitlab_ci_config() {
    log_info "创建GitLab CI配置..."
    
    cat > "$SCRIPT_DIR/.gitlab-ci.yml" << 'EOF'
stages:
  - quality
  - security
  - test
  - build
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

before_script:
  - apt-get update -qq && apt-get install -y -qq git curl

quality_check:
  stage: quality
  image: python:3.9
  script:
    - pip install flake8 pylint
    - apt-get install -y shellcheck
    - ./config/dev/code_quality.sh check
  artifacts:
    reports:
      junit: reports/quality-report.xml
    paths:
      - reports/
  only:
    - merge_requests
    - main
    - develop

security_check:
  stage: security
  image: python:3.9
  script:
    - ./config/security/security_hardening.sh check
  artifacts:
    reports:
      junit: reports/security-report.xml
    paths:
      - reports/
  only:
    - merge_requests
    - main
    - develop

test:
  stage: test
  image: python:3.9
  script:
    - pip install pytest pytest-cov
    - pytest --cov=src --cov-report=xml --junitxml=reports/test-report.xml
  artifacts:
    reports:
      junit: reports/test-report.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    paths:
      - reports/
  coverage: '/TOTAL.*\s+(\d+%)$/'
  only:
    - merge_requests
    - main
    - develop

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  only:
    - main
    - develop

deploy_staging:
  stage: deploy
  image: alpine:latest
  script:
    - apk add --no-cache curl
    - ./config/dev/cicd_integration.sh deploy staging
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - develop

deploy_production:
  stage: deploy
  image: alpine:latest
  script:
    - ./config/dev/cicd_integration.sh deploy production
  environment:
    name: production
    url: https://production.example.com
  when: manual
  only:
    - main
EOF
    
    log_info "GitLab CI配置已创建"
}

# 创建Jenkins流水线
create_jenkins_pipeline() {
    log_info "创建Jenkins流水线..."
    
    cat > "$SCRIPT_DIR/Jenkinsfile" << 'EOF'
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-registry.com'
        IMAGE_NAME = 'remote-dev'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Quality Check') {
            parallel {
                stage('Code Quality') {
                    steps {
                        sh './config/dev/code_quality.sh check'
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: false,
                                keepAll: true,
                                reportDir: 'reports',
                                reportFiles: 'quality-report.html',
                                reportName: 'Quality Report'
                            ])
                        }
                    }
                }
                
                stage('Security Check') {
                    steps {
                        sh './config/security/security_hardening.sh check'
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: false,
                                keepAll: true,
                                reportDir: 'reports',
                                reportFiles: 'security-report.html',
                                reportName: 'Security Report'
                            ])
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            steps {
                sh 'python -m pytest --cov=src --cov-report=xml --junitxml=reports/test-report.xml'
            }
            post {
                always {
                    junit 'reports/test-report.xml'
                    publishCoverage adapters: [
                        coberturaAdapter('coverage.xml')
                    ], sourceFileResolver: sourceFiles('STORE_LAST_BUILD')
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                script {
                    def result = sh(
                        script: './config/dev/cicd_integration.sh quality_gate',
                        returnStatus: true
                    )
                    if (result != 0) {
                        error("Quality gate failed")
                    }
                }
            }
        }
        
        stage('Build') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    def image = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}")
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                sh './config/dev/cicd_integration.sh deploy staging'
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?', ok: 'Deploy'
                sh './config/dev/cicd_integration.sh deploy production'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            emailext (
                subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Build failed. Check console output at ${env.BUILD_URL}",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
    }
}
EOF
    
    log_info "Jenkins流水线已创建"
}

# 创建Docker构建配置
create_docker_build_config() {
    log_info "创建Docker构建配置..."
    
    cat > "$SCRIPT_DIR/Dockerfile.ci" << 'EOF'
# Multi-stage build for CI/CD
FROM python:3.9-slim as builder

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    shellcheck \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY src/ ./src/
COPY config/ ./config/

# Run quality checks
RUN ./config/dev/code_quality.sh check

# Production stage
FROM python:3.9-slim as production

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy from builder
COPY --from=builder /app/src ./src
COPY --from=builder /app/config ./config
COPY --from=builder /usr/local/lib/python3.9/site-packages /usr/local/lib/python3.9/site-packages

# Create non-root user
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["python", "src/main.py"]
EOF
    
    log_info "Docker构建配置已创建"
}

# 质量门控检查
quality_gate() {
    log_step "执行质量门控检查"
    
    local gate_passed=true
    local report_file="$CICD_REPORTS_DIR/quality_gate_$(date +%Y%m%d_%H%M%S).json"
    local results=()
    
    # 读取质量门控配置
    while IFS=' ' read -r check_item threshold blocking; do
        # 跳过注释和空行
        [[ "$check_item" =~ ^#.*$ ]] && continue
        [[ -z "$check_item" ]] && continue
        
        local result=$(check_quality_gate_item "$check_item" "$threshold")
        local status="PASS"
        
        if [ "$result" != "PASS" ]; then
            status="FAIL"
            if [ "$blocking" = "true" ]; then
                gate_passed=false
            fi
        fi
        
        results+=("{\"item\":\"$check_item\",\"threshold\":\"$threshold\",\"result\":\"$result\",\"status\":\"$status\",\"blocking\":$blocking}")
        
        log_info "质量门控检查: $check_item - $status"
    done < "$QUALITY_GATE_CONFIG"
    
    # 生成报告
    generate_quality_gate_report "$report_file" "$gate_passed" "${results[@]}"
    
    if [ "$gate_passed" = true ]; then
        log_info "✅ 质量门控检查通过"
        return 0
    else
        log_error "❌ 质量门控检查失败"
        return 1
    fi
}

# 检查单个质量门控项
check_quality_gate_item() {
    local item="$1"
    local threshold="$2"
    
    case "$item" in
        "shellcheck_errors")
            local errors=$(find "$SCRIPT_DIR" -name "*.sh" -exec shellcheck {} \; 2>&1 | grep -c "error" || echo "0")
            [ "$errors" -le "$threshold" ] && echo "PASS" || echo "FAIL($errors errors)"
            ;;
        "flake8_errors")
            local errors=$(flake8 "$SCRIPT_DIR/src" 2>&1 | wc -l || echo "0")
            [ "$errors" -le "$threshold" ] && echo "PASS" || echo "FAIL($errors errors)"
            ;;
        "pylint_score")
            local score=$(pylint "$SCRIPT_DIR/src" 2>/dev/null | grep "Your code has been rated" | awk '{print $7}' | cut -d'/' -f1 || echo "0")
            [ "$(echo "$score >= $threshold" | bc -l 2>/dev/null || echo "0")" -eq 1 ] && echo "PASS" || echo "FAIL($score)"
            ;;
        "code_coverage")
            local coverage=$(pytest --cov="$SCRIPT_DIR/src" --cov-report=term-missing 2>/dev/null | grep "TOTAL" | awk '{print $4}' | sed 's/%//' || echo "0")
            [ "$coverage" -ge "$threshold" ] && echo "PASS" || echo "FAIL($coverage%)"
            ;;
        "security_vulnerabilities")
            local vulns=$(./config/security/security_hardening.sh check 2>&1 | grep -c "问题" || echo "0")
            [ "$vulns" -le "$threshold" ] && echo "PASS" || echo "FAIL($vulns vulnerabilities)"
            ;;
        "readme_exists")
            [ -f "$SCRIPT_DIR/README.md" ] && echo "PASS" || echo "FAIL(no README.md)"
            ;;
        *)
            echo "UNKNOWN"
            ;;
    esac
}

# 生成质量门控报告
generate_quality_gate_report() {
    local report_file="$1"
    local gate_passed="$2"
    shift 2
    local results=("$@")
    
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    cat > "$report_file" << EOF
{
    "timestamp": "$timestamp",
    "gate_passed": $gate_passed,
    "results": [
$(IFS=$'\n'; echo "${results[*]}" | sed 's/$/,/' | sed '$ s/,$//')
    ]
}
EOF
    
    log_info "质量门控报告已生成: $report_file"
}

# 部署到指定环境
deploy() {
    local environment="$1"
    
    log_step "部署到$environment环境"
    
    case "$environment" in
        "staging")
            deploy_to_staging
            ;;
        "production")
            deploy_to_production
            ;;
        *)
            log_error "不支持的环境: $environment"
            return 1
            ;;
    esac
}

# 部署到staging环境
deploy_to_staging() {
    log_info "部署到staging环境..."
    
    # 停止现有服务
    docker-compose -f "$SCRIPT_DIR/config/docker/docker-compose.staging.yml" down
    
    # 拉取最新镜像
    docker-compose -f "$SCRIPT_DIR/config/docker/docker-compose.staging.yml" pull
    
    # 启动服务
    docker-compose -f "$SCRIPT_DIR/config/docker/docker-compose.staging.yml" up -d
    
    # 等待服务启动
    sleep 30
    
    # 健康检查
    if curl -f http://staging.example.com/health; then
        log_info "staging环境部署成功"
        return 0
    else
        log_error "staging环境部署失败"
        return 1
    fi
}

# 部署到production环境
deploy_to_production() {
    log_info "部署到production环境..."
    
    # 创建备份
    create_deployment_backup
    
    # 蓝绿部署
    blue_green_deploy
    
    log_info "production环境部署成功"
}

# 创建部署备份
create_deployment_backup() {
    log_info "创建部署备份..."
    
    local backup_dir="$CICD_ARTIFACTS_DIR/backups/$(date +%Y%m%d_%H%M%S)"
    ensure_dir "$backup_dir"
    
    # 备份配置文件
    cp -r "$SCRIPT_DIR/config" "$backup_dir/"
    
    # 备份数据库（如果有）
    # mysqldump -u root -p database > "$backup_dir/database.sql"
    
    log_info "备份已创建: $backup_dir"
}

# 蓝绿部署
blue_green_deploy() {
    log_info "执行蓝绿部署..."
    
    # 部署到绿色环境
    docker-compose -f "$SCRIPT_DIR/config/docker/docker-compose.green.yml" up -d
    
    # 等待服务启动
    sleep 30
    
    # 健康检查
    if curl -f http://green.example.com/health; then
        log_info "绿色环境启动成功，切换流量..."
        
        # 切换负载均衡器指向绿色环境
        # nginx reload or load balancer config update
        
        # 停止蓝色环境
        docker-compose -f "$SCRIPT_DIR/config/docker/docker-compose.blue.yml" down
        
        log_info "蓝绿部署完成"
    else
        log_error "绿色环境启动失败，回滚..."
        docker-compose -f "$SCRIPT_DIR/config/docker/docker-compose.green.yml" down
        return 1
    fi
}

# 冒烟测试
smoke_test() {
    local environment="$1"
    
    log_step "执行冒烟测试: $environment"
    
    local base_url
    case "$environment" in
        "staging")
            base_url="http://staging.example.com"
            ;;
        "production")
            base_url="http://production.example.com"
            ;;
        *)
            log_error "不支持的环境: $environment"
            return 1
            ;;
    esac
    
    # 基础健康检查
    if ! curl -f "$base_url/health"; then
        log_error "健康检查失败"
        return 1
    fi
    
    # API测试
    if ! curl -f "$base_url/api/status"; then
        log_error "API测试失败"
        return 1
    fi
    
    # 功能测试
    if ! curl -f "$base_url/"; then
        log_error "首页访问失败"
        return 1
    fi
    
    log_info "冒烟测试通过"
    return 0
}

# 主函数
main() {
    case "${1:-help}" in
        "init")
            init_cicd
            ;;
        "quality_gate")
            quality_gate
            ;;
        "deploy")
            deploy "$2"
            ;;
        "smoke_test")
            smoke_test "$2"
            ;;
        "backup")
            create_deployment_backup
            ;;
        "help"|*)
            echo "CI/CD集成系统 🚀"
            echo ""
            echo "用法: $0 <命令> [参数]"
            echo ""
            echo "命令:"
            echo "  init           - 初始化CI/CD环境"
            echo "  quality_gate   - 执行质量门控检查"
            echo "  deploy <env>   - 部署到指定环境"
            echo "  smoke_test <env> - 执行冒烟测试"
            echo "  backup         - 创建部署备份"
            echo "  help           - 显示帮助信息"
            ;;
    esac
}

# 如果直接运行脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 