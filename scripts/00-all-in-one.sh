#!/bin/bash
# K8s DevOps 基础设施 - 一键安装脚本
# 按顺序执行所有安装脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "K8s DevOps 基础设施一键安装"
echo "========================================="
echo ""

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
    echo "请使用 root 权限运行此脚本"
    echo "sudo $0"
    exit 1
fi

# 确认开始
read -p "即将开始安装，是否继续? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
fi

# 按顺序执行所有脚本
scripts=(
    "01-prepare-server.sh"
    "02-install-k3s.sh"
    "03-install-nfs.sh"
    "04-install-ingress.sh"
    "05-install-harbor.sh"
    "06-install-jenkins.sh"
    "07-install-argocd.sh"
    "08-install-monitoring.sh"
    "09-install-logging.sh"
    "10-deploy-sample-app.sh"
    "11-install-kuboard.sh"
)

total=${#scripts[@]}
current=0

for script in "${scripts[@]}"; do
    current=$((current + 1))
    echo ""
    echo "========================================="
    echo "[$current/$total] 执行: $script"
    echo "========================================="

    if [ -f "$SCRIPT_DIR/$script" ]; then
        chmod +x "$SCRIPT_DIR/$script"
        bash "$SCRIPT_DIR/$script"
    else
        echo "脚本不存在: $script"
        exit 1
    fi
done

echo ""
echo "========================================="
echo "所有安装完成!"
echo "========================================="
