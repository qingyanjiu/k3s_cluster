#!/bin/bash
# 06-install-jenkins.sh - Jenkins CI/CD 安装
# 使用 Helm 部署到 K3s
# 官方文档: https://jenkins.io/doc/book/installing/kubernetes/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VALUES_FILE="$PROJECT_DIR/manifests/jenkins/values.yaml"

echo "========================================="
echo "K8s DevOps - 安装 Jenkins"
echo "========================================="

# 安装 Helm（如果没有）
if ! command -v helm &> /dev/null; then
    echo "安装 Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# 添加 Jenkins 仓库
echo "添加 Jenkins 仓库..."
helm repo add jenkinsci https://charts.jenkins.io
helm repo update

# 安装 Jenkins
echo "安装 Jenkins..."
helm upgrade --install jenkins jenkinsci/jenkins -n jenkins \
    -f $VALUES_FILE \
    --create-namespace

# 等待 Jenkins 就绪
echo "等待 Jenkins 就绪..."
kubectl wait --namespace jenkins \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=jenkins-controller \
  --timeout=300s

echo ""
echo "========================================="
echo "Jenkins 安装完成!"
echo "========================================="
kubectl get pods -n jenkins
echo ""
echo "Jenkins 地址: http://jenkins.local"
echo "用户名: admin"
echo "密码: admin123"
