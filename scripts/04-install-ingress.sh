#!/bin/bash
# 04-install-ingress.sh - Ingress Nginx 安装
# 提供 HTTP/HTTPS 入口

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "K8s DevOps - 安装 Ingress Nginx"
echo "========================================="

# 安装 Ingress Nginx Controller
echo "安装 Ingress Nginx Controller..."
kubectl apply -f $PROJECT_DIR/manifests/ingress-nginx/ingress-nginx.yaml

# 等待 Ingress Controller 就绪
echo "等待 Ingress Controller 就绪..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s

echo ""
echo "========================================="
echo "Ingress Nginx 安装完成!"
echo "========================================="
kubectl get pods -n ingress-nginx
echo ""
echo "Ingress Controller Service:"
kubectl get svc -n ingress-nginx
echo ""
echo "下一步: 运行 05-install-harbor.sh"
