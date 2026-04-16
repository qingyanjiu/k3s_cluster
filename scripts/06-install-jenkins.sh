#!/bin/bash
# 06-install-jenkins.sh - Jenkins CI/CD 安装
# 使用 Helm 部署到 K3s

set -e

echo "========================================="
echo "K8s DevOps - 安装 Jenkins"
echo "========================================="

# 安装 Helm（如果没有）
if ! command -v helm &> /dev/null; then
    echo "安装 Helm..."
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# 创建 Jenkins namespace
kubectl create namespace jenkins || true

# 添加 Jenkins 仓库
echo "添加 Jenkins 仓库..."
helm repo add jenkinsci https://charts.jenkins.io
helm repo update

# 创建 Jenkins values 配置
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
mkdir -p $PROJECT_DIR/manifests/jenkins

cat > $PROJECT_DIR/manifests/jenkins/jenkins-values.yaml <<EOF
controller:
  image: jenkins/jenkins:lts-jdk17
  imagePullPolicy: IfNotPresent

  # 资源配置
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 2000m
      memory: 4Gi

  # 持久化
  persistence:
    storageClass: nfs-storage
    size: 10Gi

  # Ingress
  ingress:
    enabled: true
    ingressClassName: nginx
    hostName: jenkins.local
    annotations:
      nginx.ingress.kubernetes.io/proxy-body-size: "100m"

  # Jenkins 配置
  adminUser: admin
  adminPassword: admin123

  # 插件
  installPlugins:
    - kubernetes
    - workflow-aggregator
    - git
    - configuration-as-code
    - blueocean
    - docker-workflow
    - maven
    - nodejs

  # 安全配置
  disableRememberMe: false

  # Java Options
  javaOpts: "-Djenkins.install.runSetupWizard=false"

# Agent 配置
agent:
  enabled: true
EOF

# 安装 Jenkins
echo "安装 Jenkins..."
helm upgrade --install jenkins jenkinsci/jenkins -n jenkins -f $PROJECT_DIR/manifests/jenkins/jenkins-values.yaml --create-namespace

# 等待 Jenkins 就绪
echo "等待 Jenkins 就绪..."
kubectl wait --namespace jenkins \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=jenkins-controller \
  --timeout=300s

# 获取初始密码
echo ""
echo "========================================="
echo "Jenkins 安装完成!"
echo "========================================="
echo "Jenkins 地址: http://jenkins.local"
echo ""
echo "获取初始密码:"
kubectl exec -n jenkins jenkins-0 -- cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || \
kubectl exec -n jenkins deploy/jenkins -n jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null || \
echo "请查看 Jenkins Pod 日志"
echo ""
echo "获取 Pod 名称:"
kubectl get pods -n jenkins
echo ""
echo "下一步: 运行 07-install-argocd.sh"
