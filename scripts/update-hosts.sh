#!/bin/bash
# update-hosts.sh - 更新 /etc/hosts 配置
# 在本地开发机器上运行

# 获取服务器 IP
SERVER_IP=${1:-"请修改为实际服务器IP"}

cat <<EOF >> /etc/hosts

# K8s DevOps 基础设施
$SERVER_IP  jenkins.local
$SERVER_IP  harbor.local
$SERVER_IP  argocd.local
$SERVER_IP  grafana.local
$SERVER_IP  prometheus.local
$SERVER_IP  app.local
EOF

echo "hosts 配置已更新"
echo "请确保 SERVER_IP 是正确的服务器地址"
