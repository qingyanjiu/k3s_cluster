#!/bin/bash
# 09-install-logging.sh - Loki 日志系统安装

set -e

echo "========================================="
echo "K8s DevOps - 安装日志组件 (Loki)"
echo "========================================="

# 添加 Loki 仓库
echo "添加 Loki 仓库..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 创建 logging namespace（如果没有）
kubectl create namespace logging || true

# 安装 Loki
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
mkdir -p $PROJECT_DIR/manifests/logging

cat > $PROJECT_DIR/manifests/logging/loki-values.yaml <<EOF
loki:
  persistence:
    enabled: true
    storageClassName: nfs-storage
    size: 10Gi

promtail:
  enabled: true
  config:
    logLevel: info
    serverPort: 3101
    clients:
      - url: http://loki:3100/loki/api/v1/push
EOF

echo "安装 Loki..."
helm upgrade --install loki grafana/loki \
  -n logging \
  -f $PROJECT_DIR/manifests/logging/loki-values.yaml \
  --create-namespace

# 等待 Loki 就绪
echo "等待 Loki 就绪..."
kubectl wait --namespace logging \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=loki \
  --timeout=180s

echo ""
echo "========================================="
echo "Loki 日志系统安装完成!"
echo "========================================="
kubectl get pods -n logging
echo ""
echo "Loki 地址: http://loki.logging:3100"
echo ""
echo "在 Grafana 中添加 Loki 数据源:"
echo "URL: http://loki.logging:3100"
echo ""
echo "所有组件安装完成!"
echo "下一步: 运行 10-deploy-sample-app.sh 部署示例应用"
