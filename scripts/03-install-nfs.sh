#!/bin/bash
# 03-install-nfs.sh - NFS 存储安装
# 为 K3s 提供持久化存储

set -e

echo "========================================="
echo "K8s DevOps - 安装 NFS 存储"
echo "========================================="

# NFS 服务器配置
# 如果是单节点 K3s，使用本机 IP；如果是多节点，指定 NFS 服务器 IP
NFS_SERVER=${NFS_SERVER:-$(hostname -I | awk '{print $1}')}
NFS_SHARE=${NFS_SHARE:-/nfs-share}

echo "NFS 服务器地址: $NFS_SERVER"
echo "NFS 共享路径: $NFS_SHARE"

# 安装 NFS 服务器（仅在 NFS 服务器节点执行）
if command -v apt &> /dev/null; then
    echo "安装 NFS 服务器..."
    apt update -y
    apt install -y nfs-kernel-server nfs-common
elif command -v yum &> /dev/null; then
    echo "安装 NFS 服务器..."
    yum install -y nfs-utils rpcbind
fi

# 创建 NFS 共享目录
echo "创建 NFS 共享目录: $NFS_SHARE"
mkdir -p $NFS_SHARE
chmod 777 $NFS_SHARE

# 配置 NFS 导出
echo "配置 NFS 导出..."
cat > /etc/exports <<EOF
$NFS_SHARE *(rw,sync,no_subtree_check,no_root_squash)
EOF

# 启动 NFS 服务
echo "启动 NFS 服务..."
if command -v systemctl &> /dev/null; then
    systemctl enable rpcbind nfs-server
    systemctl start rpcbind nfs-server
fi

# 重新导出
exportfs -ra

# 使用 Helm 安装 NFS Client Provisioner
echo "添加 NFS Subdir External Provisioner 仓库..."
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner || true
helm repo update

echo "安装 NFS Client Provisioner..."
helm upgrade --install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --namespace nfs-provisioner \
    --create-namespace \
    --set nfs.server=$NFS_SERVER \
    --set nfs.path=$NFS_SHARE \
    --set storageClass.name=nfs-storage \
    --set storageClass.defaultClass=true \
    --set storageClass.reclaimPolicy=Retain \
    --set storageClass.archiveOnDelete=false

echo ""
echo "========================================="
echo "NFS 存储安装完成!"
echo "========================================="
kubectl get sc
echo ""
echo "下一步: 运行 04-install-ingress.sh"
