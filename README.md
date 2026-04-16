# K3s 集群 DevOps 基础设施

基于 K3s 的 DevOps 基础设施自动化部署，包含常用组件的一键安装脚本和 Kubernetes 资源清单。

## 目录结构

```
k3s_cluster/
├── scripts/                    # 安装脚本
│   ├── 00-all-in-one.sh       # 一键安装（推荐）
│   ├── 01-prepare-server.sh    # 服务器初始化
│   ├── 02-install-k3s.sh       # K3s 集群安装
│   ├── 03-install-nfs.sh       # NFS 存储
│   ├── 04-install-ingress.sh   # Ingress Nginx
│   ├── 05-install-harbor.sh    # Harbor 镜像仓库
│   ├── 06-install-jenkins.sh   # Jenkins CI/CD
│   ├── 07-install-argocd.sh   # ArgoCD GitOps
│   ├── 08-install-monitoring.sh  # Prometheus + Grafana
│   ├── 09-install-logging.sh  # Loki 日志系统
│   ├── 10-deploy-sample-app.sh   # 示例应用
│   ├── 11-install-kuboard.sh   # Kuboard 管理界面
│   └── update-hosts.sh        # 自动更新 hosts
│
└── manifests/                  # Kubernetes 资源清单
    ├── sample-app/             # 示例应用
    │   ├── vue-frontend.yaml   # Vue 前端 + Nginx 配置
    │   └── java-service.yaml   # Java 后端服务
    ├── services/
    │   └── nodeport-services.yaml  # NodePort 访问配置
    ├── kuboard/
    │   └── kuboard-ingress.yaml    # Kuboard Ingress
    ├── argocd/
    │   └── ingress.yaml        # ArgoCD Ingress
    ├── monitoring/
    │   ├── kube-prometheus-stack.yaml  # Prometheus + Grafana 配置
    │   └── grafana-config.yaml  # Grafana 自定义配置
    ├── logging/
    │   └── values.yaml         # Loki 日志系统配置
    └── jenkins/
        └── values.yaml         # Jenkins Helm 配置
```

## 快速开始

### 环境要求

- **操作系统**: Ubuntu 20.04+ / CentOS 7+ / Rocky Linux 8+
- **配置**: 至少 2 CPU / 4GB 内存
- **网络**: 能访问外网（拉取镜像、Helm charts）
- **权限**: root 权限

### 一键安装

```bash
# 克隆脚本到目标机器
cd scripts

# 一键安装所有组件（推荐）
sudo bash 00-all-in-one.sh

# 或按顺序单独执行
sudo bash 01-prepare-server.sh
sudo bash 02-install-k3s.sh
# ... 其他脚本
```

## 配置文件说明

### 安装脚本参数

#### 03-install-nfs.sh

| 环境变量 | 默认值 | 说明 |
|----------|--------|------|
| NFS_SERVER | 本机 IP | NFS 服务器地址 |
| NFS_SHARE | /nfs-share | NFS 共享路径 |

```bash
# 示例：指定 NFS 服务器
NFS_SERVER=192.168.1.100 bash 03-install-nfs.sh
```

#### 05-install-harbor.sh

| 参数位置 | 默认值 | 说明 |
|----------|--------|------|
| $1 | v2.9.0 | Harbor 版本 |
| $2 | harbor.local | Harbor 域名 |

```bash
# 示例：指定版本和域名
bash 05-install-harbor.sh v2.10.0 harbor.mycompany.com
```

#### 11-install-kuboard.sh

| 参数 | 说明 |
|------|------|
| docker | Docker 方式安装（默认，推荐） |
| k8s | K8s 方式安装 |

```bash
# Docker 方式
bash 11-install-kuboard.sh docker

# K8s 方式
bash 11-install-kuboard.sh k8s
```

### manifests 配置文件

#### manifests/jenkins/values.yaml

Jenkins Helm Chart 配置文件。

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| controller.resources.requests.cpu | 500m | CPU 请求 |
| controller.resources.requests.memory | 512Mi | 内存请求 |
| controller.resources.limits.cpu | 2000m | CPU 限制 |
| controller.resources.limits.memory | 4Gi | 内存限制 |
| controller.persistence.storageClass | nfs-storage | 存储类 |
| controller.persistence.size | 10Gi | PVC 大小 |
| controller.admin.user | admin | 管理员用户名 |
| controller.admin.password | admin123 | 管理员密码 |
| controller.ingress.hostName | jenkins.local | 访问域名 |

