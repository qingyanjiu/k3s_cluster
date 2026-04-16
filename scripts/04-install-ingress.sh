#!/bin/bash
# 04-install-ingress.sh - Ingress Nginx 安装
# 提供 HTTP/HTTPS 入口

set -e

echo "========================================="
echo "K8s DevOps - 安装 Ingress Nginx"
echo "========================================="

# 安装 Ingress Nginx Controller
echo "安装 Ingress Nginx Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

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
