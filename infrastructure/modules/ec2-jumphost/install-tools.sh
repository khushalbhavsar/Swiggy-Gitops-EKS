#!/bin/bash
set -e

echo "🚀 Starting DevOps Environment Setup..."

# --------------------------------------------------
# Update system
# --------------------------------------------------
sudo dnf update -y

# Essential tools
sudo dnf install -y git wget unzip curl yum-utils

git --version

# --------------------------------------------------
# Install Java 21 (Required for Jenkins)
# --------------------------------------------------
sudo dnf install -y java-21-amazon-corretto
java -version

# --------------------------------------------------
# Install NodeJS (Latest Stable)
# --------------------------------------------------
sudo dnf module enable nodejs:20 -y
sudo dnf install -y nodejs
node -v
npm -v

# --------------------------------------------------
# Install Jenkins
# --------------------------------------------------
sudo wget -O /etc/yum.repos.d/jenkins.repo \
https://pkg.jenkins.io/redhat-stable/jenkins.repo

sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

sudo dnf install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# --------------------------------------------------
# Install Terraform
# --------------------------------------------------
sudo yum-config-manager --add-repo \
https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

sudo dnf install -y terraform
terraform -v

# --------------------------------------------------
# Install Maven & Ansible
# --------------------------------------------------
sudo dnf install -y maven ansible
mvn -v
ansible --version

# --------------------------------------------------
# Install kubectl
# --------------------------------------------------
curl -LO "https://dl.k8s.io/release/$(curl -L -s \
https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# --------------------------------------------------
# Install eksctl
# --------------------------------------------------
curl --silent --location \
"https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" \
| tar xz -C /tmp

sudo mv /tmp/eksctl /usr/local/bin/
eksctl version

# --------------------------------------------------
# Install Helm
# --------------------------------------------------
curl -fsSL -o get_helm.sh \
https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

chmod 700 get_helm.sh
./get_helm.sh
rm -f get_helm.sh
helm version

# --------------------------------------------------
# Install Docker
# --------------------------------------------------
sudo dnf install -y docker
sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker ec2-user
sudo usermod -aG docker jenkins

docker --version

# --------------------------------------------------
# Install Docker Compose
# --------------------------------------------------
sudo curl -L \
"https://github.com/docker/compose/releases/download/v2.24.5/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# --------------------------------------------------
# Run SonarQube (Low-memory safe mode)
# --------------------------------------------------
sudo docker run -d --name sonar \
-p 9000:9000 \
-e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
sonarqube:lts-community

sudo docker ps

# --------------------------------------------------
# Install Trivy
# --------------------------------------------------
sudo rpm -ivh \
https://github.com/aquasecurity/trivy/releases/download/v0.48.3/trivy_0.48.3_Linux-64bit.rpm

trivy --version

# --------------------------------------------------
# Install Vault
# --------------------------------------------------
sudo dnf install -y vault

# --------------------------------------------------
# Install MariaDB
# --------------------------------------------------
sudo dnf install -y mariadb105-server
sudo systemctl enable mariadb
sudo systemctl start mariadb
mysql --version

# --------------------------------------------------
# Install PostgreSQL (Amazon Linux 2023)
# --------------------------------------------------
sudo dnf install -y postgresql15-server postgresql15
sudo postgresql-15-setup initdb

sudo systemctl enable postgresql
sudo systemctl start postgresql
psql --version

# --------------------------------------------------
# Install AWS CLI v2
# --------------------------------------------------
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

aws --version

echo "✅ DevOps Environment Setup Completed Successfully!"