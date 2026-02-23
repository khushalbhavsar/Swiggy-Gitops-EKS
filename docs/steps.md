# Swiggy GitOps Project — Step-by-Step Deployment Guide

Complete walkthrough to deploy the Swiggy clone on AWS EKS using GitOps, ArgoCD, Jenkins, and Terraform.

---

## Table of Contents

1. [Prerequisites](#step-1-prerequisites)
2. [Clone the Repository](#step-2-clone-the-repository)
3. [Configure AWS Credentials](#step-3-configure-aws-credentials)
4. [Create S3 Buckets for Terraform State](#step-4-create-s3-buckets-for-terraform-state)
5. [Provision VPC & EC2 Jumphost](#step-5-provision-vpc--ec2-jumphost)
6. [Connect to EC2 & Verify Tools](#step-6-connect-to-ec2--verify-tools)
7. [Jenkins Initial Setup](#step-7-jenkins-initial-setup)
8. [Install Required Jenkins Plugins](#step-8-install-required-jenkins-plugins)
9. [SonarQube Setup & Jenkins Integration](#step-9-sonarqube-setup--jenkins-integration)
10. [Configure Jenkins Global Tools](#step-10-configure-jenkins-global-tools)
11. [Jenkins Email Notification Setup](#step-11-jenkins-email-notification-setup)
12. [Create EKS Cluster via Jenkins Pipeline](#step-12-create-eks-cluster-via-jenkins-pipeline)
13. [Create ECR Repository via Jenkins Pipeline](#step-13-create-ecr-repository-via-jenkins-pipeline)
14. [Build & Push Docker Image to ECR](#step-14-build--push-docker-image-to-ecr)
15. [Install & Configure ArgoCD](#step-15-install--configure-argocd)
16. [Deploy Application with ArgoCD](#step-16-deploy-application-with-argocd)
17. [Install Prometheus & Grafana Monitoring](#step-17-install-prometheus--grafana-monitoring)
18. [Configure Route 53 DNS (Optional)](#step-18-configure-route-53-dns-optional)
19. [Verify SonarQube Metrics](#step-19-verify-sonarqube-metrics)
20. [Cleanup / Tear Down](#step-20-cleanup--tear-down)

---

## Step 1: Prerequisites

Ensure you have the following before starting:

| Requirement           | Details                                                    |
|-----------------------|------------------------------------------------------------|
| AWS Account           | With IAM permissions for EC2, EKS, ECR, S3, VPC, Route 53 |
| AWS CLI               | v2 installed and configured                                |
| Terraform             | >= 1.6.3                                                   |
| Git                   | Installed locally                                          |
| SSH Key Pair          | Created in your target AWS region (e.g., `us-east-1`)     |
| Domain (optional)     | For Route 53 DNS setup                                     |

---

## Step 2: Clone the Repository

```bash
git clone https://github.com/<your-username>/swiggy-gitops.git
cd swiggy-gitops
```

**Project structure overview:**

```
swiggy-gitops/
├── app/swiggy-react/          # React application source
├── infrastructure/            # Terraform modules & environments
│   ├── environments/          # dev / staging / prod
│   └── modules/               # vpc, eks, ecr, ec2-jumphost, s3-backend
├── gitops/                    # ArgoCD watches this directory
│   ├── apps/                  # K8s manifests (swiggy, monitoring, databases)
│   └── argocd/                # App-of-apps root & project config
├── ci/                        # Jenkins pipelines & scripts
├── monitoring/                # Grafana dashboards & datasources
├── security/                  # Trivy config & Kyverno policies
└── docs/                      # Documentation
```

---

## Step 3: Configure AWS Credentials

```bash
aws configure
```

Enter when prompted:

| Field             | Value                      |
|-------------------|----------------------------|
| Access Key ID     | `<YOUR_ACCESS_KEY>`        |
| Secret Access Key | `<YOUR_SECRET_KEY>`        |
| Region            | `us-east-1`               |
| Output format     | `json`                     |

Verify:

```bash
aws sts get-caller-identity
```

---

## Step 4: Create S3 Buckets for Terraform State

These buckets store remote Terraform state files for all modules.

```bash
cd infrastructure/modules/s3-backend
terraform init
terraform plan
terraform apply -auto-approve
```

**Expected output:**

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:
  bucket1_id = "swiggy111"
  bucket2_id = "swiggy222"
```

> **Note:** Update the bucket names in `infrastructure/modules/s3-backend/main.tf` if the defaults are already taken in your AWS account.

---

## Step 5: Provision VPC & EC2 Jumphost

This step creates the VPC (public/private subnets, IGW, route tables, security groups), IAM roles, and the EC2 jumphost with all DevOps tools pre-installed via user-data script.

```bash
cd infrastructure/modules/ec2-jumphost
terraform init
terraform plan
terraform apply -auto-approve
```

**Expected output:**

```
Apply complete! Resources: 24 added, 0 changed, 0 destroyed.

Outputs:
  jumphost_public_ip = "xx.xx.xx.xx"
  region             = "us-east-1"
```

Verify all resources tracked in state:

```bash
terraform state list
```

> **Save the `jumphost_public_ip`** — you'll need it for Jenkins, SonarQube, and SSH access.

---

## Step 6: Connect to EC2 & Verify Tools

### 6.1: SSH into the Jumphost

**Option A — AWS Console:**

1. Go to **AWS Console → EC2 → Instances**
2. Select your jumphost instance → Click **Connect**

**Option B — SSH from terminal:**

```bash
ssh -i <your-key>.pem ec2-user@<jumphost_public_ip>
```

### 6.2: Switch to Root

```bash
sudo -i
```

### 6.3: Verify All Tools Are Installed

The user-data script (`infrastructure/modules/ec2-jumphost/install-tools.sh`) auto-installs everything. Verify:

```bash
git --version                       # Git
java -version                       # Java 17 (Amazon Corretto)
jenkins --version                   # Jenkins
terraform -version                  # Terraform >= 1.6.3
mvn -v                              # Maven
kubectl version --client --short    # kubectl
eksctl version                      # eksctl
helm version --short                # Helm 3
docker --version                    # Docker
docker ps                           # Should show SonarQube container running
trivy --version                     # Trivy
aws --version                       # AWS CLI v2
mysql --version                     # MariaDB
psql --version                      # PostgreSQL
```

> See [tools-verification.md](tools-verification.md) for the full checklist with expected outputs.

---

## Step 7: Jenkins Initial Setup

### 7.1: Get the Admin Password

```bash
cat /var/lib/jenkins/secrets/initialAdminPassword
```

Copy the output password.

### 7.2: Access Jenkins UI

Open in browser:

```
http://<jumphost_public_ip>:8080
```

### 7.3: Complete Setup Wizard

1. Paste the admin password
2. Click **Install suggested plugins**
3. Create your first admin user (fill in username, password, full name, email)
4. Click **Save and Continue → Save and Finish → Start using Jenkins**

---

## Step 8: Install Required Jenkins Plugins

1. Go to **Jenkins Dashboard → Manage Jenkins → Plugins**
2. Click the **Available** tab
3. Search and install all of the following:

**Pipeline & Build:**

- Pipeline: Stage View
- Eclipse Temurin Installer
- Maven Integration
- NodeJS
- Config File Provider

**Docker:**

- Docker
- Docker Commons
- Docker Pipeline
- Docker API
- Docker Build Step

**AWS:**

- Amazon ECR

**Kubernetes:**

- Kubernetes Client API
- Kubernetes
- Kubernetes Credentials
- Kubernetes CLI
- Kubernetes Credentials Provider

**Code Quality & Security:**

- SonarQube Scanner
- OWASP Dependency-Check

**Notifications & Monitoring:**

- Email Extension Template
- Prometheus Metrics

4. Check **"Restart Jenkins when installation is complete and no jobs are running"**

---

## Step 9: SonarQube Setup & Jenkins Integration

### 9.1: Access SonarQube

Open in browser:

```
http://<jumphost_public_ip>:9000
```

Login with default credentials:
- **Username:** `admin`
- **Password:** `admin`

Change the password when prompted.

### 9.2: Generate SonarQube Token

1. Navigate to: **Administration → Security → Users**
2. Click the **Tokens** icon for your user
3. Generate a token:
   - **Token name:** `jenkins-token`
   - **Expires in:** No expiration
4. Click **Generate** and **copy the token immediately** (it won't be shown again)

### 9.3: Add SonarQube Token to Jenkins

1. Go to **Jenkins → Manage Jenkins → Credentials**
2. Click **System → Global credentials (unrestricted) → Add Credentials**
3. Fill in:
   - **Kind:** Secret text
   - **Secret:** _(paste SonarQube token)_
   - **ID:** `sonarqube-token`
   - **Description:** `SonarQube authentication token`
4. Click **Create**

### 9.4: Configure SonarQube Server in Jenkins

1. Go to **Jenkins → Manage Jenkins → System**
2. Scroll to **SonarQube servers** section
3. Click **Add SonarQube**:
   - **Name:** `sonar-server`
   - **Server URL:** `http://<jumphost_public_ip>:9000`
   - **Server Authentication Token:** Select `sonarqube-token`
4. Check **"Environment variables"**
5. Click **Save**

### 9.5: Configure Webhook in SonarQube

This allows SonarQube to notify Jenkins after analysis is complete.

1. Go to **SonarQube → Administration → Configuration → Webhooks**
2. Click **Create**:
   - **Name:** `jenkins`
   - **URL:** `http://<jumphost_public_ip>:8080/sonarqube-webhook/`
3. Click **Create**

---

## Step 10: Configure Jenkins Global Tools

Go to **Jenkins → Manage Jenkins → Tools** and configure each:

### JDK

- **Name:** `jdk`
- Check **Install automatically**
- Installer: **Install from adoptium.net**
- Version: `jdk-17.0.8.1+1`

### SonarQube Scanner

- **Name:** `sonar-scanner`
- Check **Install automatically**
- Version: Latest available

### NodeJS

- **Name:** `nodejs`
- Check **Install automatically**
- Version: Latest LTS

### OWASP Dependency-Check

- **Name:** `DP-check`
- Check **Install automatically**
- Installer: **Install from github.com**
- Version: Latest available

### Docker

- **Name:** `Docker`
- Check **Install automatically**
- Installer: **Download from docker.com**
- Version: Latest

### Maven

- **Name:** `maven`
- Check **Install automatically**

Click **Save**.

---

## Step 11: Jenkins Email Notification Setup

### 11.1: Generate Gmail App Password

1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Ensure **2-Step Verification** is enabled
3. Search for **App Passwords** in Google Account settings
4. Create an app password:
   - **App name:** `jenkins`
   - Click **Generate**
   - **Copy the 16-character password**

### 11.2: Add Gmail Credentials in Jenkins

1. Go to **Jenkins → Manage Jenkins → Credentials**
2. **System → Global credentials → Add Credentials**:
   - **Kind:** Username with password
   - **Username:** `<your-email>@gmail.com`
   - **Password:** _(paste app password)_
   - **ID:** `email`
   - **Description:** `Gmail SMTP credentials`
3. Click **Create**

### 11.3: Configure SMTP Settings

1. Go to **Jenkins → Manage Jenkins → System**

2. **Extended E-mail Notification:**
   - SMTP Server: `smtp.gmail.com`
   - SMTP Port: `465`
   - Credentials: Select `email`
   - Check **Use SSL**
   - Default Content Type: `HTML (text/html)`

3. **E-mail Notification:**
   - SMTP Server: `smtp.gmail.com`
   - Check **Use SMTP Authentication**
   - Username: `<your-email>@gmail.com`
   - Password: _(app password)_
   - Check **Use SSL**
   - SMTP Port: `465`

### 11.4: Set Default Triggers

1. Scroll to **Default Triggers**
2. Enable: **Always**, **Failure**, **Success**
3. Click **Apply → Save**

### 11.5: Test

Send a test email from the E-mail Notification section to verify delivery.

---

## Step 12: Create EKS Cluster via Jenkins Pipeline

### 12.1: Create the Pipeline Job

1. **Jenkins Dashboard → New Item**
2. Name: `eks-terraform`
3. Type: **Pipeline** → Click **OK**
4. Pipeline configuration:
   - **Definition:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** `https://github.com/<your-username>/swiggy-gitops.git`
   - **Branch:** `*/master`
   - **Script Path:** `ci/Jenkinsfile.infra`
5. Click **Apply → Save**

### 12.2: Run the Pipeline

1. Click **Build with Parameters**
2. **ACTION:** `apply`
3. Click **Build**

> This creates the EKS cluster with 3 worker nodes (t2.large, ON_DEMAND).

### 12.3: Verify EKS Cluster

SSH into the jumphost and run:

```bash
aws eks --region us-east-1 update-kubeconfig --name project-eks
kubectl get nodes
```

Expected: 3 nodes in `Ready` state.

---

## Step 13: Create ECR Repository via Jenkins Pipeline

### 13.1: Create the Pipeline Job

1. **Jenkins Dashboard → New Item**
2. Name: `ecr-terraform`
3. Type: **Pipeline** → Click **OK**
4. Pipeline configuration:
   - **Definition:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** `https://github.com/<your-username>/swiggy-gitops.git`
   - **Branch:** `*/master`
   - **Script Path:** `ci/scripts/Jenkinsfile.ecr`
5. Click **Apply → Save**

### 13.2: Run the Pipeline

1. Click **Build with Parameters**
2. **ACTION:** `apply`
3. Click **Build**

### 13.3: Verify ECR Repository

```bash
aws ecr describe-repositories --region us-east-1
```

You should see the `swiggy` ECR repository listed.

---

## Step 14: Build & Push Docker Image to ECR

### 14.1: Add GitHub PAT to Jenkins

1. **Jenkins → Manage Jenkins → Credentials → Global credentials**
2. Click **Add Credentials**:
   - **Kind:** Secret text
   - **Secret:** `<your-github-personal-access-token>`
   - **ID:** `my-git-pattoken`
   - **Description:** `GitHub PAT for Git operations`
3. Click **Create**

> **Generate a PAT** from [GitHub Settings → Developer settings → Personal access tokens](https://github.com/settings/tokens) with `repo` scope.

### 14.2: Update Jenkinsfile Environment Variables

Before running, update the environment block in `ci/Jenkinsfile.app`:

```groovy
environment {
    AWS_ACCOUNT_ID     = '<your-aws-account-id>'
    AWS_ECR_REPO_NAME  = 'swiggy'
    AWS_DEFAULT_REGION = 'us-east-1'
    REPOSITORY_URI     = '<your-account-id>.dkr.ecr.us-east-1.amazonaws.com'
}
```

Also update the Git credentials in the `Update Deployment file` stage:

```groovy
environment {
    GIT_REPO_NAME  = "<your-repo-name>"
    GIT_EMAIL      = "<your-email>"
    GIT_USER_NAME  = "<your-github-username>"
}
```

### 14.3: Create the Pipeline Job

1. **Jenkins Dashboard → New Item**
2. Name: `swiggy`
3. Type: **Pipeline** → Click **OK**
4. Pipeline configuration:
   - **Definition:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** `https://github.com/<your-username>/swiggy-gitops.git`
   - **Branch:** `*/master`
   - **Script Path:** `ci/Jenkinsfile.app`
5. Click **Apply → Save**

### 14.4: Run the Pipeline

Click **Build Now**. The pipeline executes these stages:

| # | Stage                    | Description                                               |
|---|--------------------------|-----------------------------------------------------------|
| 1 | Cleaning Workspace       | Clean previous build artifacts                            |
| 2 | Checkout from Git        | Clone the repository                                      |
| 3 | SonarQube Analysis       | Static code analysis on `app/swiggy-react/`               |
| 4 | Quality Check            | Wait for SonarQube quality gate result                    |
| 5 | Install Dependencies     | Run `npm install` in the React app directory              |
| 6 | OWASP FS Scan            | Dependency vulnerability scan (~45 min first run)         |
| 7 | Trivy File Scan          | Scan filesystem for vulnerabilities                       |
| 8 | Docker Image Build       | Build Docker image from `app/swiggy-react/Dockerfile`     |
| 9 | ECR Image Push           | Tag and push image to AWS ECR with build number           |
| 10| Trivy Image Scan         | Scan the Docker image for CVEs                            |
| 11| Update Deployment File   | Update image tag in `gitops/apps/swiggy/deployment.yaml`  |

> After stage 11, the updated manifest is pushed to Git, which triggers ArgoCD to auto-sync.

---

## Step 15: Install & Configure ArgoCD

SSH into the jumphost EC2 and run:

### 15.1: Install ArgoCD

```bash
kubectl create namespace argocd

kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 15.2: Verify Installation

```bash
kubectl get pods -n argocd
```

Wait until all 7 pods show `Running` status:

```
argocd-application-controller-0          1/1     Running
argocd-applicationset-controller-xxx     1/1     Running
argocd-dex-server-xxx                    1/1     Running
argocd-notifications-controller-xxx      1/1     Running
argocd-redis-xxx                         1/1     Running
argocd-repo-server-xxx                   1/1     Running
argocd-server-xxx                        1/1     Running
```

### 15.3: Expose ArgoCD Server via LoadBalancer

```bash
kubectl edit svc argocd-server -n argocd
```

Find `type: ClusterIP` and change it to `type: LoadBalancer`. Save and exit (`:wq`).

Get the external URL:

```bash
kubectl get svc argocd-server -n argocd
```

Copy the `EXTERNAL-IP` value (e.g., `a1b2c3d4e5f6.elb.amazonaws.com`).

### 15.4: Get ArgoCD Admin Password

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

### 15.5: Login to ArgoCD UI

Open in browser:

```
https://<EXTERNAL-IP>
```

- **Username:** `admin`
- **Password:** _(output from step 15.4)_

---

## Step 16: Deploy Application with ArgoCD

### 16.1: Create the Target Namespace

```bash
kubectl create namespace dev
```

### Option A: Deploy via ArgoCD UI

1. Click **+ NEW APP**
2. Fill in:

| Field            | Value                                                      |
|------------------|------------------------------------------------------------|
| Application Name | `swiggy`                                                   |
| Project Name     | `default`                                                  |
| Sync Policy      | `Automatic`                                                |
| Repository URL   | `https://github.com/<your-username>/swiggy-gitops.git`     |
| Revision         | `HEAD`                                                     |
| Path             | `gitops/apps/swiggy`                                       |
| Cluster URL      | `https://kubernetes.default.svc`                           |
| Namespace        | `dev`                                                      |

3. Click **Create**

### Option B: Deploy via App-of-Apps Pattern (Recommended)

Apply the ArgoCD project and root application from the repo:

```bash
kubectl apply -f gitops/argocd/projects.yaml
kubectl apply -f gitops/argocd/root-app.yaml
```

This automatically deploys all apps defined under `gitops/apps/` (swiggy, monitoring, databases).

### 16.2: Verify Deployment

```bash
kubectl get pods -n dev
kubectl get svc -n dev
```

Copy the `EXTERNAL-IP` from the LoadBalancer service — this is your application URL.

Open in browser:

```
http://<EXTERNAL-IP>
```

---

## Step 17: Install Prometheus & Grafana Monitoring

SSH into the jumphost and run:

### 17.1: Install Prometheus Stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace prometheus
helm install prometheus prometheus-community/kube-prometheus-stack -n prometheus
```

### 17.2: Install EBS CSI Driver

Required for persistent volumes on EKS:

```bash
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

helm upgrade --install aws-ebs-csi-driver \
  --namespace kube-system aws-ebs-csi-driver/aws-ebs-csi-driver
```

### 17.3: Verify Installation

```bash
kubectl get pods -n prometheus
```

All pods should be in `Running` state.

### 17.4: Access Grafana

```bash
kubectl get svc -n prometheus | grep grafana
```

Default Grafana credentials:
- **Username:** `admin`
- **Password:** `prom-operator`

### 17.5: Import Pre-Built Dashboards

The project includes 9 Grafana dashboards in `monitoring/grafana-dashboards/dashboards/`:

| Dashboard File            | Description                     |
|---------------------------|---------------------------------|
| `315_revlatest.json`      | Kubernetes cluster overview     |
| `1621_revlatest.json`     | Node exporter metrics           |
| `3662_revlatest.json`     | Prometheus stats                |
| `6417_revlatest.json`     | Kubernetes pods monitoring      |
| `9614_revlatest.json`     | NGINX ingress controller        |
| `10000_revlatest.json`    | Cluster resource monitoring     |
| `12006_revlatest.json`    | Kubernetes volumes              |
| `13602_revlatest.json`    | Jenkins performance             |
| `15758_revlatest.json`    | Node resource metrics           |

**To import:** Grafana UI → **Dashboards → Import → Upload JSON file**

---

## Step 18: Configure Route 53 DNS (Optional)

### 18.1: Get Load Balancer URL

```bash
kubectl get svc -n dev
```

Copy the `EXTERNAL-IP` of the `swiggy-app` LoadBalancer service.

### 18.2: Create DNS Record in Route 53

1. Open **AWS Console → Route 53 → Hosted zones**
2. Select your hosted zone (e.g., `example.com`)
3. Click **Create record**:
   - **Record name:** `swiggy`
   - **Record type:** `CNAME` (or `A – Alias` for ALB)
   - **Value:** _(paste LoadBalancer DNS)_
   - **TTL:** `300`
4. Click **Create records**

### 18.3: Verify DNS Resolution

```bash
nslookup swiggy.example.com
```

### 18.4: Access Your Application

Open in browser:

```
http://swiggy.example.com
```

> **Optional:** Enable HTTPS using AWS Certificate Manager (ACM) and attach the certificate to your LoadBalancer.

---

## Step 19: Verify SonarQube Metrics

1. Open `http://<jumphost_public_ip>:9000`
2. Login and go to **Projects** tab
3. Click on the **swiggy** project
4. Review the dashboard metrics:
   - **Bugs** — Code reliability issues
   - **Vulnerabilities** — Security issues
   - **Code Smells** — Maintainability issues
   - **Coverage** — Test coverage percentage
   - **Duplications** — Duplicate code blocks
5. Click **Issues** tab to filter by type and severity
6. Click **Code** tab to explore source files with inline annotations

---

## Step 20: Cleanup / Tear Down

To destroy all resources and avoid ongoing AWS charges, run in reverse order:

### 20.1: Delete ArgoCD Applications & Namespaces

```bash
kubectl delete -f gitops/argocd/root-app.yaml
kubectl delete -f gitops/argocd/projects.yaml
kubectl delete namespace argocd
kubectl delete namespace dev
kubectl delete namespace prometheus
```

### 20.2: Destroy ECR Repository

Run the `ecr-terraform` Jenkins pipeline with **ACTION: `destroy`**, or manually:

```bash
cd infrastructure/modules/ecr
terraform destroy -auto-approve
```

### 20.3: Destroy EKS Cluster

Run the `eks-terraform` Jenkins pipeline with **ACTION: `destroy`**, or manually:

```bash
cd infrastructure/modules/eks
terraform destroy -auto-approve
```

### 20.4: Destroy EC2 Jumphost & VPC

```bash
cd infrastructure/modules/ec2-jumphost
terraform destroy -auto-approve
```

### 20.5: Destroy S3 State Buckets

```bash
cd infrastructure/modules/s3-backend
terraform destroy -auto-approve
```

---

## Summary: End-to-End Pipeline Flow

```
1. Terraform provisions AWS infrastructure (S3 → VPC → EC2 → EKS → ECR)
2. Jenkins CI builds React app, scans with SonarQube + Trivy, pushes to ECR
3. Jenkins updates K8s manifest in gitops/apps/swiggy/deployment.yaml
4. ArgoCD detects Git change and auto-deploys to EKS cluster
5. Prometheus + Grafana monitor the cluster and application metrics
```

```
  Developer        GitHub           Jenkins CI          AWS ECR
     │               │                  │                  │
     ├──git push────►│                  │                  │
     │               ├──webhook────────►│                  │
     │               │                  ├──build & scan───►│
     │               │                  │                  │
     │               │◄──update yaml────┤                  │
     │               │                  │                  │
     │            ArgoCD                │                  │
     │               │                  │                  │
     │               ├──sync to EKS────────────────────────►  EKS Cluster
     │               │                                         ├── swiggy-app
     │               │                                         ├── prometheus
     │               │                                         └── grafana
```

---

## References

- [Building a Scalable Swiggy Clone with GitOps & Kubernetes](https://medium.com/@yaswanth.arumulla/building-a-scalable-swiggy-clone-with-gitops-kubernetes-cc060c7e56c1)
- [Kubernetes Monitoring with Prometheus & Grafana](https://medium.com/@yaswanth.arumulla/kubernetes-monitoring-for-everyone-step-by-step-with-prometheus-grafana-b8582f0cf808)
