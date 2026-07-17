// ============================================================================
// APPLICATION CI/CD PIPELINE (Jenkinsfile.app)
// ============================================================================
// This pipeline automates the complete CI/CD workflow for the Swiggy React app:
// 1. Code checkout from GitHub
// 2. Static code analysis with SonarQube
// 3. Dependency installation and security scanning (OWASP, Trivy)
// 4. Docker image build and push to AWS ECR
// 5. Update Kubernetes deployment manifest for GitOps (ArgoCD)
// 6. Email notification with scan reports
// ============================================================================

pipeline {
    // ----------------------------------------------------------------------------
    // AGENT CONFIGURATION
    // ----------------------------------------------------------------------------
    // 'agent any' means this pipeline can run on any available Jenkins agent/node
    agent any 

    // ----------------------------------------------------------------------------
    // TOOLS CONFIGURATION
    // ----------------------------------------------------------------------------
    // Declares the tools required for this pipeline
    // These must be pre-configured in Jenkins Global Tool Configuration
    tools {
        jdk 'jdk'           // Java Development Kit - required for SonarQube scanner
        nodejs 'nodejs'     // Node.js runtime - required for npm install and React build
    }

    // ----------------------------------------------------------------------------
    // ENVIRONMENT VARIABLES
    // ----------------------------------------------------------------------------
    // Global environment variables accessible throughout all pipeline stages
    environment  {
        // SonarQube scanner installation path (configured in Jenkins tools)
        SCANNER_HOME = tool 'sonar-scanner'                 
        // Name of the SonarQube server configured in Jenkins (Manage Jenkins > Configure System)
        SONARQUBE_SERVER  = 'sonar-server'                
        // AWS Account ID - used to construct ECR repository URI
        AWS_ACCOUNT_ID = '843998948464'                  
        // ECR repository name where Docker images will be pushed
        AWS_ECR_REPO_NAME = 'swiggy'                      
        // Jenkins credentials ID for SonarQube authentication token
        SONAR_TOKEN_CRED  = 'sonarqube-token'            
        // AWS region where ECR repository is hosted
        AWS_DEFAULT_REGION = 'us-east-1'
        // Full ECR repository URI constructed from account ID and region
        // Format: <account-id>.dkr.ecr.<region>.amazonaws.com
        REPOSITORY_URI = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com"
    }

    // ============================================================================
    // PIPELINE STAGES
    // ============================================================================
    stages {
        // ------------------------------------------------------------------------
        // STAGE 1: WORKSPACE CLEANUP
        // ------------------------------------------------------------------------
        // Cleans the Jenkins workspace to ensure a fresh start
        // Removes all files from previous builds to prevent conflicts
        stage('Cleaning Workspace') {
            steps {
                cleanWs()   // Jenkins plugin: Workspace Cleanup
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 2: SOURCE CODE CHECKOUT
        // ------------------------------------------------------------------------
        // Clones the source code repository from GitHub
        // Uses the 'main' branch as the source
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/khushalbhavsar/Swiggy-Gitops-EKS.git'
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 3: VERIFY CHECKOUT
        // ------------------------------------------------------------------------
        // Lists all files in the workspace to verify successful checkout
        // Useful for debugging and build verification
        stage("List Files") {
            steps {
                sh 'ls -la' // Verify files after checkout
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 4: SONARQUBE STATIC CODE ANALYSIS
        // ------------------------------------------------------------------------
        // Performs static code analysis using SonarQube to detect:
        // - Code smells, bugs, and vulnerabilities
        // - Code coverage metrics
        // - Technical debt estimation
        // Results are sent to the configured SonarQube server
        stage('Sonarqube Analysis') {
            steps {
                // Navigate to the React application directory
                dir('app/swiggy-react') {
                    // withSonarQubeEnv sets up environment variables for SonarQube
                    withSonarQubeEnv(env.SONARQUBE_SERVER) {
                        sh ''' 
                        ${SCANNER_HOME}/bin/sonar-scanner \
                        -Dsonar.projectName=swiggy \
                        -Dsonar.projectKey=swiggy 
                        '''
                    }
                }
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 5: SONARQUBE QUALITY GATE CHECK
        // ------------------------------------------------------------------------
        // Waits for SonarQube Quality Gate result
        // Quality Gates define pass/fail criteria (e.g., no critical bugs)
        // NOTE: Requires webhook configuration in SonarQube to notify Jenkins
        stage('Quality Check') {
            steps {
                script {
                    // abortPipeline: false - continues build even if quality gate fails
                    // Set to 'true' to fail the build on quality gate failure
                    waitForQualityGate abortPipeline: false, credentialsId: env.SONAR_TOKEN_CRED 
                }
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 6: NPM DEPENDENCY INSTALLATION
        // ------------------------------------------------------------------------
        // Installs Node.js dependencies for the React application
        // Removes existing node_modules to ensure clean installation
        stage('Install Dependencies') {
            steps {
                dir('app/swiggy-react') {
                    sh '''
                    ls -la  # Verify package.json exists
                    if [ -f package.json ]; then
                        rm -rf node_modules package-lock.json  # Remove old dependencies for clean install
                        npm install  # Install all dependencies from package.json
                    else
                        echo "Error: package.json not found!"
                        exit 1  # Fail the build if package.json is missing
                    fi
                    '''
                }
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 7: OWASP DEPENDENCY-CHECK SECURITY SCAN
        // ------------------------------------------------------------------------
        // Scans project dependencies for known security vulnerabilities
        // Uses the National Vulnerability Database (NVD)
        // WARNING: First run downloads NVD data and may take 45+ minutes
        stage('OWASP FS Scan') {
            steps {
                dir('app/swiggy-react') {
                    // Run OWASP Dependency-Check with Node.js audit disabled (already covered)
                    dependencyCheck additionalArguments: '--scan . --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-check'
                    // Publish the XML report to Jenkins for visualization
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 8: TRIVY FILESYSTEM SECURITY SCAN
        // ------------------------------------------------------------------------
        // Trivy scans the filesystem for:
        // - Vulnerabilities in dependencies (npm packages)
        // - Misconfigurations in config files
        // - Secrets accidentally committed to code
        stage('Trivy File Scan') {
            steps {
                dir('app/swiggy-react') {
                    // 'trivy fs .' scans the current directory
                    // Output is saved to trivyfs.txt for email attachment
                    sh 'trivy fs . > trivyfs.txt'
                }
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 9: DOCKER IMAGE BUILD
        // ------------------------------------------------------------------------
        // Builds a Docker image for the React application using the Dockerfile
        // Cleans up unused Docker resources first to save disk space
        stage("Docker Image Build") {
            steps {
                script {
                    dir('app/swiggy-react') {
                        // Remove unused Docker data (networks, dangling images, etc.)
                        sh 'docker system prune -f'
                        // Remove all stopped containers
                        sh 'docker container prune -f'
                        // Build Docker image with the ECR repo name as tag
                        // Uses Dockerfile in current directory (app/swiggy-react)
                        sh 'docker build -t ${AWS_ECR_REPO_NAME} .'
                    }
                }
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 10: PUSH IMAGE TO AWS ECR
        // ------------------------------------------------------------------------
        // Authenticates with AWS ECR and pushes the Docker image
        // Images are tagged with Jenkins BUILD_NUMBER for versioning
        stage("ECR Image Pushing") {
            steps {
                script {
                    // Step 1: Get ECR login password and authenticate Docker client
                    // This uses AWS CLI credentials configured on the Jenkins server
                    sh 'aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}'
                    
                    // Step 2: Tag the local image with full ECR URI and build number
                    // Example: 843998948464.dkr.ecr.us-east-1.amazonaws.com/swiggy:42
                    sh 'docker tag ${AWS_ECR_REPO_NAME}:latest ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                    
                    // Step 3: Push the tagged image to ECR
                    sh 'docker push ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                }
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 11: TRIVY CONTAINER IMAGE SCAN
        // ------------------------------------------------------------------------
        // Scans the pushed Docker image for vulnerabilities
        // This is the final security gate before deployment
        stage("TRIVY Image Scan") {
            steps {
                // Scan the ECR image directly (Trivy supports remote registries)
                // Output saved to trivyimage.txt for email attachment
                sh 'trivy image ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER} > trivyimage.txt'
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 12: RE-CHECKOUT CODE FOR GITOPS UPDATE
        // ------------------------------------------------------------------------
        // Fresh checkout needed because previous stages may have modified files
        // This ensures we have a clean copy for the GitOps update
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/khushalbhavsar/Swiggy-Gitops-EKS.git'
            }
        }

        // ------------------------------------------------------------------------
        // STAGE 13: UPDATE KUBERNETES DEPLOYMENT MANIFEST (GitOps)
        // ------------------------------------------------------------------------
        // This is the GitOps stage - updates the deployment.yaml with new image tag
        // ArgoCD watches this file and automatically deploys changes to Kubernetes
        // This completes the CI/CD loop: Code -> Image -> Update Manifest -> Deploy
        stage('Update Deployment file') {
            environment {
                GIT_REPO_NAME = "Swiggy-Gitops-EKS"          // GitHub repository name
                GIT_EMAIL = "khushalbhavsar41@gmail.com"     // Git commit author email
                GIT_USER_NAME = "khushalbhavsar"             // Git commit author name
                YAML_FILE = "deployment.yaml"                 // Kubernetes deployment manifest
            }
            steps {
                // Navigate to the GitOps manifest directory
                dir('gitops/apps/swiggy') {
                    // Use GitHub Personal Access Token for authentication
                    withCredentials([string(credentialsId: 'my-git-pattoken', variable: 'git_token')]) {
                        sh '''
                            # Configure Git user for the commit
                            git config user.email "${GIT_EMAIL}"
                            git config user.name "${GIT_USER_NAME}"
                            BUILD_NUMBER=${BUILD_NUMBER}
                            echo $BUILD_NUMBER

                            # Use sed to replace the image line in deployment.yaml
                            # This updates the container image to the newly built version
                            # Example: image: 843998948464.dkr.ecr.us-east-1.amazonaws.com/swiggy:42
                            sed -i "s#image:.*#image: ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:$BUILD_NUMBER#g" ${YAML_FILE}
                            
                            # Commit and push the changes to trigger ArgoCD sync
                            git add .
                            git commit -m "Update ${AWS_ECR_REPO_NAME} Image to version \${BUILD_NUMBER}"
                            git push https://${git_token}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
        
                        '''
                    }
                }
            }
        }
    }

    // ============================================================================
    // POST-BUILD ACTIONS
    // ============================================================================
    // Actions that run after all stages complete (regardless of success/failure)
    post {
        // 'always' block runs whether the build succeeds, fails, or is unstable
        always {
            script {
                // Create placeholder files if security scan reports don't exist
                // This prevents email attachment errors
                sh 'if [ ! -f trivyfs.txt ]; then echo "No trivyfs report found" > trivyfs.txt; fi'
                sh 'if [ ! -f trivyimage.txt ]; then echo "No trivy image report found" > trivyimage.txt; fi'
                sh 'if [ ! -f dependency-check-report.xml ]; then echo "No dependency check report found" > dependency-check-report.xml; fi'
            }
            // Send email notification with build results and security scan reports
            // Requires Email Extension Plugin (emailext) configured in Jenkins
            emailext(
                from: 'khushalbhavsar41@gmail.com',           // Sender email address
                replyTo: 'khushalbhavsar41@gmail.com',        // Reply-to address
                attachLog: true,                              // Attach full build log
                subject: "Build ${currentBuild.result}",      // Email subject with build status
                // HTML email body with styled sections for project info
                body: """
                <html>
                <body>
                    <div style="background-color: #FFA07A; padding: 10px; margin-bottom: 10px;">
                        <p style="color: white; font-weight: bold;">Project: ${env.JOB_NAME}</p>
                    </div>
                    <div style="background-color: #90EE90; padding: 10px; margin-bottom: 10px;">
                        <p style="color: white; font-weight: bold;">Build Number: ${env.BUILD_NUMBER}</p>
                    </div>
                    <div style="background-color: #87CEEB; padding: 10px; margin-bottom: 10px;">
                        <p style="color: white; font-weight: bold;">URL: ${env.BUILD_URL}</p>
                    </div>
                </body>
                </html>
            """,
                to: 'khushalbhavsar41@gmail.com',             // Recipient email address
                mimeType: 'text/html',                        // Email format
                // Attach security scan reports: Trivy FS scan, Trivy image scan, OWASP report
                attachmentsPattern: 'trivyfs.txt,trivyimage.txt,**/dependency-check-report.xml'
            )
        }
    }
}





