#### manifests/monitoring/kube-prometheus-stack.yaml

Prometheus + Grafana 监控配置。

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| prometheus.prometheusSpec.retention | 15d | 数据保留天数 |
| prometheus.prometheusSpec.storageSpec | nfs-storage, 10Gi | Prometheus 存储 |
| grafana.adminPassword | admin123 | Grafana 密码 |
| grafana.persistence | nfs-storage, 5Gi | Grafana 存储 |

#### manifests/monitoring/grafana-config.yaml

Grafana 自定义配置文件（ConfigMap）。

```yaml
data:
  grafana.ini: |
    [server]
    domain = grafana.local        # 修改为实际域名
    root_url = http://grafana.local  # 修改为实际地址
```

#### manifests/logging/values.yaml

Loki 日志系统配置。

| 配置项 | 默认值 | 说明 |
|--------|--------|------|
| loki.persistence.storageClassName | nfs-storage | 存储类 |
| loki.persistence.size | 10Gi | Loki 数据存储 |
| promtail.config.logLevel | info | 日志级别 |
| promtail.config.serverPort | 3101 | Promtail 端口 |

#### manifests/sample-app/vue-frontend.yaml

示例 Vue 前端应用，包含 Deployment、ConfigMap、Service、Ingress。

| 配置项 | 说明 |
|--------|------|
| replicas | 副本数 |
| image | 容器镜像 |
| resources | 资源限制 |
| Ingress host | app.local |

#### manifests/sample-app/java-service.yaml

示例 Java 后端服务。

| 配置项 | 说明 |
|--------|------|
| image | Java 镜像（默认 openjdk:17-slim） |
| replicas | 副本数 |
| containerPort | 8080 |

#### manifests/services/nodeport-services.yaml

NodePort 方式访问配置，用于内网无法配置 DNS/hosts 的场景。

| 服务 | NodePort | 端口 |
|------|----------|------|
| ArgoCD | 30080/30443 | HTTP/HTTPS |
| Jenkins | 30088 | HTTP |
| Grafana | 30090 | HTTP |
| Prometheus | 30091 | HTTP |
| Loki | 30092 | HTTP |

## 控制台访问地址

### 前置条件

安装完成后，需要在**本地开发机器**的 `/etc/hosts` 中添加解析记录：

```bash
# 自动更新（需传入服务器 IP）
bash scripts/update-hosts.sh 192.168.0.122

# 或手动添加
192.168.0.122  jenkins.local
192.168.0.122  harbor.local
192.168.0.122  argocd.local
192.168.0.122  grafana.local
192.168.0.122  prometheus.local
192.168.0.122  app.local
192.168.0.122  kuboard.local
```

> **注意**: 将 `192.168.0.122` 替换为实际服务器 IP。

### 服务访问列表

| 服务 | 地址 | 用户名 | 密码 | 说明 |
|------|------|--------|------|------|
| **Harbor** | http://harbor.local | admin | Harbor12345 | 镜像仓库 |
| **Jenkins** | http://jenkins.local | admin | admin123 | CI/CD 流水线 |
| **ArgoCD** | https://argocd.local | admin | (见下方) | GitOps 交付 |
| **Grafana** | http://grafana.local | admin | admin123 | 监控可视化 |
| **Kuboard** | http://kuboard.local | admin | Kuboard123 | K8s 可视化管理 |
| **示例应用** | http://app.local | - | - | Vue 前端演示 |

### 各服务详细说明

#### Harbor（镜像仓库）

- **地址**: http://harbor.local
- **用途**: 存储和分发 Docker 镜像
- **默认账号**: admin
- **默认密码**: Harbor12345
- **修改密码**: 登录后点击右上角 "admin" -> "修改密码"

#### Jenkins（CI/CD）

- **地址**: http://jenkins.local
- **用途**: 持续集成/持续部署流水线
- **默认账号**: admin
- **默认密码**: admin123
- **插件**: kubernetes, git, blueocean, docker-workflow, maven, nodejs

