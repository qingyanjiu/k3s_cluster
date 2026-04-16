#!/bin/bash
# 07-install-argocd.sh - ArgoCD GitOps 安装

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "K8s DevOps - 安装 ArgoCD"
echo "========================================="

# 创建 ArgoCD namespace
kubectl create namespace argocd || true

# 安装 ArgoCD
echo "安装 ArgoCD..."
kubectl apply -n argocd -f $PROJECT_DIR/manifests/argocd/install.yaml

# 等待 ArgoCD 就绪
echo "等待 ArgoCD 就绪..."
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=180s

# 创建 Ingress
kubectl apply -f $PROJECT_DIR/manifests/argocd/ingress.yaml

# 获取初始密码
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "========================================="
echo "ArgoCD 安装完成!"
echo "========================================="
echo "ArgoCD 地址: https://argocd.local"
echo "用户名: admin"
echo "密码: $ARGOCD_PASSWORD"
echo ""
echo "请在 /etc/hosts 中添加:"
echo "argocd.local"
echo ""
echo "重要: 首次登录后请更改密码!"
echo ""
echo "下一步: 运行 08-install-monitoring.sh"
