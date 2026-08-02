# Production DevOps Architecture (Jenkins + ArgoCD + Terraform + AWS EKS)

This architecture replaces **GitHub Actions** with **Jenkins** while keeping **ArgoCD** for GitOps deployments.

---

# Complete Architecture

```text
                                    CI PIPELINE

                          +----------------------+
Developer                  |      Jenkins CI     |
    |                      |----------------------|
    |                      | Pull Code           |
    ▼                      | Install Dependency  |
 GitHub -----------------> | Unit Test          |
(Code Repository)          | OWASP Scan         |
                            | SonarQube Scan     |
                            | Trivy Scan         |
                            | Docker Build       |
                            | Push Image to ECR  |
                            +----------+---------+
                                       |
                                       |
                                       ▼
                                AWS ECR Repository
                                       |
                                       |
                                       ▼

                            Update Helm values.yaml
                            (Image Tag Version)
                                       |
                                       ▼
                            GitHub (GitOps Repository)
                                       |
                                       ▼

                              +-----------------+
                              |     ArgoCD      |
                              |-----------------|
                              | Watch Git Repo  |
                              | Sync Helm Chart |
                              | Deploy to EKS   |
                              +--------+--------+
                                       |
                -------------------------------------------------
                |                     |                         |
                ▼                     ▼                         ▼
          EKS DEV Cluster      EKS PRE-PROD Cluster      EKS PROD Cluster
                |                     |                         |
      -------------------   -------------------     -------------------
      | Web Service     |   | Web Service     |     | Web Service     |
      | API Service     |   | API Service     |     | API Service     |
      | Auth Service    |   | Auth Service    |     | Auth Service    |
      -------------------   -------------------     -------------------
                |                     |                         |
      -----------------------------------------------------------
                             Shared AWS Services
      -----------------------------------------------------------
      RDS | Redis | S3 | Route53 | ACM | Secrets Manager
                    CloudWatch | IAM | ALB | EFS

                                       |
                                       ▼
                              Prometheus Metrics
                                       |
                                       ▼
                              Grafana Dashboard
                                       |
                                       ▼
                        Email / Slack / PagerDuty Alerts
```

---

# Step-by-Step Flow

## Step 1: Developer

### Work

* Write application code
* Fix bugs
* Add new features

Example

```bash
git add .
git commit -m "Added payment feature"
git push origin main
```

**Output:** Code is pushed to GitHub.

---

# Step 2: GitHub

### Purpose

Stores

* Source Code
* Dockerfile
* Helm Charts
* Kubernetes YAML
* Jenkinsfile

GitHub Webhook triggers Jenkins automatically.

```text
Developer
      │
      ▼
GitHub
      │
Webhook
      ▼
Jenkins
```

---

# Step 3: Jenkins CI Pipeline

Jenkins starts automatically.

Pipeline stages:

```text
Pull Code
      │
      ▼
Install Dependencies
      │
      ▼
Unit Testing
      │
      ▼
OWASP Dependency Check
      │
      ▼
SonarQube Analysis
      │
      ▼
Trivy Scan
      │
      ▼
Docker Build
      │
      ▼
Push Image to AWS ECR
```

---

## Stage 1: Pull Code

```bash
git clone https://github.com/company/ecommerce.git
```

Downloads the latest source code.

---

## Stage 2: Install Dependencies

Example

```bash
npm install
```

or

```bash
mvn clean install
```

Downloads all required libraries.

---

## Stage 3: Unit Testing

Example

```bash
npm test
```

Ensures the application works before deployment.

---

## Stage 4: OWASP Dependency Check

Checks third-party libraries.

Example

```bash
dependency-check.sh --scan .
```

Detects vulnerable dependencies.

---

## Stage 5: SonarQube

Checks

* Bugs
* Security Issues
* Code Smells
* Duplicate Code
* Quality Gate

---

## Stage 6: Trivy

Filesystem Scan

```bash
trivy fs .
```

Docker Image Scan

```bash
trivy image ecommerce:v1
```

Detects vulnerabilities and secrets.

---

## Stage 7: Docker Build

```bash
docker build -t ecommerce:v1 .
```

Creates the Docker image.

---

## Stage 8: Push Image to AWS ECR

```bash
docker push <aws-account-id>.dkr.ecr.ap-south-1.amazonaws.com/ecommerce:v1
```

Stores the Docker image in Amazon ECR.

---

# Step 4: Jenkins CD Pipeline

After the image is pushed, Jenkins updates the Helm chart.

Example

Before

