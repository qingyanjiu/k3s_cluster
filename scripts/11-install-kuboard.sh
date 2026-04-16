#!/bin/bash
# 11-install-kuboard.sh - Kuboard 可视化管理界面安装
# 支持 Docker 方式和 K8s 方式
# 官方文档: https://www.kuboard.cn/install/v3/install.html

set -e

echo "========================================="
echo "K8s DevOps - 安装 Kuboard 可视化管理界面"
echo "========================================="

# 检测安装方式
INSTALL_METHOD=${1:-docker}

if [ "$INSTALL_METHOD" = "k8s" ]; then
    echo "使用 K8s 方式安装..."
    
    # 创建 namespace
    kubectl create namespace kuboard || true
    
    # 安装 Kuboard v3
    echo "安装 Kuboard..."
    kubectl apply -f https://addons.kuboard.cn/kuboard/kuboard-v3-swr.yaml
    
    # 等待 Kuboard 就绪
    echo "等待 Kuboard 就绪..."
    kubectl wait --namespace kuboard \
      --for=condition=ready pod \
      --selector=k8s.kuboard.cn/name=kuboard-v3 \
      --timeout=180s || true
    
    # 创建 Ingress
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
    mkdir -p $PROJECT_DIR/manifests/kuboard
    
    cat > $PROJECT_DIR/manifests/kuboard/kuboard-ingress.yaml <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kuboard-ingress
  namespace: kuboard
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
  - host: kuboard.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kuboard-v3
            port:
              number: 80
EOF
    
    kubectl apply -f $PROJECT_DIR/manifests/kuboard/kuboard-ingress.yaml
    
    echo ""
    echo "========================================="
    echo "Kuboard 安装完成!"
    echo "========================================="
    kubectl get pods -n kuboard
    
else
    echo "使用 Docker 方式安装..."
    
    # 检查 Docker 是否运行
    if ! command -v docker &> /dev/null; then
        echo "错误: 未安装 Docker，请先安装 Docker 或使用 k8s 方式"
        exit 1
    fi
    
    # 停止现有的 Kuboard 容器（如果存在）
    docker stop kuboard 2>/dev/null || true
    docker rm kuboard 2>/dev/null || true
    
    # 运行 Kuboard
    echo "启动 Kuboard 容器..."
    docker run -d \
      --restart=unless-stopped \
      --name kuboard \
      -p 30080:80/tcp \
      -p 30081:30081/udp \
      -e TZ="Asia/Shanghai" \
      -e KUBOARD_SHELL_ROOT_PASSWORD=Kuboard123 \
      -e KUBOARD_SSO_DEFAULT_PASSWORD=Kuboard123 \
      kuboard/kuboard:v3
    
    # 等待容器启动
    echo "等待 Kuboard 启动..."
    sleep 10
    
    echo ""
    echo "========================================="
    echo "Kuboard 安装完成!"
    echo "========================================="
    docker ps | grep kuboard
fi

echo ""
echo "Kuboard 地址: http://kuboard.local:30080"
echo ""
echo "默认账号: admin"
echo "默认密码: Kuboard123"
echo ""
echo "如需配置 K8s 集群连接，请执行:"
echo "  docker exec kuboard kuboard-agent add-cluster"
echo ""
echo "请在 /etc/hosts 中添加:"
echo "127.0.0.1 kuboard.local"
echo ""
echo "========================================="
echo "所有组件安装完成!"
echo "========================================="