# Swiggy Clone — GitOps CI/CD on AWS EKS

A production-grade DevOps project deploying a **Swiggy food delivery clone** (React 18) to AWS EKS using GitOps with ArgoCD, Jenkins CI/CD, and Terraform IaC.

## Architecture

```
Developer → GitHub → Jenkins CI → ECR → ArgoCD → EKS Cluster
                                                    ├── Prometheus
                                                    └── Grafana
```

See [docs/README.md](docs/README.md) for detailed architecture diagrams.

## Project Structure

```
swiggy-gitops/
├── README.md
├── docs/                              # Architecture diagrams & docs
│
├── app/                               # Application Source
│   └── swiggy-react/
│       ├── Dockerfile
│       ├── package.json
│       ├── public/
│       └── src/
│
├── infrastructure/                    # Terraform (IaC)
│   ├── environments/
│   │   ├── dev/
│   │   ├── staging/
│   │   └── prod/
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       ├── ecr/
│       ├── ec2-jumphost/
│       └── s3-backend/
│
├── gitops/                            # ArgoCD watches THIS
│   ├── apps/
│   │   ├── swiggy/
│   │   │   ├── deployment.yaml
│   │   │   ├── service.yaml
│   │   │   └── ingress.yaml
│   │   ├── monitoring/
│   │   │   ├── prometheus.yaml
│   │   │   └── grafana.yaml
│   │   └── databases/
│   │       ├── mariadb.yaml
│   │       └── postgres.yaml
│   └── argocd/
│       ├── root-app.yaml              # App-of-apps pattern
│       └── projects.yaml
│
├── ci/                                # CI pipelines
│   ├── Jenkinsfile.app
│   ├── Jenkinsfile.infra
│   └── scripts/
│       ├── install-tools.sh
│       ├── kubernetes.sh
│       └── Jenkinsfile.ecr
│
├── monitoring/
│   └── grafana-dashboards/
│       ├── dashboards/                # 9 pre-built dashboards
│       └── datasources/
│
└── security/
    ├── trivy-config.yaml
    └── policies/
        └── cluster-policies.yaml
```

## Quick Start

### Prerequisites

- AWS Account with appropriate permissions
- Terraform >= 1.6.3
- kubectl, eksctl, Helm 3
- Docker
- Jenkins server

### 1. Provision Infrastructure

```bash
cd infrastructure/environments/dev
terraform init
terraform plan
terraform apply
```

### 2. Deploy EKS Cluster

Run the `Jenkinsfile.infra` pipeline in Jenkins, or manually:

```bash
cd infrastructure/modules/eks
terraform init
terraform plan
terraform apply
```

### 3. Configure ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f gitops/argocd/projects.yaml
kubectl apply -f gitops/argocd/root-app.yaml
```

### 4. CI Pipeline

The Jenkins `Jenkinsfile.app` pipeline will:
1. Checkout code
2. Run SonarQube analysis
3. Install dependencies & scan with OWASP/Trivy
4. Build Docker image & push to ECR
5. Update K8s deployment manifest with new image tag
6. ArgoCD auto-syncs the change to EKS

## Monitoring

Pre-configured Grafana dashboards are available in `monitoring/grafana-dashboards/dashboards/`.

Install Prometheus + Grafana:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus --create-namespace
```

## Tools Verification

See [docs/tools-verification.md](docs/tools-verification.md) for a complete installation checklist.

## References

- [Building a Scalable Swiggy Clone with GitOps & Kubernetes](https://medium.com/@yaswanth.arumulla/building-a-scalable-swiggy-clone-with-gitops-kubernetes-cc060c7e56c1)
- [Kubernetes Monitoring with Prometheus & Grafana](https://medium.com/@yaswanth.arumulla/kubernetes-monitoring-for-everyone-step-by-step-with-prometheus-grafana-b8582f0cf808)
