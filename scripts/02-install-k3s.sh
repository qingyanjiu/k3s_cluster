#!/bin/bash
# 02-install-k3s.sh - K3s 单节点集群安装
# 官方文档: https://docs.k3s.io/quick-start

set -e

echo "========================================="
echo "K8s DevOps - 安装 K3s 集群"
echo "========================================="

# 检查是否已安装
if command -v k3s &> /dev/null; then
    echo "K3s 已安装"
    kubectl version --short 2>/dev/null || kubectl version
    echo "跳过安装步骤"
    exit 0
fi

# 下载并安装 K3s
echo "下载并安装 K3s..."
curl -sfL https://get.k3s.io | sh -

# 等待 K3s 启动
echo "等待 K3s 启动..."
sleep 10

# 配置 kubectl
echo "配置 kubectl..."
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 644 ~/.kube/config
export KUBECONFIG=~/.kube/config

# 等待节点 Ready
echo "等待节点就绪..."
until kubectl get nodes | grep -q "Ready"; do
    echo "等待节点 Ready..."
    sleep 5
done

# 显示集群信息
echo ""
echo "========================================="
echo "K3s 集群安装完成!"
echo "========================================="
kubectl get nodes
echo ""
echo "K3s 版本:"
kubectl version --short
echo ""
echo "下一步: 运行 03-install-nfs.sh"
