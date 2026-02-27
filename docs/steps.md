# Step-by-Step Deployment Guide

A complete walkthrough to replicate the Swiggy Clone GitOps project — from code to a fully deployed application on AWS EKS.

---

## Table of Contents

- [Step 1: Clone the GitHub Repository](#step-1-clone-the-github-repository)
- [Step 2: Configure AWS Keys](#step-2-configure-aws-keys)
- [Step 3: Navigate into the Project](#step-3-navigate-into-the-project)
- [Step 4: Create S3 Buckets for Terraform State](#step-4-create-s3-buckets-for-terraform-state)
- [Step 5: Create Network (VPC & EC2)](#step-5-create-network-vpc--ec2)
- [Step 6: Connect to EC2 and Access Jenkins](#step-6-connect-to-ec2-and-access-jenkins)
- [Step 7: Jenkins Setup in Browser](#step-7-jenkins-setup-in-browser)
- [Step 9: Install Required Jenkins Plugins](#step-9-install-required-jenkins-plugins)
- [Step 10: SonarQube Setup](#step-10-sonarqube-setup)
- [Step 11: Jenkins Email Notification Setup](#step-11-jenkins-email-notification-setup-with-gmail)
- [Step 12: Create Jenkins Pipeline — EKS Cluster](#step-12-create-a-jenkins-pipeline-job-create-eks-cluster)
- [Step 13: Create Jenkins Pipeline — ECR](#step-13-create-a-jenkins-pipeline-job-create-ecr)
- [Step 14: Create Jenkins Pipeline — Build & Push Docker Images](#step-14-create-a-jenkins-pipeline-job-for-build-and-push-docker-images-to-ecr)
- [Step 15: Install ArgoCD in Jumphost EC2](#step-15-install-argocd-in-jumphost-ec2)
- [Step 16: Deploy with ArgoCD & Configure Route 53](#step-16-deploying-with-argocd-and-configuring-route-53)
- [Step 17: Configure Route 53 DNS](#step-17-configuring-route-53-dns-for-your-swiggy-clone)
- [SonarQube Project Metrics](#navigate-in-sonarqube-ui-to-see-project-metrics)
- [Prometheus & Grafana Monitoring](#monitoring-with-prometheus--grafana)
- [Configure Alerts (Optional)](#optional-configure-alerts-email-notifications)
- [Final Checklist](#final-checklist)

---

## Step 1: Clone the GitHub Repository

1. Open **VS Code**.
2. Open the terminal in VS Code.
3. Clone the project:

```bash
git clone https://github.com/arumullayaswanth/Swiggy-GitOps-project.git
```

---

## Step 2: Configure AWS Keys

Make sure you have your AWS credentials configured. Run:

```bash
aws configure
```

Enter your:

- **Access Key ID**
- **Secret Access Key**
- **Region** (e.g., `us-east-1`)
- **Output format** (leave it as `json`)

---

## Step 3: Navigate into the Project

```bash
ls
cd Swiggy-GitOps-project
ls
```

---

## Step 4: Create S3 Buckets for Terraform State

These buckets will store `terraform.tfstate` files.

```bash
cd s3-buckets/
ls
terraform init
terraform plan
terraform apply -auto-approve
```

---

## Step 5: Create Network (VPC & EC2)

1. Navigate to Terraform EC2 folder:

   ```bash
   cd ../terraform_main_ec2
   ```

2. Run Terraform:

   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

   **Example output:**

   ```
   Apply complete! Resources: 24 added, 0 changed, 0 destroyed.
   Outputs:
   jumphost_public_ip = "18.208.229.108"
   region = "us-east-1"
   ```

3. List all resources tracked in your current Terraform state file:

   ```bash
   terraform state list
   ```

---

## Step 6: Connect to EC2 and Access Jenkins

1. Go to **AWS Console** → **EC2**.
2. Click your instance → **Connect**.
3. Once connected, switch to root:

   ```bash
   sudo -i
   ```

4. **DevOps Tool Installation Check & Version Report:**

   ```bash
   git --version
   java -version
   jenkins --version
   terraform -version
   mvn -v
   kubectl version --client --short
   eksctl version
   helm version --short
   docker --version
   trivy --version
   docker ps | grep sonar
   kubectl get pods -A | grep grafana
   kubectl get pods -A | grep prometheus
   aws --version
   mysql --version
   ```

5. Get the initial Jenkins admin password:

   ```bash
   cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

   **Example output:** `0c39f23132004d508132ae3e0a7c70e4`

   > Copy that password!

---

## Step 7: Jenkins Setup in Browser

1. Open browser and go to:

   ```
   http://<EC2 Public IP>:8080
   ```

2. Paste the password from the last step.
3. Click **Install suggested plugins**.
4. Create first user:
   - Click through: **Save and Continue** → **Save and Finish** → **Start using Jenkins**

---

## Step 9: Install Required Jenkins Plugins

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Plugins**.
2. Click the **Available** tab.
3. Search and install the following:

   | Plugin | Category |
   |--------|----------|
   | Pipeline: Stage View | Pipeline |
   | Eclipse Temurin Installer | Build Tools |
   | SonarQube Scanner | Code Quality |
   | Maven Integration | Build Tools |
   | NodeJS | Build Tools |
   | Docker | Containerization |
   | Docker Commons | Containerization |
   | Docker Pipeline | Containerization |
   | Docker API | Containerization |
   | Docker-build-step | Containerization |
   | Amazon ECR | Cloud |
   | Kubernetes Client API | Kubernetes |
   | Kubernetes | Kubernetes |
   | Kubernetes Credentials | Kubernetes |
   | Kubernetes CLI | Kubernetes |
   | Kubernetes Credentials Provider | Kubernetes |
   | Config File Provider | Configuration |
   | OWASP Dependency-Check | Security |
   | Email Extension Template | Notifications |
   | Prometheus Metrics | Monitoring |

4. When installation is complete:
   - Check **"Restart Jenkins when installation is complete and no jobs are running"**

---

## Step 10: SonarQube Setup

### 10.0: Access SonarQube

1. Open browser and go to:

   ```
   http://<EC2 Public IP>:9000
   ```

2. Log in with:
   - **Username:** `admin`
   - **Password:** `admin` _(change after first login)_

3. Update your password:
   - **Old Password:** `admin`
   - **New Password:** `yaswanth`
   - **Confirm Password:** `yaswanth`
   - Click **Update**

---

### 10.1: Generate a Token in SonarQube

1. Open the **SonarQube Dashboard** in your browser.
2. Navigate to: **Administration** → **Security** → **Users**.
3. Click the **Tokens** icon button.
4. Click **Generate Token** and fill in:
   - **Token name:** `token`
   - **Expires in:** `No expiration`
5. Click **Generate** and **copy the token**.

   > **Warning:** You will not be able to view this token again — save it securely.

6. This token will be used in Jenkins for authentication with SonarQube.

---

### 10.2: Add SonarQube Token as Jenkins Credential

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Credentials**.
2. Click **System** → **Global credentials (unrestricted)**.
3. Click **Add Credentials**.
4. Fill in:
   - **Kind:** `Secret text`
   - **Secret:** _(paste your SonarQube token)_
   - **ID:** `sonarqube-token`
   - **Description:** `sonarqube-token`
5. Click **Create**.

---

### 10.3: Configure SonarQube Server in Jenkins

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **System**.
2. Scroll down to the **SonarQube servers** section.
3. Click **Add SonarQube** and fill:
   - **Name:** `sonar-server`
   - **Server URL:** `http://localhost:9000` _(or your actual Sonar IP)_
   - **Server Authentication Token:** Select `sonarqube-token` (from credentials)
4. Check **Environment variables injection**.
5. Click **Save**.

---

### 10.4: Configure Webhook in SonarQube

1. Go to **SonarQube Dashboard** → **Administration**.
2. Under **Configuration**, click **Webhooks**.
3. Click **Create**.
4. Fill:
   - **Name:** `jenkins`
   - **Server URL:** `http://localhost:8080/sonarqube-webhook/` _(or your actual Jenkins IP)_
5. Click **Create**.

> This allows SonarQube to notify Jenkins after analysis is complete.

---

### 10.5: Configure Tools in Jenkins

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Tool**.

2. **JDK installations:**
   - Click **Add JDK**
   - **Name:** `jdk`
   - Check **Install automatically**
   - **Add Installer** → Select **Install from adoptium.net**
   - **Version:** `jdk-17.0.8.1+1`

3. **SonarQube Scanner installations:**
   - Click **Add SonarQube Scanner**
   - **Name:** `sonar-scanner`
   - Check **Install automatically**
   - **Version:** `SonarQube Scanner 7.0.1.4817` _(latest version)_

4. **NodeJS installations:**
   - Click **Add NodeJS**
   - **Name:** `nodejs`
   - Check **Install automatically**
   - **Version:** `NodeJS 23.7.0` _(latest version)_

5. **Dependency-Check installations:**
   - Click **Add Dependency-Check**
   - **Name:** `DP-check`
   - Check **Install automatically**
   - **Add Installer** → Select **Install from github.com**
   - **Version:** `dependency-check-12.0.2` _(latest version)_

6. **Docker installations:**
   - Click **Add Docker**
   - **Name:** `Docker`
   - Check **Install automatically**
   - **Add Installer** → Select **Download from docker.com**
   - **Version:** _(latest)_

7. **Maven installations:**
   - Click **Add Maven**
   - **Name:** `maven`
   - Check **Install automatically**

8. Click **Save**.

---

## Step 11: Jenkins Email Notification Setup with Gmail

### 11.1: Enable 2-Step Verification & App Password in Gmail

1. Go to **Gmail**.
2. In the top-right, click **Manage your Google Account**.
3. In the left sidebar, click **Security**.
4. Under **Signing in to Google**, check if **2-Step Verification** is enabled.
   - If not, turn it **ON** and complete the setup.
5. In the top Google search bar, type: **App Passwords**.
6. Generate an app password:
   - **App Name:** `jenkins`
   - Click **Generate**
   - Copy the generated password

---

### 11.2: Add Gmail Credentials in Jenkins

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Credentials**.
2. Click **System** → **Global credentials (unrestricted)**.
3. Click **Add Credentials**.
4. Fill the form:
   - **Kind:** `Username with password`
   - **Username:** `yaswanth.arumulla@gmail.com`
   - **Password:** _(paste the app password)_
   - **ID:** `email`
   - **Description:** `email`
5. Click **Create**.

---

### 11.3: Configure Email Settings in Jenkins

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **System**.

2. Scroll down to **Extended E-mail Notification**:
   - **SMTP Server:** `smtp.gmail.com`
   - **SMTP Port:** `465`
   - Click **Advanced**
   - **Credentials:** Select the `email` credential
   - Check **Use SSL**
   - **Default Content Type:** `HTML (text/html)`

3. Scroll down to **E-mail Notification**:
   - **SMTP Server:** `smtp.gmail.com`
   - Click **Advanced**
   - Check **Use SMTP Authentication**
   - **User Name:** `yaswanth.arumulla@gmail.com`
   - **Password:** _(paste app password)_
   - Check **Use SSL**
   - **SMTP Port:** `465`
   - **Reply-to Address:** `yaswanth.arumulla@gmail.com`
   - **Charset:** `UTF-8`

4. Test configuration:
   - **Test E-mail recipient:** `yaswanth.arumulla@gmail.com`
   - Click **Test Configuration** to verify

---

### 11.4: Set Default Email Triggers in Jenkins

1. Scroll down to **Default Triggers**.
2. Click the dropdown and select:
   - **Always**
   - **Failure**
   - **Success**
3. Click **Apply** then **Save**.

---

### 11.5: Check Gmail

Go to your Gmail inbox and confirm that a test email has arrived from Jenkins.

> You're now ready to receive Jenkins pipeline notifications via Gmail!

---

## Step 12: Create a Jenkins Pipeline Job (Create EKS Cluster)

1. Go to **Jenkins Dashboard**.
2. Click **New Item**.
3. **Name it:** `eks-terraform`
4. Select: **Pipeline** → Click **OK**.
5. **Pipeline configuration:**
   - **Definition:** `Pipeline script from SCM`
   - **SCM:** `Git`
   - **Repository URL:** `https://github.com/arumullayaswanth/Swiggy-GitOps-project.git`
   - **Branches to build:** `*/master`
   - **Script Path:** `eks-terraform/eks-jenkinsfile`
   - Click **Apply** → **Save**
6. Click **Build with Parameters**:
   - **ACTION:** Select `apply`
   - Click **Build**

7. To verify your EKS cluster, connect to your EC2 jumphost server and run:

   ```bash
   aws eks --region us-east-1 update-kubeconfig --name project-eks
   kubectl get nodes
   ```

---

## Step 13: Create a Jenkins Pipeline Job (Create ECR)

1. Go to **Jenkins Dashboard**.
2. Click **New Item**.
3. **Name it:** `ecr-terraform`
4. Select: **Pipeline** → Click **OK**.
5. **Pipeline configuration:**
   - **Definition:** `Pipeline script from SCM`
   - **SCM:** `Git`
   - **Repository URL:** `https://github.com/arumullayaswanth/Swiggy-GitOps-project.git`
   - **Branches to build:** `*/master`
   - **Script Path:** `ecr-terraform/ecr-jenkinfine`
   - Click **Apply** → **Save**
6. Click **Build with Parameters**:
   - **ACTION:** Select `apply`
   - Click **Build**

7. To verify your ECR repository, connect to your EC2 jumphost server and run:

   ```bash
   aws ecr describe-repositories --region us-east-1
   ```

---

## Step 14: Create a Jenkins Pipeline Job for Build and Push Docker Images to ECR

### 14.1: Add GitHub PAT to Jenkins Credentials

1. Navigate to **Jenkins Dashboard** → **Manage Jenkins** → **Credentials** → **(global)** → **Global credentials (unrestricted)**.
2. Click **Add Credentials**.
3. In the form:
   - **Kind:** `Secret text`
   - **Secret:** `ghp_HKMhfhfdTPOKYE2LLxGuytsimxnnl5d1f73zh`
   - **ID:** `my-git-pattoken`
   - **Description:** `git credentials`
4. Click **OK** to save.

---

### 14.2: Jenkins Pipeline Setup — Build, Push & Update Docker Images to ECR

1. Go to **Jenkins Dashboard**.
2. Click **New Item**.
3. **Name it:** `swiggy`
4. Select: **Pipeline** → Click **OK**.
5. **Pipeline configuration:**
   - **Definition:** `Pipeline script from SCM`
   - **SCM:** `Git`
   - **Repository URL:** `https://github.com/arumullayaswanth/Swiggy-GitOps-project.git`
   - **Branches to build:** `*/master`
   - **Script Path:** `jenkinsfiles/swiggy`
   - Click **Apply** → **Save**
6. Click **Build**.

---

## Step 15: Install ArgoCD in Jumphost EC2

### 15.1: Create Namespace for ArgoCD

```bash
kubectl create namespace argocd
```

### 15.2: Install ArgoCD in the Created Namespace

```bash
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 15.3: Verify the Installation

Ensure all pods are in `Running` state:

```bash
kubectl get pods -n argocd
```

### 15.4: Validate the Cluster

Check your nodes and create a test pod if necessary:

```bash
kubectl get nodes
```

### 15.5: List All ArgoCD Resources

```bash
kubectl get all -n argocd
```

**Sample output:**

```
NAME                                                    READY   STATUS    RESTARTS   AGE
pod/argocd-application-controller-0                     1/1     Running   0          106m
pod/argocd-applicationset-controller-787bfd9669-4mxq6   1/1     Running   0          106m
pod/argocd-dex-server-bb76f899c-slg7k                   1/1     Running   0          106m
pod/argocd-notifications-controller-5557f7bb5b-84cjr    1/1     Running   0          106m
pod/argocd-redis-b5d6bf5f5-482qq                        1/1     Running   0          106m
pod/argocd-repo-server-56998dcf9c-c75wk                 1/1     Running   0          106m
pod/argocd-server-5985b6cf6f-zzgx8                      1/1     Running   0          106m
```

### 15.6: Expose ArgoCD Server Using LoadBalancer

1. Edit the ArgoCD server service:

   ```bash
   kubectl edit svc argocd-server -n argocd
   ```

2. Change the service type — find this line:

   ```yaml
   type: ClusterIP
   ```

   Change it to:

   ```yaml
   type: LoadBalancer
   ```

   Save and exit (`:wq` for vi).

3. Get the external Load Balancer DNS:

   ```bash
   kubectl get svc argocd-server -n argocd
   ```

   **Sample output:**

   ```
   NAME            TYPE           CLUSTER-IP     EXTERNAL-IP                           PORT(S)                      AGE
   argocd-server   LoadBalancer   172.20.1.100   a1b2c3d4e5f6.elb.amazonaws.com        80:31234/TCP,443:31356/TCP   2m
   ```

4. Access the ArgoCD UI:

   ```
   https://<EXTERNAL-IP>.amazonaws.com
   ```

### 15.7: Get the Initial ArgoCD Admin Password

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

**Login Details:**

- **Username:** `admin`
- **Password:** _(output of the above command)_

---

## Step 16: Deploying with ArgoCD and Configuring Route 53

### 16.1: Create Namespace in EKS (from Jumphost EC2)

Run these commands on your jumphost EC2 server:

```bash
kubectl create namespace dev
kubectl get namespaces
```

### 16.2: Create New Application with ArgoCD

1. Open the **ArgoCD UI** in your browser.
2. Click **+ NEW APP**.
3. Fill in the following:
   - **Application Name:** `project`
   - **Project Name:** `default`
   - **Sync Policy:** `Automatic`
   - **Repository URL:** `https://github.com/arumullayaswanth/Swiggy-GitOps-project.git`
   - **Revision:** `HEAD`
   - **Path:** `kubernetes-files`
   - **Cluster URL:** `https://kubernetes.default.svc`
   - **Namespace:** `dev`
4. Click **Create**.

> ArgoCD will now automatically sync your manifests to the `dev` namespace.

### 16.3: Copy the Load Balancer URL

Once the application is deployed:

1. Get the services in the `dev` namespace:

   ```bash
   kubectl get svc -n dev
   ```

2. Locate the **EXTERNAL-IP** of the LoadBalancer service.
3. Copy this IP/URL — you'll use it to configure Route 53 for DNS.

---

## Step 17: Configuring Route 53 DNS for Your Swiggy Clone

Follow these steps to point a domain/subdomain to your Load Balancer in EKS.

### 17.1: Log in to AWS Route 53

1. Open the **AWS Management Console**.
2. Navigate to **Route 53** → **Hosted zones**.
3. Select the hosted zone for `aluru.site` (or create a new hosted zone if it doesn't exist).

### 17.2: Create a Record Set

1. Click **Create record**.
2. Fill in the details as needed.
3. Click **Create records**.

### 17.3: Verify DNS Resolution

1. Wait a few minutes for DNS propagation.
2. Test the DNS from your terminal or browser:

   ```bash
   nslookup swiggy.aluru.site
   ```

3. You should see your LoadBalancer's IP or DNS returned.

### 17.4: Access Your Swiggy Clone

Open your browser and navigate to:

```
http://swiggy.aluru.site
```

Your Swiggy clone should load successfully, deployed via ArgoCD with full GitOps CI/CD automation.

> **Optional:** Enable HTTPS for `swiggy.aluru.site` using AWS ACM and attach it to your LoadBalancer to serve secure traffic.

---

## Navigate in SonarQube UI to See Project Metrics

1. **Login to SonarQube:**

   ```
   http://<your-ec2-ip>:9000
   ```

   - **Username:** `admin`
   - **Password:** `admin` _(change after first login)_

2. Go to **Projects** — click on the **Projects** tab in the top menu. You'll see a list of analyzed projects.

3. **Select the Project "Swiggy"** — find and click on the project named **Swiggy**.

4. **View Bugs & Vulnerabilities:**
   - Navigate to the **Issues** tab.
   - Filter issues by:
     - **Type:** Bug
     - **Type:** Vulnerability
   - You can further filter by severity, status, etc.

5. **View Overall Code Summary:**
   - Click on the **Code** tab to explore source files with inline issue annotations.
   - Alternatively, click the **Main Branch** tab to view:
     - Bugs
     - Vulnerabilities
     - Code Smells
     - Duplications
     - Coverage

---

## Monitoring with Prometheus & Grafana

> Monitor your ArgoCD-deployed website (running via LoadBalancer) with Prometheus + Grafana.
> View CPU, RAM, pod status, uptime, errors, etc.

### Prerequisites

Make sure you have these ready:

1. A Kubernetes Cluster (EKS, GKE, Minikube — anything works)
2. `kubectl` is installed and connected to your cluster
3. Helm is installed:

   ```bash
   # Install Helm (if not installed)
   curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
   helm version
   ```

4. Internet access to pull charts & Docker images
5. _(Optional)_ ArgoCD if you want GitOps deployment

### Step 1: Create a Namespace for Monitoring

```bash
kubectl create namespace monitoring
```

### Step 2: Add Prometheus & Grafana Helm Chart Repo

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### Step 3: Install the Kube Prometheus Stack

This installs Prometheus, Grafana, Alertmanager, and Node Exporters:

```bash
helm install kube-prom-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring
```

**This installs:**

| Component | Purpose |
|-----------|---------|
| Prometheus | Metrics collector |
| Grafana | Dashboard visualizer |
| Alertmanager | For warnings/alerts |
| Node Exporters | To get node metrics |

### Step 4: Check That Everything Is Running

```bash
kubectl get pods -n monitoring
```

**Expected output:**

```
NAME                                                     READY   STATUS    RESTARTS   AGE
alertmanager-kube-prom-stack-kube-prome-alertmanager-0   2/2     Running   0          2m45s
kube-prom-stack-grafana-d5dfd9fd-m5j9t                   3/3     Running   0          3m19s
kube-prom-stack-kube-prome-operator-6779bc5685-llmc8     1/1     Running   0          3m19s
kube-prom-stack-kube-state-metrics-6c4dc9d54-w48xj       1/1     Running   0          3m19s
kube-prom-stack-prometheus-node-exporter-vhncz           1/1     Running   0          3m19s
kube-prom-stack-prometheus-node-exporter-vx56f           1/1     Running   0          3m19s
prometheus-kube-prom-stack-kube-prome-prometheus-0       2/2     Running   0          2m45s
```

> Wait until all pods show `STATUS: Running`.

### Step 5: Expose Grafana UI Using LoadBalancer

By default, Grafana is an internal `ClusterIP` service. Expose it:

1. Edit the Grafana service:

   ```bash
   kubectl edit svc kube-prom-stack-grafana -n monitoring
   ```

2. Find this line:

   ```yaml
   type: ClusterIP
   ```

   Change it to:

   ```yaml
   type: LoadBalancer
   ```

   Save and exit (`:wq` for vi).

### Step 6: Get the Grafana LoadBalancer IP

```bash
kubectl get svc kube-prom-stack-grafana -n monitoring
```

**Expected output:**

```
NAME                      TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)        AGE
kube-prom-stack-grafana   LoadBalancer   172.20.174.208   abbda6b6f6c9345c6b017c020cf00122-1809047356.us-east-1.elb.amazonaws.com   80:32242/TCP   5m39s
```

> Copy the **EXTERNAL-IP** (e.g., `http://a1b2c3d4.us-east-1.elb.amazonaws.com`).

### Step 7: Access the Grafana UI

1. Open your browser.
2. Paste the **EXTERNAL-IP** from the previous step.
3. You'll see the **Grafana login page**.

4. Get the initial Grafana admin password:

   ```bash
   kubectl get secret kube-prom-stack-grafana -n monitoring \
     -o jsonpath="{.data.admin-password}" | base64 -d && echo
   ```

   **Example output:** `prom-operator`

5. **Login to Grafana:**
   - **Username:** `admin`
   - **Password:** `prom-operator`
   - Change the password when prompted.

### Step 8: Add Kubernetes Dashboards in Grafana

1. Go to: **Left menu** → **Dashboards** → **+ Import** → **New Dashboard**.
2. In the text box under **"Import via Grafana.com"**, paste the dashboard ID.

**Available Dashboard IDs:**

| Dashboard ID | Description |
|--------------|-------------|
| 315 | Kubernetes Cluster Monitoring |
| 3662 | Kubernetes Pods/Containers |
| 1621 | Kubernetes Deployments |
| 12006 | Kubernetes API Server |
| 6417 | Kubernetes Nodes |
| 10000 | Kubernetes Namespace Monitoring |
| 13602 | Kubernetes Persistent Volumes |
| 15758 | Kubernetes Networking |
| 9614 | NGINX Ingress Controller |

> **Note:** Enter one dashboard ID at a time, click **Load**, import, and repeat for each.

3. **Select Data Source:**
   - On the import screen, choose **Prometheus** from the dropdown (already installed with kube-prometheus-stack).
   - Click **Import**.

4. **View the Dashboard:**
   - After importing, the dashboard will automatically open.
   - You'll see: CPU usage per Node, Memory usage per Pod, Cluster Uptime, Requests, Errors, etc.

### Step 9: See Your ArgoCD App Metrics

All apps running in your cluster (including ones deployed via ArgoCD) are automatically monitored.

1. Go to **Dashboards** → **Import**.
2. Use **Dashboard ID:** `14584` (ArgoCD Official Dashboard).
3. Select **Prometheus** as the data source.

---

## (Optional) Configure Alerts — Email Notifications

> **Goal:** Receive an email alert when CPU usage (or any other metric) exceeds a threshold.

### Step 1: Confirm Alertmanager Is Running

```bash
kubectl get pods -n monitoring
```

Look for:

```
alertmanager-kube-prom-stack-kube-prome-alertmanager-0    2/2    Running
```

### Step 2: Expose Alertmanager via LoadBalancer

1. Edit the Alertmanager service:

   ```bash
   kubectl edit svc kube-prom-stack-kube-prome-alertmanager -n monitoring
   ```

2. Find `type: ClusterIP` and change it to `type: LoadBalancer`. Save and exit.

3. Get the external IP:

   ```bash
   kubectl get svc kube-prom-stack-kube-prome-alertmanager -n monitoring
   ```

4. Access Alertmanager in browser:

   ```
   http://<external-dns>:9093
   ```

> **Note:** If it doesn't load, open port `9093` in the Security Group for the Load Balancer.

**The Alertmanager dashboard provides:**

- **Active Alerts** — alerts currently firing (e.g., high CPU usage)
- **Silences** — suppress certain alerts
- **Status** — cluster and configuration status
- **Receivers** — configured receivers (email, Slack, etc.)
- **Routes** — routing tree for alert notifications

### Step 3: Configure Alertmanager for Email

1. Export the current Alertmanager config:

   ```bash
   kubectl get secret alertmanager-kube-prom-stack-kube-prome-alertmanager \
     -n monitoring -o jsonpath='{.data.alertmanager\.yaml}' | base64 --decode > alertmanager.yaml
   ```

2. Edit the config:

   ```bash
   vim alertmanager.yaml
   ```

3. Add your SMTP email settings:

   ```yaml
   global:
     smtp_smarthost: 'smtp.gmail.com:587'
     smtp_from: 'yaswanth.arumulla@gmail.com'
     smtp_auth_username: 'yaswanth.arumulla@gmail.com'
     smtp_auth_password: 'your-app-password'   # Use app password, not real password!

   route:
     receiver: 'email-alert'

   receivers:
     - name: 'email-alert'
       email_configs:
         - to: 'yaswanth.arumulla@gmail.com'
           send_resolved: true
   ```

   > **For Gmail:** Enable 2-Step Verification and create an App Password from Google account security settings.

4. Apply the updated config:

   ```bash
   kubectl create secret generic alertmanager-kube-prom-stack-kube-prome-alertmanager \
     --from-file=alertmanager.yaml \
     -n monitoring \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

### Step 4: Restart Alertmanager

```bash
kubectl delete pod alertmanager-kube-prom-stack-kube-prome-alertmanager-0 -n monitoring
```

Wait for restart:

```bash
kubectl get pods -n monitoring -w
```

Look for:

```
alertmanager-kube-prom-stack-kube-prome-alertmanager-0   2/2   Running   0   30s
```

### Step 5: Create an Alert Rule (CPU Example)

Create a file called `cpu-alert-rule.yaml`:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: cpu-alert
  namespace: monitoring
spec:
  groups:
    - name: cpu.rules
      rules:
        - alert: HighCPUUsage
          expr: sum(rate(container_cpu_usage_seconds_total[1m])) > 0.7
          for: 2m
          labels:
            severity: warning
          annotations:
            summary: "High CPU Usage detected"
            description: "CPU usage is above 70% for 2 minutes."
```

Apply the rule:

```bash
kubectl apply -f cpu-alert-rule.yaml
```

### Step 6: Test Your Alert

1. Run a CPU-heavy process in a pod (simulate load).
2. Wait 2–3 minutes.
3. Check your email — you should receive an alert!

### Step 7: Verify Alerts in Prometheus

1. Expose Prometheus via LoadBalancer:

   ```bash
   kubectl edit svc kube-prom-stack-kube-prome-prometheus -n monitoring
   ```

   Change `type: ClusterIP` to `type: LoadBalancer`. Save and exit.

2. Get the Prometheus LoadBalancer IP:

   ```bash
   kubectl get svc kube-prom-stack-kube-prome-prometheus -n monitoring
   ```

3. Access Prometheus UI:

   ```
   http://<EXTERNAL-IP>:9090
   ```

---

## Final Checklist

| Item | Status |
|------|--------|
| Prometheus & Grafana Installed | Done |
| Grafana Accessible via LoadBalancer | Done |
| Kubernetes Metrics Visible | Done |
| ArgoCD Deployed App Visible | Done |
| Dashboards Working | Done |
| Optional Alerts Configured | Done |

---

## Bonus: What You Can Monitor

- CPU/RAM of your ArgoCD app
- Pod crashes/restarts
- Node health
- Cluster capacity
- Response times
- Resource usage per container

---

## Conclusion

Monitoring Kubernetes is not just a luxury — it's a necessity in modern cloud-native environments. With Prometheus and Grafana, you can gain real-time insights into your applications, nodes, and infrastructure performance.

- **Prometheus** ensures that metrics are collected and stored efficiently.
- **Grafana** makes those metrics meaningful with beautiful, actionable dashboards.
- **Alertmanager** allows you to proactively respond to issues like high CPU or memory usage before they affect users.
