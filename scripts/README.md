# K8s DevOps 一键安装脚本

基于 K3s 的 DevOps 基础设施自动化部署脚本，支持一键安装所有常用组件。

## 组件列表

| 序号 | 脚本 | 组件 | 说明 |
|------|------|------|------|
| 00 | 00-all-in-one.sh | 一键安装 | 按顺序执行所有脚本 |
| 01 | 01-prepare-server.sh | 服务器初始化 | 更新系统、关闭防火墙、配置内核参数 |
| 02 | 02-install-k3s.sh | K3s 集群 | 单节点 K3s 安装 |
| 03 | 03-install-nfs.sh | NFS 存储 | NFS 服务器 + NFS Subdir External Provisioner |
| 04 | 04-install-ingress.sh | Ingress Nginx | Ingress Nginx Controller |
| 05 | 05-install-harbor.sh | Harbor 镜像仓库 | Docker Compose 部署的镜像仓库 |
| 06 | 06-install-jenkins.sh | Jenkins CI/CD | Helm 部署的 Jenkins |
| 07 | 07-install-argocd.sh | ArgoCD | GitOps 持续交付工具 |
| 08 | 08-install-monitoring.sh | Prometheus + Grafana | 监控套件 |
| 09 | 09-install-logging.sh | Loki 日志系统 | 日志收集与分析 |
| 10 | 10-deploy-sample-app.sh | 示例应用 | Vue3 前端（Java 后端可选） |
| 11 | 11-install-kuboard.sh | Kuboard | Kubernetes 可视化管理界面（支持 Docker/K8s 方式） |

## 快速开始

### 环境要求

- **操作系统**: Ubuntu 20.04+ / CentOS 7+ / Rocky Linux 8+
- **配置**: 至少 2 CPU / 4GB 内存
- **网络**: 能访问外网（拉取镜像、Helm charts）
- **权限**: root 权限

### 安装步骤

```bash
# 1. 克隆或复制脚本到目标机器
git clone <repo-url> /root/k8s/scripts
cd /root/k8s/scripts

# 2. 一键安装（推荐）
sudo bash 00-all-in-one.sh

# 或者按顺序单独执行
sudo bash 01-prepare-server.sh
sudo bash 02-install-k3s.sh
# ... 继续其他脚本
```

### 访问地址

安装完成后，添加以下 hosts 记录：

```
192.168.0.122 jenkins.local argocd.local grafana.local app.local
# Kuboard（Docker 方式）
127.0.0.1 kuboard.local
```

| 服务 | 地址 | 用户名 | 密码 |
|------|------|--------|------|
| Harbor | http://harbor.local | admin | Harbor12345 |
| Jenkins | http://jenkins.local | admin | admin123 |
| ArgoCD | https://argocd.local | admin | (查看密码) |
| Grafana | http://grafana.local | admin | admin123 |
| Kuboard | http://kuboard.local:30080 | admin | Kuboard123 |
| 示例应用 | http://app.local | - | - |

## 在其他机器上部署

### 方式一：完全重装

```bash
# 在目标机器上执行
git clone <repo-url> /tmp/k8s-scripts
cd /tmp/k8s-scripts/scripts

# 确保已安装 K3s 后，按顺序执行
bash 01-prepare-server.sh   # 可选，如果需要初始化
bash 03-install-nfs.sh       # NFS 存储
bash 04-install-ingress.sh  # Ingress
bash 05-install-harbor.sh   # Harbor
# ... 其他组件
```

### 方式二：使用自定义参数

```bash
# 指定 NFS 服务器地址（用于多节点场景）
NFS_SERVER=192.168.1.100 bash 03-install-nfs.sh

# 指定 Harbor 版本
HARBOR_VERSION=v2.10.0 bash 05-install-harbor.sh

# 指定 Harbor 域名
HARBOR_DOMAIN=harbor.example.com bash 05-install-harbor.sh

# Kuboard 安装方式（默认 docker，可选 k8s）
bash 11-install-kuboard.sh docker
bash 11-install-kuboard.sh k8s
```

## 脚本说明

### 03-install-nfs.sh 参数

| 环境变量 | 默认值 | 说明 |
|----------|--------|------|
| NFS_SERVER | 本机 IP | NFS 服务器地址 |
| NFS_SHARE | /nfs-share | NFS 共享路径 |

### 05-install-harbor.sh 参数

| 参数位置 | 默认值 | 说明 |
|----------|--------|------|
| $1 | v2.9.0 | Harbor 版本 |
| $2 | harbor.local | Harbor 域名 |

```bash
# 示例
bash 05-install-harbor.sh v2.10.0 harbor.mycompany.com
```

## 目录结构

```
k8s/
├── scripts/           # 安装脚本
│   ├── 00-all-in-one.sh
│   ├── 01-prepare-server.sh
│   ├── 02-install-k3s.sh
│   └── ...
└── manifests/        # K8s 资源清单
    ├── storage/
    ├── jenkins/
    ├── argocd/
    ├── monitoring/
    ├── logging/
    ├── sample-app/
    └── kuboard/
```

## 常见问题

### Q: 镜像拉取失败 (Docker Hub 限流)

A: 这是 Docker Hub 对匿名/未认证用户的限制。解决方案：

1. **方案一：使用国内镜像源**
   ```bash
   # 登录 Docker Hub 或使用国内镜像代理
   docker login
   ```

2. **方案二：配置容器镜像仓库**
   ```bash
   # 在 K3s 中配置镜像仓库
   sudo systemctl edit k3s
   # 添加 --mirror 参数
   ```

3. **方案三：修改脚本使用其他镜像**
   - Java 后端：使用 `eclipse-temurin:17-jre` 或国内镜像
   - Kuboard：使用 Docker 方式安装

### Q: Helm 安装超时

A: 增加超时时间：
```bash
helm install <name> <chart> --timeout 10m
```

### Q: NFS 挂载失败

A: 确保 NFS 服务器已启动且防火墙已关闭：
```bash
systemctl status nfs-server
showmount -e
```

### Q: Ingress 不生效

A: 检查 Ingress Controller 是否就绪：
```bash
kubectl get pods -n ingress-nginx
```

### Q: Kuboard 无法启动

A: 脚本支持两种安装方式：
```bash
# Docker 方式（默认，推荐）
bash 11-install-kuboard.sh docker

# K8s 方式
bash 11-install-kuboard.sh k8s
```

## 镜像源配置建议

在中国大陆使用，建议配置镜像加速器：

```bash
# Docker 镜像加速
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker

# K3s 镜像配置（可选）
# 在 /etc/systemd/system/k3s.service 中添加 --mirror 参数
```

## 更新日志

- 2024-04: 初始版本，支持 K3s 单节点部署
- 修复 Harbor 安装路径问题
- 修复 Kuboard 安装链接（支持 Docker/K8s 两种方式）
- 添加 NFS 可配置支持多节点
- 更新示例应用（Java 后端可选），解决 Docker Hub 镜像拉取问题

## License

MIT