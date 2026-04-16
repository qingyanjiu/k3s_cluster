#!/bin/bash
# 08-install-monitoring.sh - Prometheus + Grafana 监控安装
# 使用 kube-prometheus-stack

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "K8s DevOps - 安装监控组件"
echo "========================================="

# 添加 Prometheus 社区仓库
echo "添加 Prometheus 仓库..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 部署 Grafana 配置
echo "部署 Grafana 配置..."
kubectl apply -f $PROJECT_DIR/manifests/monitoring/grafana-config.yaml

# 安装 kube-prometheus-stack
echo "安装 kube-prometheus-stack..."
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f $PROJECT_DIR/manifests/monitoring/kube-prometheus-stack.yaml \
  --create-namespace

# 等待监控组件就绪
echo "等待 Pod 就绪..."
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=prometheus \
  --timeout=300s || true

echo ""
echo "========================================="
echo "监控组件安装完成!"
echo "========================================="
kubectl get pods -n monitoring
echo ""
echo "Grafana 地址: http://grafana.local"
echo "用户名: admin"
echo "密码: admin123"
