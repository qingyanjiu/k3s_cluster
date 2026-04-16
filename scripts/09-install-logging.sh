#!/bin/bash
# 09-install-logging.sh - Loki 日志系统安装

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "K8s DevOps - 安装日志组件 (Loki)"
echo "========================================="

# 添加 Loki 仓库
echo "添加 Loki 仓库..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 安装 Loki
echo "安装 Loki..."
helm upgrade --install loki grafana/loki \
  -n logging \
  -f $PROJECT_DIR/manifests/logging/values.yaml \
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
echo "在 Grafana 中添加 Loki 数据源:"
echo "URL: http://loki.logging:3100"
