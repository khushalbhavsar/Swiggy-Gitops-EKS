# Installation Verification Checklist

Verify that all DevOps tools are correctly installed on the EC2 jumphost by running the commands below.

---

## Tool Verification Commands

| Tool | Command | Expected Output |
|------|---------|-----------------|
| **Git** | `git --version` | `git version x.x.x` |
| **Java** | `java -version` | `openjdk version "17..."` |
| **Jenkins** | `systemctl status jenkins` | `active (running)` |
| **Terraform** | `terraform -v` | `Terraform v1.x.x` |
| **Maven** | `mvn -v` | `Apache Maven x.x.x` |
| **kubectl** | `kubectl version --client` | `Client Version: v1.xx.x` |
| **eksctl** | `eksctl version` | `eksctl version: x.x.x` |
| **Helm** | `helm version` | `v3.x.x` |
| **Docker** | `docker --version` | `Docker version xx.xx.xx` |
| **Docker Containers** | `docker ps` | Lists running containers (e.g., `sonarqube`) |
| **Trivy** | `trivy --version` | `Version: 0.48.3` |
| **MariaDB** | `mysql --version` | `mysql Ver x.x Distrib...` |
| **MariaDB Service** | `systemctl status mariadb` | `active (running)` |
| **ArgoCD** | `kubectl get pods -n argocd` | All pods in `Running` or `Completed` status |
| **Prometheus / Grafana** | `kubectl get pods -n prometheus` | All pods in `Running` or `Completed` status |

---

## DevOps Environment Tool Map

```
DevOps-Environment/
├── Source Control
│   └── git
│
├── CI/CD
│   ├── jenkins
│   ├── maven
│   ├── docker
│   │   └── docker-compose
│   └── sonar (via Docker)
│
├── Infrastructure as Code (IaC)
│   ├── terraform
│   ├── awscli
│   ├── eksctl
│   ├── kubectl
│   └── helm
│
├── Kubernetes Tools
│   ├── argocd
│   ├── prometheus
│   ├── grafana
│   └── k9s
│
├── Security & Compliance
│   ├── trivy
│   └── vault (optional)
│
├── Databases
│   ├── mariadb
│   └── postgresql
│
├── Web Servers & Proxies
│   └── nginx (optional)
│
├── Programming Runtimes
│   ├── java-17 (for Jenkins)
│   ├── nodejs & npm (optional)
│   └── python3 & pip
│
├── Configuration Management
│   └── ansible
│
├── Monitoring & System Utilities
│   ├── htop
│   ├── net-tools
│   └── systemctl (for service checks)
│
└── Optional DevOps Tools
    ├── keycloak
    ├── harbor (private registry)
    └── gitlab (code hosting & CI/CD)
```