```yaml
image:
  repository: company/ecommerce
  tag: v1
```

After

```yaml
image:
  repository: company/ecommerce
  tag: v2
```

Jenkins commits the updated `values.yaml` to the GitOps repository.

---

# Step 5: GitHub GitOps Repository

Stores deployment files.

```text
helm/

Chart.yaml

values.yaml

deployment.yaml

service.yaml

ingress.yaml
```

Git is the **single source of truth**.

---

# Step 6: ArgoCD

ArgoCD watches the GitOps repository.

```text
GitHub

↓

Image Tag Changed

↓

ArgoCD Detects Change

↓

Sync

↓

Deploy
```

No manual deployment is needed.

---

# Step 7: Terraform

Terraform provisions and manages AWS infrastructure.

Creates:

* VPC
* Public & Private Subnets
* Internet Gateway
* NAT Gateway
* Route Tables
* IAM Roles
* Security Groups
* EKS Cluster
* Node Groups
* ECR
* RDS
* S3
* Route 53
* ACM

Commands

```bash
terraform init
terraform plan
terraform apply
```

---

# Step 8: Amazon EKS

Three environments:

### Development

* Developer testing
* Feature validation

### Pre-Production

* QA testing
* Integration testing
* UAT

### Production

* Live customer traffic

Each cluster runs:

* Web Service
* API Service
* Authentication Service

---

# Step 9: Shared AWS Services

| Service             | Purpose                         |
| ------------------- | ------------------------------- |
| Amazon RDS          | MySQL database                  |
| ElastiCache (Redis) | Cache and sessions              |
| Amazon S3           | Images, artifacts, backups      |
| Route 53            | DNS                             |
| ACM                 | SSL/TLS certificates            |
| Secrets Manager     | Database passwords and API keys |
| CloudWatch          | AWS logs and alarms             |
| IAM                 | Secure access control           |
| ALB                 | External load balancing         |
| EFS                 | Shared persistent storage       |

---

# Step 10: Monitoring

## Prometheus

Collects:

* CPU
* Memory
* Pod status
* Request count
* Network metrics

---

## Grafana

Displays dashboards for:

* CPU usage
* Memory usage
* Pod restarts
* Response time
* Error rate

---

## Alerts

Notifications sent to:

* Email
* Slack
* PagerDuty

---

# Complete End-to-End Flow

```text
1. Developer writes code
            │
            ▼
2. Push code to GitHub
            │
            ▼
3. GitHub Webhook triggers Jenkins
            │
            ▼
4. Jenkins pulls source code
            │
            ▼
5. Install dependencies
            │
            ▼
6. Run unit tests
            │
            ▼
7. OWASP Dependency Check
            │
            ▼
8. SonarQube analysis
            │
            ▼
9. Trivy security scan
            │
            ▼
10. Build Docker image
            │
            ▼
11. Push Docker image to AWS ECR
            │
            ▼
12. Jenkins updates Helm values.yaml (new image tag)
            │
            ▼
13. Commit changes to GitOps repository
            │
            ▼
14. ArgoCD detects Git changes
            │
            ▼
15. ArgoCD syncs Helm chart to Amazon EKS
            │
            ▼
16. Deploy to DEV cluster
            │
            ▼
17. Validate and promote to PRE-PROD
            │
            ▼
18. Validate and promote to PROD
            │
            ▼
19. Users access the application through ALB/Ingress
            │
            ▼
20. Prometheus collects metrics
            │
            ▼
21. Grafana displays dashboards
            │
            ▼
22. Email/Slack/PagerDuty alerts notify the team
```

## Interview Answer (2 Minutes)

> "In our project, developers push code to GitHub, which triggers a Jenkins pipeline through a webhook. Jenkins pulls the code, installs dependencies, runs unit tests, performs OWASP Dependency Check, SonarQube analysis, and Trivy security scanning. If all stages succeed, Jenkins builds a Docker image and pushes it to Amazon ECR. The CD pipeline updates the Docker image tag in the Helm chart's `values.yaml` and commits the change to the GitOps repository. ArgoCD continuously watches this repository and automatically synchronizes the updated Helm manifests to our Amazon EKS clusters. We deploy through Dev, Pre-Production, and Production environments. Terraform provisions the AWS infrastructure such as VPC, EKS, IAM, RDS, and networking. Prometheus collects metrics, Grafana provides monitoring dashboards, and alerts are sent through Email, Slack, or PagerDuty. This architecture provides automated, secure, scalable, and GitOps-driven deployments."