#### ArgoCD（GitOps）

- **地址**: https://argocd.local
- **用途**: GitOps 持续交付
- **用户名**: admin
- **密码获取**:
  ```bash
  kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
  ```
- **首次登录后请立即修改密码**

#### Grafana（监控）

- **地址**: http://grafana.local
- **用途**: 指标可视化、仪表盘
- **用户名**: admin
- **默认密码**: admin123
- **数据源**: Prometheus（自动配置）
- **内置仪表盘**: Kubernetes 集群概览、节点指标、Pod 状态等

#### Kuboard（K8s 管理界面）

##### 安装方式

使用 **K8s 方式**部署，通过 Ingress 或 NodePort 访问。

```bash
# 安装 Kuboard
bash 11-install-kuboard.sh

# 自定义端口（可选，默认 30083）
KUBOARD_WEB_PORT=30085 bash 11-install-kuboard.sh
```

##### 配置文件

Kuboard 相关配置文件位于 `manifests/kuboard/` 目录：

| 文件 | 说明 |
|------|------|
| `kuboard-v3.yaml` | 主配置文件，包含 Deployment、Service、ConfigMap 等 |
| `kuboard-v3-swr.yaml` | SWR 版本镜像配置 |
| `kuboard-ingress.yaml` | Ingress 配置 |

**常用配置项**（修改 `kuboard-v3.yaml` 中的 ConfigMap）：

```yaml
KUBOARD_SERVER_NODE_PORT: '30083'       # Web 端口
KUBOARD_AGENT_SERVER_UDP_PORT: '30084'  # Agent UDP 端口
KUBOARD_AGENT_SERVER_TCP_PORT: '30084'  # Agent TCP 端口
KUBOARD_AGENT_KEY: 'your-secret-key'    # Agent 通信密钥
KUBOARD_DISABLE_AUDIT: 'false'          # 是否禁用审计
```

##### 访问信息

| 访问方式 | 地址 |
|----------|------|
| Ingress | http://kuboard.local |
| NodePort | http://`<节点IP>`:30083 |

- **默认账号**: admin
- **默认密码**: Kuboard123
- **用途**: Kubernetes 可视化管理、Workload 管理、存储管理、权限管理等

##### 首次使用配置

**第一步：导入集群**

1. 打开浏览器访问 Kuboard
2. 使用默认账号密码登录
3. 点击「添加集群」或「导入集群」
4. 选择「直接连接」方式
5. 获取集群信息：
   ```bash
   cat ~/.kube/config
   ```
6. 按照提示完成集群导入

**第二步：配置命名空间权限**

1. 进入「集群管理」->「权限管理」
2. 创建或编辑命名空间角色
3. 将 `admin` 用户绑定到对应命名空间

**第三步：开始使用**

导入集群后，可以：

- **工作负载管理**: 部署、扩缩容、更新应用
- **存储管理**: 查看 PVC、StorageClass
- **配置管理**: 管理 ConfigMap、Secret
- **网络管理**: 查看 Service、Ingress、Endpoints
- **日志查看**: 查看 Pod 日志
- **终端访问**: 进入 Pod 容器内部
- **健康检查**: 查看节点、Pod 状态

##### 常用操作

**查看节点列表**
```
集群管理 -> 节点管理
```

**部署应用**
```
集群管理 -> 工作负载 -> 创建 -> 编辑 YAML 或 表单
```

**查看 Pod 日志**
```
集群管理 -> 工作负载 -> 选择命名空间 -> 点击 Pod -> 日志
```

**进入容器终端**
```
集群管理 -> 工作负载 -> 选择命名空间 -> 点击 Pod -> 终端
```

**扩缩容**
```
集群管理 -> 工作负载 -> 选择 Deployment -> 扩缩容
```

##### Kuboard 界面功能概览

| 功能模块 | 说明 |
|----------|------|
| 集群概览 | 显示集群整体状态、资源使用率 |
| 工作负载 | Deployment、StatefulSet、DaemonSet、Job、CronJob 管理 |
| 服务发现 | Service、Ingress、Endpoints 管理 |
| 存储管理 | PVC、StorageClass、PV 管理 |
| 配置中心 | ConfigMap、Secret 管理 |
| 权限管理 | 用户、角色、命名空间权限 |
| 主机管理 | 节点信息、标签、污点管理（部分版本） |
| 日志审计 | 查看操作日志 |

