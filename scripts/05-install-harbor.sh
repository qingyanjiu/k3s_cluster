#!/bin/bash
# 05-install-harbor.sh - Harbor 镜像仓库安装
# 版本: v2.9.0

set -e

HARBOR_VERSION=${1:-v2.9.0}
HARBOR_DOMAIN=${2:-harbor.local}

echo "========================================="
echo "K8s DevOps - 安装 Harbor 镜像仓库"
echo "版本: $HARBOR_VERSION"
echo "域名: $HARBOR_DOMAIN"
echo "========================================="

# 创建安装目录
mkdir -p ~/harbor && cd ~/harbor

# 下载 Harbor
echo "下载 Harbor..."
wget -q https://github.com/goharbor/harbor/releases/download/$HARBOR_VERSION/harbor-offline-installer-$HARBOR_VERSION.tgz

# 解压
echo "解压 Harbor..."
tar -xzf harbor-offline-installer-$HARBOR_VERSION.tgz

# 生成配置文件
echo "生成配置文件..."
cat > harbor.yml <<EOF
# Harbor Configuration
hostname: $HARBOR_DOMAIN
http:
  port: 80
https:
  enabled: false

# 数据存储
data_volume: /data/harbor

# Harbor Admin 密码
harbor_admin_password: Harbor12345

# 数据库
database:
  password: root123
  max_idle_conns: 50
  max_open_conns: 100

# Storage
trivy:
  ignore_unfixed: false
  offline: true
persistence:
  persistentVolumeClaim:
    registry:
      storageClass: "nfs-storage"
      size: 10Gi
    chartmuseum:
      storageClass: "nfs-storage"
      size: 5Gi
    jobservice:
      jobLog:
        storageClass: "nfs-storage"
        size: 1Gi
    database:
      storageClass: "nfs-storage"
      size: 1Gi
    redis:
      storageClass: "nfs-storage"
      size: 1Gi

# 日志
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M

# 无需注释服务
notary: false
clair: false
EOF

# 准备数据目录
mkdir -p /data/harbor

# 安装 Docker Compose（如果没有）
if ! command -v docker-compose &> /dev/null; then
    echo "安装 Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
fi

# 运行安装
echo "安装 Harbor..."
cd ~/harbor/harbor
./install.sh --with-notary --with-trivy --with-clair

# 启动 Harbor
echo "启动 Harbor..."
cd ~/harbor/harbor
docker compose up -d

# 等待 Harbor 就绪
echo "等待 Harbor 就绪..."
sleep 10

# 创建 Ingress
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cat > $PROJECT_DIR/manifests/harbor/harbor-ingress.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: harbor-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "100m"
spec:
  ingressClassName: nginx
  rules:
  - host: $HARBOR_DOMAIN
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: harbor
            port:
              number: 80
EOF

echo ""
echo "========================================="
echo "Harbor 安装完成!"
echo "========================================="
docker compose ps
echo ""
echo "Harbor 地址: http://$HARBOR_DOMAIN"
echo "默认账号: admin"
echo "默认密码: Harbor12345"
echo ""
echo "请在 /etc/hosts 中添加:"
echo "$HARBOR_DOMAIN"
echo ""
echo "下一步: 运行 06-install-jenkins.sh"
