#!/bin/bash
# 01-prepare-server.sh - K8s DevOps 基础设施 - 服务器初始化
# 适用于: Ubuntu 20.04+ / CentOS 7+

set -e

echo "========================================="
echo "K8s DevOps - 服务器初始化"
echo "========================================="

# 检测操作系统
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "无法检测操作系统"
    exit 1
fi

echo "检测到操作系统: $OS"

# 更新系统
echo "更新系统包..."
if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    apt update && apt upgrade -y
elif [ "$OS" == "centos" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ]; then
    yum update -y
else
    echo "不支持的操作系统: $OS"
    exit 1
fi

# 安装基础工具
echo "安装基础工具..."
if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    apt install -y curl wget vim git unzip apt-transport-https ca-certificates gnupg lsb-release
elif [ "$OS" == "centos" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ]; then
    yum install -y curl wget vim git unzip bind-utils
fi

# 关闭防火墙（K3s 需要）
echo "关闭防火墙..."
if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ]; then
    systemctl stop ufw 2>/dev/null || true
    systemctl disable ufw 2>/dev/null || true
elif [ "$OS" == "centos" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ]; then
    systemctl stop firewalld 2>/dev/null || true
    systemctl disable firewalld 2>/dev/null || true
fi

# 关闭 SELinux
if [ "$OS" == "centos" ] || [ "$OS" == "rocky" ] || [ "$OS" == "almalinux" ]; then
    setenforce 0 2>/dev/null || true
    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config 2>/dev/null || true
fi

# 关闭 swap
echo "关闭 swap..."
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/' /etc/fstab

# 配置内核参数
echo "配置内核参数..."
cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

echo ""
echo "========================================="
echo "服务器初始化完成!"
echo "下一步: 运行 02-install-k3s.sh"
echo "========================================="