#### 示例应用

- **地址**: http://app.local
- **内容**: Vue3 前端 + Java 后端（需手动启用）
- **前端镜像**: nginx:alpine
- **后端镜像**: eclipse-temurin:17-jre（默认未部署，需配置镜像源）

### NodePort 备选访问

如果无法配置 hosts，可使用 NodePort 方式访问：

```bash
# 部署 NodePort 服务
kubectl apply -f manifests/services/nodeport-services.yaml

# 访问地址（<服务器IP>:<NodePort>）
Jenkins:    http://192.168.0.122:30088
Grafana:    http://192.168.0.122:30090
Prometheus: http://192.168.0.122:30091
ArgoCD:     http://192.168.0.122:30080
Loki:       http://192.168.0.122:30092
```

## 模块说明

### 存储层

- **NFS**: 提供持久化存储，支持 PVC 自动创建
- **StorageClass**: nfs-storage（设为默认存储类）

### 网络层

- **Ingress Nginx**: HTTP/HTTPS 统一入口
- **IngressClass**: nginx
- 所有服务通过 Ingress 暴露，支持域名访问

### 中间件/工具

| 模块 | Namespace | 说明 |
|------|-----------|------|
| NFS Provisioner | nfs-provisioner | NFS 存储动态供给 |
| Ingress Nginx | ingress-nginx | HTTP 入口控制器 |
| Harbor | default (Docker) | 镜像仓库 |
| Jenkins | jenkins | CI/CD |
| ArgoCD | argocd | GitOps |
| Monitoring | monitoring | Prometheus + Grafana |
| Logging | logging | Loki + Promtail |
| Kuboard | kuboard (或 Docker) | K8s 管理界面 |

### 示例应用

| 组件 | Namespace | 副本数 | 端口 |
|------|-----------|--------|------|
| vue-frontend | sample-app | 2 | 80 |
| java-backend | sample-app | 2 | 8080 |

## 常见问题

### 镜像拉取失败（Docker Hub 限流）

```bash
# 配置 Docker 镜像加速
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### ArgoCD 密码忘记了

```bash
# 重置 admin 密码
kubectl -n argocd patch secret argocd-initial-admin-secret \
  -p '{"stringData":{"password":"newpassword123"}}'
```

### NFS 挂载失败

```bash
# 检查 NFS 服务状态
systemctl status nfs-server
showmount -e

# 检查 NFS Pod
kubectl get pods -n nfs-provisioner
kubectl logs -n nfs-provisioner -l app=nfs-provisioner
```

### Ingress 不生效

```bash
# 检查 Ingress Controller
kubectl get pods -n ingress-nginx
kubectl get ingress -A

# 查看 Ingress 事件
kubectl describe ingress <name> -n <namespace>
```

### 查看所有 Pod 状态

```bash
kubectl get pods -A
kubectl get pods -A | grep -v Running
```

### 查看所有 Service

```bash
kubectl get svc -A
```

### Kuboard 无法访问

```bash
# Docker 方式：检查容器状态
docker ps | grep kuboard
docker logs kuboard

# K8s 方式：检查 Pod 状态
kubectl get pods -n kuboard
kubectl logs -n kuboard -l k8s.kuboard.cn/name=kuboard-v3

# 检查 Ingress（K8s 方式）
kubectl get ingress -n kuboard
kubectl describe ingress kuboard-ingress -n kuboard
```

### Kuboard 连接集群失败

```bash
# 检查 Agent 是否运行（Docker 方式）
docker exec kuboard kuboard-agent status

# 重新添加集群
docker exec kuboard kuboard-agent add-cluster

# 检查 kubeconfig 是否正确
cat ~/.kube/config
```

### Kuboard 导入集群后没有权限

```bash
# 检查当前用户的 clusterrolebinding
kubectl get clusterrolebinding -A

# 为 admin 用户创建 cluster-admin 绑定
kubectl create clusterrolebinding kuboard-admin \
  --clusterrole=cluster-admin \
  --user=admin
```
