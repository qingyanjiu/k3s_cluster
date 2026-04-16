#!/bin/bash
# 08-install-monitoring.sh - Prometheus + Grafana 监控安装
# 使用 kube-prometheus-stack

set -e

echo "========================================="
echo "K8s DevOps - 安装监控组件"
echo "========================================="

# 添加 Prometheus 社区仓库
echo "添加 Prometheus 仓库..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# 创建 monitoring namespace
kubectl create namespace monitoring || true

# 创建 Grafana 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
mkdir -p $PROJECT_DIR/manifests/monitoring

cat > $PROJECT_DIR/manifests/monitoring/grafana-config.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-config
  namespace: monitoring
data:
  grafana.ini: |
    [server]
    domain = grafana.local
    root_url = http://grafana.local
EOF

kubectl apply -f $PROJECT_DIR/manifests/monitoring/grafana-config.yaml

# 安装 kube-prometheus-stack
cat > $PROJECT_DIR/manifests/monitoring/kube-prometheus-stack.yaml <<EOF
prometheus:
  prometheusSpec:
    retention: 15d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: nfs-storage
          resources:
            requests:
              storage: 10Gi

grafana:
  adminPassword: admin123
  persistence:
    enabled: true
    storageClassName: nfs-storage
    size: 5Gi
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - grafana.local
EOF

echo "安装 kube-prometheus-stack..."
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f $PROJECT_DIR/manifests/monitoring/kube-prometheus-stack.yaml \
  --create-namespace

# 等待监控组件就绪
echo "等待监控组件就绪..."
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=kube-prometheus-stack \
  --timeout=300s || true

# 等待所有 Pod 就绪
echo "等待所有 Pod 就绪..."
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
echo "Grafana 账号: admin"
echo "Grafana 密码: admin123"
echo ""
echo "Prometheus 地址: http://prometheus.monitoring:9090"
echo ""
echo "下一步: 运行 09-install-logging.sh"
