# Swiggy GitOps EKS — Interview Questions, Answers & Project Walkthrough

Prepare for DevOps/Cloud interviews using this project as your reference.

---

## Table of Contents

- [How to Explain This Project in an Interview](#how-to-explain-this-project-in-an-interview)
  - [30-Second Elevator Pitch](#30-second-elevator-pitch)
  - [2-Minute Detailed Walkthrough](#2-minute-detailed-walkthrough)
  - [Architecture Flow Explanation](#architecture-flow-explanation)
  - [Component-by-Component Breakdown](#component-by-component-breakdown)
  - [Key Numbers to Remember](#key-numbers-to-remember)
  - [What Challenges Did You Face?](#what-challenges-did-you-face)
  - [What Would You Improve?](#what-would-you-improve)
  - [Pro Tips for the Interview](#pro-tips-for-the-interview)
- [Interview Questions & Answers (30 Questions)](#interview-questions--answers)

---

## How to Explain This Project in an Interview

---

### 30-Second Elevator Pitch

> *"I built a production-grade end-to-end DevOps pipeline that deploys a Swiggy food delivery clone — a React 18 application — onto AWS EKS using the GitOps methodology. The entire infrastructure is provisioned with Terraform, CI is handled by Jenkins with integrated security scanning (SonarQube, Trivy, OWASP), Docker images are pushed to ECR, and ArgoCD continuously deploys to Kubernetes by watching the Git repository as the single source of truth. The project also includes Prometheus and Grafana for monitoring, and Kyverno for policy enforcement."*

---

### 2-Minute Detailed Walkthrough

Use this structure when the interviewer says **"Tell me about your project"**:

**1. Start with the WHAT (10 sec):**
> *"This is a complete DevOps project where I deploy a Swiggy food delivery clone app to AWS EKS using GitOps."*

**2. Explain the WHY (15 sec):**
> *"I built it to demonstrate a real-world production pipeline — covering infrastructure automation, CI/CD, container orchestration, monitoring, and security — all the things a DevOps engineer handles day-to-day."*

**3. Walk through the HOW (60 sec):**
> *"The flow starts with Terraform — I wrote reusable modules for VPC, EKS cluster, ECR registry, an EC2 jumphost, and S3 backends. Everything is multi-environment ready with dev, staging, and prod configurations.*
>
> *For CI, I set up Jenkins with a 12-stage declarative pipeline: it checks out the code, runs SonarQube analysis for code quality, OWASP dependency check for CVEs in npm packages, Trivy for filesystem vulnerabilities, builds a Docker image, pushes it to ECR, scans the image again with Trivy, and finally updates the Kubernetes deployment manifest with the new image tag.*
>
> *For CD, I use ArgoCD with the App-of-Apps pattern. ArgoCD watches the gitops directory in my repo and auto-syncs any changes to the EKS cluster. So when Jenkins updates the image tag and pushes to Git, ArgoCD picks it up and deploys automatically — no manual kubectl commands.*
>
> *On top of that, I have Prometheus and Grafana for monitoring with 9 pre-built dashboards, and Kyverno cluster policies that enforce resource limits and restrict image registries."*

**4. Highlight the IMPACT (15 sec):**
> *"The result is a fully automated pipeline — from code commit to production deployment — with zero manual intervention, full observability, and multiple security gates."*

---

### Architecture Flow Explanation

When asked **"Walk me through the architecture"**, explain this flow:

```
Developer → GitHub → Jenkins CI → ECR → Git Update → ArgoCD → EKS
```

**Step-by-step:**

| Step | What Happens |
|------|-------------|
| **1. Code Push** | Developer pushes code to GitHub |
| **2. Jenkins Trigger** | Jenkins CI pipeline is triggered (webhook or poll) |
| **3. Code Quality** | SonarQube scans code for bugs, smells, and vulnerabilities |
| **4. Dependency Scan** | OWASP checks npm packages against the NVD database |
| **5. Filesystem Scan** | Trivy scans the source directory for vulnerabilities |
| **6. Docker Build** | Docker image is built from the Dockerfile |
| **7. Push to ECR** | Image is tagged with build number and pushed to AWS ECR |
| **8. Image Scan** | Trivy scans the built Docker image for OS/library CVEs |
| **9. Git Update** | Jenkins updates `deployment.yaml` with the new image tag and pushes to GitHub |
| **10. ArgoCD Sync** | ArgoCD detects the Git change and auto-deploys to EKS |
| **11. Live** | Application is running with 4 replicas behind a LoadBalancer |
| **12. Monitoring** | Prometheus collects metrics; Grafana displays dashboards |

---

### Component-by-Component Breakdown

Use this when the interviewer asks **"Explain each component"** or **"What tools did you use and why?"**:

#### Infrastructure (Terraform)
> *"I used Terraform with 5 reusable modules — VPC, EKS, ECR, EC2 jumphost, and S3 backend. Each environment (dev, staging, prod) calls the same modules with different variables. Remote state is stored in S3 for team collaboration and durability."*

#### CI Pipeline (Jenkins)
> *"Jenkins runs a 12-stage declarative pipeline. It starts with code checkout, runs three different security scans (SonarQube, OWASP, Trivy), builds and pushes the Docker image to ECR, and updates the GitOps manifest. I have a separate infrastructure pipeline for Terraform apply/destroy with parameterized builds."*

#### CD / GitOps (ArgoCD)
> *"ArgoCD follows the App-of-Apps pattern — one root application recursively watches the `gitops/apps/` directory and manages all child apps. It has auto-sync with self-heal and prune enabled, meaning the cluster always matches the Git state. If someone manually edits the cluster, ArgoCD reverts it."*

#### Container Orchestration (EKS)
> *"The app runs on AWS EKS with managed node groups. The deployment has 4 replicas for high availability, a LoadBalancer service for external access, and Nginx ingress for URL routing. I also deployed MariaDB and PostgreSQL as database layers."*

#### Monitoring (Prometheus + Grafana)
> *"I deployed the kube-prometheus-stack via Helm through ArgoCD. Prometheus scrapes cluster and application metrics. Grafana has 9 pre-configured dashboards — covering node health, cluster overview, pod metrics, and ingress performance — with auto-provisioned datasources."*

#### Security (Trivy + Kyverno + SonarQube + OWASP)
> *"Security is layered: SonarQube for code quality, OWASP for dependency CVEs, Trivy for filesystem and image scanning. At the cluster level, Kyverno enforces policies — requiring resource limits on every pod and restricting images to only our approved ECR registry."*

---

### Key Numbers to Remember

Interviewers love specifics. Memorize these:

| Metric | Value |
|--------|-------|
| Replicas | 4 |
| CI Pipeline Stages | 12 (app) + 6 (infra) |
| Terraform Modules | 5 |
| Environments | 3 (dev, staging, prod) |
| Grafana Dashboards | 9 |
| Security Scans | 4 (SonarQube, OWASP, Trivy FS, Trivy Image) |
| Kyverno Policies | 2 (resource limits, registry restriction) |
| Databases | 2 (MariaDB, PostgreSQL) |
| App Port | 3000 |
| Tools on EC2 Jumphost | 20+ |

---

### What Challenges Did You Face?

Be ready for **"What challenges did you encounter?"** — interviewers always ask this:

**1. Jenkins-ArgoCD Integration:**
> *"The biggest challenge was automating the image tag update. After Jenkins pushes to ECR, it needs to update the deployment manifest in Git so ArgoCD picks it up. I solved this by having Jenkins run sed to replace the image tag and push the commit back to GitHub using stored credentials."*

**2. EKS Networking:**
> *"Configuring the VPC with proper public and private subnets, NAT gateways, and security groups for EKS was complex. The worker nodes need private subnet access to ECR and the API server. I solved this by carefully designing the Terraform VPC module with proper route tables and subnet tagging."*

**3. SonarQube Quality Gate Webhook:**
> *"SonarQube's `waitForQualityGate` requires a webhook to call back to Jenkins. Initially it kept timing out because the webhook URL wasn't configured properly in SonarQube. I had to set up the webhook in SonarQube's admin pointing back to Jenkins' sonarqube-webhook endpoint."*

**4. OWASP NVD Rate Limiting:**
> *"The OWASP Dependency-Check downloads the NVD database on every run, and the API has rate limits. Builds would fail when the NVD was unavailable. I handled this by making the scan non-blocking (`|| true`) and checking if the report file exists before publishing."*

**5. Trivy Database Updates:**
> *"The first Trivy scan on a fresh EC2 instance takes longer because it downloads the vulnerability database. I pre-cached the database in the user-data script to avoid pipeline timeouts."*

---

### What Would You Improve?

This shows **self-awareness and growth mindset** — interviewers love this:

| Improvement | Why |
|-------------|-----|
| **Helm Charts** | Replace raw YAML manifests with Helm for templating, versioning, and rollbacks |
| **HPA (Horizontal Pod Autoscaler)** | Dynamic scaling instead of fixed 4 replicas |
| **Multi-stage Docker build** | Use Nginx to serve static React build (smaller image, faster, more secure) |
| **Argo Rollouts** | Blue-green or canary deployments for zero-downtime releases |
| **Vault/Secrets Manager** | Externalize secrets instead of Jenkins credentials |
| **GitHub Actions** | Replace Jenkins for tighter Git integration and less maintenance |
| **Terragrunt** | DRY environment configurations instead of duplicated `main.tf` files |
| **E2E Tests** | Add Cypress/Playwright tests in the pipeline before deployment |
| **Spot Instances** | Use EKS Spot node groups for cost optimization |
| **Service Mesh (Istio)** | mTLS, traffic management, and advanced observability |

---

### Pro Tips for the Interview

1. **Draw the architecture** — grab a whiteboard/screen share and sketch the flow while explaining. This demonstrates deep understanding.
2. **Use numbers** — say "12-stage pipeline" not "multi-stage pipeline"; say "5 Terraform modules" not "several modules."
3. **Explain trade-offs** — *"I chose Jenkins over GitHub Actions because the EC2 jumphost already runs Jenkins, but in a greenfield project I'd pick GitHub Actions for lower maintenance."*
4. **Show awareness of production gaps** — *"In a real prod setup, I would add Helm, HPA, Vault for secrets, and Argo Rollouts for canary deployments."*
5. **Talk about the WHY, not just WHAT** — don't just list tools; explain why you chose each one.
6. **Be ready for deep dives** — the interviewer will pick one area (e.g., Terraform, ArgoCD, Jenkins) and go deep. Know each tool well.
7. **Practice the 2-minute walkthrough** — rehearse until it sounds natural, not memorized.

---
---

## Interview Questions & Answers

---

## GitOps & ArgoCD

### 1. What is GitOps and why did you use it in this project?

**Answer:** GitOps is a deployment methodology where Git is the single source of truth for declarative infrastructure and application configuration. I used it because it provides version-controlled deployments, easy rollbacks (just revert a commit), audit trails for every change, and self-healing — ArgoCD continuously reconciles the cluster state with what's defined in Git. If someone manually modifies the cluster, ArgoCD automatically reverts it.

---

### 2. Explain the App-of-Apps pattern you implemented in ArgoCD.

**Answer:** The App-of-Apps pattern uses a single root ArgoCD Application (`root-app.yaml`) that recursively watches the `gitops/apps/` directory. This root app automatically discovers and manages all child applications — swiggy deployment, Prometheus, Grafana, MariaDB, and PostgreSQL. Adding a new service is as simple as dropping a YAML file into the `gitops/apps/` directory; ArgoCD picks it up automatically. This eliminates the need to manually register each application in ArgoCD.

---

### 3. What happens if ArgoCD goes down? Will the running application be affected?

**Answer:** No. The running workloads on EKS are unaffected because Kubernetes continues to manage them independently. We only lose the auto-sync and self-healing capability temporarily. Once ArgoCD recovers, it reconciles and catches up with any pending changes in the Git repository.

---

### 4. What is the difference between ArgoCD's `selfHeal` and `prune` sync policies?

**Answer:** `selfHeal: true` means ArgoCD will automatically revert any manual changes made directly to the cluster (drift detection). `prune: true` means ArgoCD will delete resources from the cluster that no longer exist in the Git repository. Together, they ensure the cluster always matches the Git state exactly.

---

### 5. How does the new Docker image tag reach ArgoCD after a Jenkins build?

**Answer:** After Jenkins builds and pushes the Docker image to ECR, it runs a `sed` command to update the image tag in `gitops/apps/swiggy/deployment.yaml` and pushes that change back to GitHub. ArgoCD watches this repository and detects the manifest change, then automatically syncs the new deployment to EKS.

---

## CI/CD & Jenkins

### 6. Walk me through the stages in your application CI pipeline.

**Answer:** The pipeline has 12 stages:
1. **Workspace Cleanup** — clean previous build artifacts
2. **Git Checkout** — clone the repo
3. **List Files** — verify checkout
4. **SonarQube Analysis** — static code analysis
5. **Quality Gate** — wait for SonarQube quality gate result
6. **Install Dependencies** — `npm install`
7. **OWASP Dependency-Check** — scan for known CVEs in dependencies
8. **Trivy Filesystem Scan** — scan source files for vulnerabilities
9. **Docker Image Build** — build the container image
10. **Push to ECR** — push image to AWS Elastic Container Registry
11. **Trivy Image Scan** — scan the built image for vulnerabilities
12. **Update Deployment Tag** — update the image tag in the GitOps manifest and push to Git

---

### 7. Why do you have two separate Jenkins pipelines (app and infra)?

**Answer:** Separation of concerns. The **app pipeline** (`Jenkinsfile.app`) handles application-level tasks — code analysis, building, scanning, and deploying the Docker image. The **infra pipeline** (`Jenkinsfile.infra`) handles Terraform operations — provisioning and destroying cloud infrastructure. They have different triggers, different frequencies, and different risk profiles. Infrastructure changes are less frequent and more impactful, so they deserve a separate, controlled pipeline.

---

### 8. How does the infrastructure pipeline support both provisioning and teardown?

**Answer:** The `Jenkinsfile.infra` uses a Jenkins parameterized build with a `choice` parameter (`apply` or `destroy`). Based on the selection, it conditionally runs either `terraform apply -auto-approve` or `terraform destroy -auto-approve` using a `when` expression block. This allows the same pipeline to manage the full lifecycle.

---

### 9. How did you handle the SonarQube Quality Gate in Jenkins?

**Answer:** I used `waitForQualityGate` step which waits for SonarQube to process the analysis and return a pass/fail result via a webhook. I configured it with `abortPipeline: false` so that a quality gate failure doesn't block the pipeline but is logged as a warning. In a stricter environment, you'd set it to `true`.

---

### 10. What is OWASP Dependency-Check and why did you include it?

**Answer:** OWASP Dependency-Check scans project dependencies (npm packages in this case) against the National Vulnerability Database (NVD) to identify known CVEs. I included it as a security layer to catch vulnerable third-party libraries before they reach production. It generates both HTML and XML reports, and I configured it as non-blocking (`|| true`) so NVD availability issues don't break the build.

---

## Terraform & Infrastructure

### 11. Explain your Terraform module structure and why you designed it this way.

**Answer:** I created 5 reusable modules: `vpc`, `eks`, `ecr`, `ec2-jumphost`, and `s3-backend`. Each module is self-contained with its own `main.tf`, `variables.tf`, and `outputs.tf`. The `environments/` directory (dev, staging, prod) consumes these modules with environment-specific parameters. This design follows DRY principles — write the module once, reuse across environments with different configurations.

---

### 12. How do you manage Terraform state in this project?

**Answer:** Terraform state is stored remotely in AWS S3 buckets. Each module has a `backend.tf` that configures the S3 backend with a unique key. Remote state ensures team collaboration (no local state conflicts), state locking (prevents concurrent modifications), and durability (S3's 99.999999999% durability). The S3 buckets themselves are provisioned by the `s3-backend` module.

---

### 13. How do you handle multi-environment deployments with Terraform?

**Answer:** Each environment (`dev/`, `staging/`, `prod/`) has its own `main.tf` that references the shared modules with environment-specific variable values — different instance sizes, cluster node counts, VPC CIDRs, etc. This allows each environment to have its own isolated infrastructure and state file while sharing the same proven module code.

---

### 14. What IAM resources did you create for the EC2 jumphost and why?

**Answer:** I created an IAM Role, IAM Policy, and Instance Profile for the EC2 jumphost. The role grants the EC2 instance permissions to interact with EKS (`eks:*`), ECR (`ecr:*`), and S3 (`s3:*`) — necessary for running Terraform, pushing Docker images, and managing the Kubernetes cluster. The instance profile attaches the role to the EC2 instance, following AWS best practices of using roles instead of hardcoded access keys.

---

### 15. What does the EC2 jumphost's user-data script install?

**Answer:** The `install-tools.sh` script installs 20+ DevOps tools including: Jenkins, Docker, Terraform, kubectl, AWS CLI, Helm, Trivy, SonarQube (as a Docker container), ArgoCD CLI, Node.js, and more. This creates a fully self-contained DevOps workstation that acts as both the CI server (Jenkins) and a management node for the EKS cluster.

---

## Kubernetes & EKS

### 16. Describe the Kubernetes resources you deployed for the Swiggy application.

**Answer:** Three main resources:
- **Deployment** — runs 4 replicas of the React app container (port 3000) from the ECR image, with `imagePullPolicy: Always` and a 300-second termination grace period
- **Service** — LoadBalancer type to expose the application externally
- **Ingress** — Nginx ingress rules for URL-based routing

---

### 17. Why did you choose 4 replicas for the deployment?

**Answer:** 4 replicas provide high availability and load distribution. If one pod fails, three others handle traffic while Kubernetes restarts the failed pod. In a real environment, I'd use a Horizontal Pod Autoscaler (HPA) to dynamically scale based on CPU/memory utilization rather than a fixed count.

---

### 18. What is the `terminationGracePeriodSeconds: 300` in your deployment and why is it set to 300?

**Answer:** It gives the pod 300 seconds (5 minutes) to gracefully shut down before Kubernetes forcefully kills it. During this period, the pod stops receiving new traffic, completes in-flight requests, and runs any cleanup hooks. The default is 30 seconds, but for a web application with potentially long-running requests, a longer grace period prevents abrupt disconnections.

---

### 19. How would you implement a rolling update strategy for this deployment?

**Answer:** I would add a `strategy` block to the deployment:
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```
This ensures at least 4 pods are always running during updates (zero downtime). Kubernetes creates a new pod with the updated image, waits for it to be ready, then terminates an old one, repeating until all pods are updated.

---

### 20. What is the difference between EKS managed node groups and self-managed nodes?

**Answer:** Managed node groups are provisioned and lifecycle-managed by AWS — automated AMI updates, draining, and replacement. Self-managed nodes require you to handle EC2 instances, scaling, and updates yourself. I used managed node groups for reduced operational overhead, automatic patching, and seamless integration with EKS.

---

## Monitoring & Observability

### 21. How is monitoring set up in this project?

**Answer:** I deployed Prometheus and Grafana using the kube-prometheus-stack Helm chart via ArgoCD. Prometheus scrapes metrics from the Kubernetes API, node exporter, and application endpoints. Grafana consumes Prometheus as a datasource (auto-provisioned via `datasources.yaml`) and displays 9 pre-configured dashboards covering node-level, cluster-level, and pod-level metrics.

---

### 22. Name some of the Grafana dashboards you configured and what they monitor.

**Answer:**
- **Dashboard 315** — Kubernetes cluster overview (nodes, pods, resource usage)
- **Dashboard 1621** — Node Exporter (CPU, memory, disk, network per node)
- **Dashboard 6417** — Kubernetes cluster (namespace-level view)
- **Dashboard 9614** — NGINX Ingress Controller metrics
- **Dashboard 13602** — Kubernetes pod-level detailed metrics
- **Dashboard 15758** — Kubernetes workloads overview

These cover infrastructure health, application performance, and networking.

---

### 23. How would you set up alerting for this project?

**Answer:** I would configure Prometheus AlertManager with alerting rules — for example, alerts when pod restart count exceeds threshold, node CPU > 80%, or pod CrashLoopBackOff. AlertManager would route notifications to Slack, PagerDuty, or email. I'd also add Grafana alerting for dashboard-based threshold alerts.

---

## Security

### 24. Explain the three layers of security scanning in your pipeline.

**Answer:**
1. **SonarQube** — static code analysis for bugs, code smells, vulnerabilities, and technical debt in the React source code
2. **OWASP Dependency-Check** — scans npm dependencies against the NVD database for known CVEs
3. **Trivy** — two scans: filesystem scan (source code) and image scan (built Docker image) for OS-level and library-level vulnerabilities

This layered approach catches issues at the code level, dependency level, and container level.

---

### 25. Explain the Kyverno policies you implemented.

**Answer:** I implemented two ClusterPolicies in `Enforce` mode:
1. **require-resource-limits** — every pod must define CPU and memory limits. This prevents runaway containers from starving node resources.
2. **restrict-image-registries** — only images from our approved ECR registry are allowed. This prevents deploying untrusted or unauthorized images.

`Enforce` mode means non-compliant resources are **rejected** at admission time, not just warned about.

---

### 26. What is the difference between Trivy filesystem scan and image scan?

**Answer:** Filesystem scan (`trivy fs .`) scans the source code directory for vulnerabilities in application dependencies and misconfigurations. Image scan (`trivy image <image>`) scans the built Docker image, including the OS packages in the base image (node:16-slim), application libraries, and any binaries. The image scan catches vulnerabilities introduced by the base image that aren't visible in the source code.

---

## Docker & Container

### 27. Explain your Dockerfile and the base image choice.

**Answer:** The Dockerfile uses `node:16-slim` as the base image — slim variant to minimize image size and reduce the attack surface (fewer OS packages = fewer vulnerabilities). It copies `package.json`, runs `npm install`, copies the source code, exposes port 3000, and starts the React development server. In production, I would use a multi-stage build with an Nginx base image to serve the static build output.

---

### 28. How do you push Docker images to ECR in the pipeline?

**Answer:** Three steps:
1. Authenticate with ECR: `aws ecr get-login-password | docker login --username AWS --password-stdin <ECR_URL>`
2. Tag the image: `docker tag swiggy:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/swiggy:<BUILD_NUMBER>`
3. Push: `docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/swiggy:<BUILD_NUMBER>`

The ECR repository also has scan-on-push enabled for an additional layer of vulnerability scanning.

---

## AWS & Networking

### 29. What AWS services does this project use and what is each one's role?

**Answer:**
| Service | Role |
|---------|------|
| **VPC** | Isolated network with public/private subnets |
| **EKS** | Managed Kubernetes cluster running the application |
| **ECR** | Private Docker registry storing container images |
| **EC2** | Jumphost running Jenkins, SonarQube, and DevOps tools |
| **S3** | Remote Terraform state storage |
| **IAM** | Roles, policies, and instance profiles for secure access |
| **Route 53** | (Optional) DNS management for custom domain |

---

### 30. If you had to improve this project, what would you change?

**Answer:**
1. **Helm Charts** — replace raw Kubernetes manifests with Helm for templating and versioning
2. **Horizontal Pod Autoscaler** — dynamic scaling based on CPU/memory instead of fixed 4 replicas
3. **Multi-stage Docker build** — use Nginx to serve static React build for production
4. **Terraform Cloud/Terragrunt** — better state management and DRY environment configs
5. **GitHub Actions** — replace Jenkins for tighter Git integration and lower maintenance
6. **Blue-Green or Canary deployments** — using Argo Rollouts for zero-downtime deployments
7. **Secrets management** — integrate AWS Secrets Manager or HashiCorp Vault
8. **Integration/E2E tests** — add Cypress or Playwright tests in the pipeline
9. **Cost optimization** — use Spot instances for EKS node groups
10. **Service Mesh** — add Istio for mTLS, traffic management, and observability

---

## Bonus: Quick One-Liner Answers

| Question | Answer |
|----------|--------|
| What port does the app run on? | 3000 |
| How many replicas? | 4 |
| Which Kubernetes version? | EKS managed (AWS latest supported) |
| Which React version? | React 18 |
| Which Node.js version? | 16 (node:16-slim) |
| How many Terraform modules? | 5 (VPC, EKS, ECR, EC2, S3) |
| How many environments? | 3 (dev, staging, prod) |
| How many Grafana dashboards? | 9 pre-configured |
| How many Jenkins pipeline stages? | 12 (app) + 6 (infra) |
| Which policy engine? | Kyverno |
