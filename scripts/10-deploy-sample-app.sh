#!/bin/bash
# 10-deploy-sample-app.sh - 部署示例应用
# 包含 Vue3 前端（Java 后端需要配置镜像源）

set -e

echo "========================================="
echo "K8s DevOps - 部署示例应用"
echo "========================================="

# 创建示例应用 namespace
kubectl create namespace sample-app || true

# Java 微服务配置（可选，默认跳过）
# 如需部署 Java 后端，请手动修改镜像为可用的国内镜像
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
mkdir -p $PROJECT_DIR/manifests/sample-app

# 默认只部署 Vue3 前端，如需部署 Java 后端取消注释
cat > $PROJECT_DIR/manifests/sample-app/java-service.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-backend
  namespace: sample-app
  labels:
    app: java-backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: java-backend
  template:
    metadata:
      labels:
        app: java-backend
    spec:
      containers:
      - name: java-backend
        # 使用国内镜像源，如阿里云镜像或自建仓库
        # image: registry.cn-hangzhou.aliyuncs.com/library/openjdk:17-slim
        # 或使用其他可用的镜像
        image: eclipse-temurin:17-jre
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "1Gi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: java-backend
  namespace: sample-app
spec:
  selector:
    app: java-backend
  ports:
  - port: 8080
    targetPort: 8080
  type: ClusterIP
EOF

# Vue3 前端配置（使用 nginx:alpine 官方镜像）
cat > $PROJECT_DIR/manifests/sample-app/vue-frontend.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vue-frontend
  namespace: sample-app
  labels:
    app: vue-frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vue-frontend
  template:
    metadata:
      labels:
        app: vue-frontend
    spec:
      containers:
      - name: vue-frontend
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "256Mi"
            cpu: "200m"
        volumeMounts:
        - name: nginx-config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: nginx-config
        configMap:
          name: vue-frontend-nginx
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: vue-frontend-nginx
  namespace: sample-app
data:
  default.conf: |
    server {
        listen 80;
        server_name _;
        location / {
            root /usr/share/nginx/html;
            index index.html;
            try_files \$uri \$uri/ /index.html;
        }
        location /api/ {
            proxy_pass http://java-backend.sample-app:8080/;
        }
    }
---
apiVersion: v1
kind: Service
metadata:
  name: vue-frontend
  namespace: sample-app
spec:
  selector:
    app: vue-frontend
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: sample-app-ingress
  namespace: sample-app
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app.local
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: java-backend
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: vue-frontend
            port:
              number: 80
EOF

# 部署应用
# 只部署 Vue3 前端（Java 后端需要配置镜像源）
echo "部署 Vue3 前端..."
kubectl apply -f $PROJECT_DIR/manifests/sample-app/vue-frontend.yaml

# 等待应用就绪
echo "等待应用就绪..."
kubectl wait --namespace sample-app \
  --for=condition=ready pod \
  --selector=app=vue-frontend \
  --timeout=120s || true

echo ""
echo "========================================="
echo "示例应用部署完成!"
echo "========================================="
kubectl get pods -n sample-app
kubectl get svc -n sample-app
kubectl get ingress -n sample-app
echo ""
echo "访问应用: http://app.local"
echo ""
echo "注意: Java 后端默认未部署（Docker Hub 镜像拉取限制）"
echo "如需部署，请配置国内镜像源后取消注释 java-service.yaml"
echo ""
echo "========================================="
echo "K8s DevOps 基础设施搭建完成!"
echo "========================================="
echo ""
echo "服务访问地址:"
echo "  - Jenkins:    http://jenkins.local"
echo "  - ArgoCD:    https://argocd.local"
echo "  - Grafana:   http://grafana.local"
echo "  - 示例应用:  http://app.local"