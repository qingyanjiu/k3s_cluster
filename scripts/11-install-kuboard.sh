#!/bin/bash
# 11-install-kuboard.sh - Kuboard 可视化管理界面安装
# 使用 K8s 方式部署
# 官方文档: https://www.kuboard.cn/install/v3/install.html

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "========================================="
echo "K8s DevOps - 安装 Kuboard 可视化管理界面"
echo "========================================="

# Kuboard 端口配置（避免与 ArgoCD NodePort 30080 冲突）
KUBOARD_WEB_PORT=${KUBOARD_WEB_PORT:-30083}
KUBOARD_AGENT_PORT=${KUBOARD_AGENT_PORT:-30084}

echo "Web 端口: $KUBOARD_WEB_PORT"
echo "Agent 端口: $KUBOARD_AGENT_PORT"

# 修改 kuboard-v3.yaml 中的端口
sed -i.bak "s/KUBOARD_SERVER_NODE_PORT: '30080'/KUBOARD_SERVER_NODE_PORT: '$KUBOARD_WEB_PORT'/g" $PROJECT_DIR/manifests/kuboard/kuboard-v3.yaml
sed -i "s/KUBOARD_AGENT_SERVER_UDP_PORT: '30081'/KUBOARD_AGENT_SERVER_UDP_PORT: '$KUBOARD_AGENT_PORT'/g" $PROJECT_DIR/manifests/kuboard/kuboard-v3.yaml
sed -i "s/KUBOARD_AGENT_SERVER_TCP_PORT: '30081'/KUBOARD_AGENT_SERVER_TCP_PORT: '$KUBOARD_AGENT_PORT'/g" $PROJECT_DIR/manifests/kuboard/kuboard-v3.yaml

# 修改 Service 端口
sed -i.bak2 "s/nodePort: 30080/nodePort: $KUBOARD_WEB_PORT/g" $PROJECT_DIR/manifests/kuboard/kuboard-v3.yaml
sed -i "s/nodePort: 30081/nodePort: $KUBOARD_AGENT_PORT/g" $PROJECT_DIR/manifests/kuboard/kuboard-v3.yaml

# 安装 Kuboard
echo "安装 Kuboard v3..."
kubectl apply -f $PROJECT_DIR/manifests/kuboard/kuboard-v3-swr.yaml
kubectl apply -f $PROJECT_DIR/manifests/kuboard/kuboard-v3.yaml

# 等待 Kuboard 就绪
echo "等待 Kuboard 就绪..."
kubectl wait --namespace kuboard \
  --for=condition=ready pod \
  --selector=k8s.kuboard.cn/name=kuboard-v3 \
  --timeout=180s || true

# 更新 Ingress（使用 Ingress 方式访问）
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
echo ""
echo "访问方式:"
echo "  - Ingress: http://kuboard.local"
echo "  - NodePort: http://<节点IP>:$KUBOARD_WEB_PORT"
echo ""
echo "默认账号: admin"
echo "默认密码: Kuboard123"
