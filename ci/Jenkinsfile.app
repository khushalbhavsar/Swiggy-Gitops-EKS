pipeline {
    agent any 
    tools {
        jdk 'jdk'
        nodejs 'nodejs'
    }
    environment  {
        SCANNER_HOME = tool 'sonar-scanner'                 
        SONARQUBE_SERVER  = 'sonar-server'                
        AWS_ACCOUNT_ID = '843998948464'                  
        AWS_ECR_REPO_NAME = 'swiggy'                      
        SONAR_TOKEN_CRED  = 'sonarqube-token'            
        AWS_DEFAULT_REGION = 'us-east-1'                
        REPOSITORY_URI = "843998948464.dkr.ecr.us-east-1.amazonaws.com/swiggy" // replace with your ECR URI

    }
    stages {
        stage('Cleaning Workspace') {
            steps {
                cleanWs()
            }
        }
        stage('Checkout from Git') {
            steps {
                git branch: 'main', url: 'https://github.com/khushalbhavsar/Swiggy-Gitops-EKS.git'
            }
        }
        stage("List Files") {
            steps {
                sh 'ls -la' // verfy files after checkout
            }
        }
        stage('Sonarqube Analysis') {
            steps {
                dir('app/swiggy-react') {
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
        stage('Quality Check') {
            steps {
                script {
                    // This requires the "Quality Gates" webhook to be configured in SonarQube
                    waitForQualityGate abortPipeline: false, credentialsId: env.SONAR_TOKEN_CRED 
                }
            }
        }
        stage('Install Dependencies') {
            steps {
                dir('app/swiggy-react') {
                    sh '''
                    ls -la  # Verify package.json exists
                    if [ -f package.json ]; then
                        rm -rf node_modules package-lock.json  # Remove old dependencies
                        npm install  # Install fresh dependencies
                    else
                        echo "Error: package.json not found!"
                        exit 1
                    fi
                    '''
                }
            }
        }

        // this step it will take 45 min
        stage('OWASP FS Scan') {
            steps {
                dir('app/swiggy-react') {
                    dependencyCheck additionalArguments: '--scan . --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-check'
                    dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
                }
            }
        }

        stage('Trivy File Scan') {
            steps {
                dir('app/swiggy-react') {
                    sh 'trivy fs . > trivyfs.txt'
                }
            }
        }
        // no change in this stage
        stage("Docker Image Build") {
            steps {
                script {
                    dir('app/swiggy-react') {
                            sh 'docker system prune -f'
                            sh 'docker container prune -f'
                            sh 'docker build -t ${AWS_ECR_REPO_NAME} .'
                    }
                }
            }
        }
        // no change in this stage
        stage("ECR Image Pushing") {
            steps {
                script {
                        sh 'aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${REPOSITORY_URI}'
                        sh 'docker tag ${AWS_ECR_REPO_NAME}:latest ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                        sh 'docker push ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER}'
                }
            }
        }
        // no change in this stage
        stage("TRIVY Image Scan") {
            steps {
                sh 'trivy image ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:${BUILD_NUMBER} > trivyimage.txt'
            }
        }
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/khushalbhavsar/Swiggy-Gitops-EKS.git'
            }
        }
        stage('Update Deployment file') {
            environment {
                GIT_REPO_NAME = "Swiggy-Gitops-EKS"      // replace your github rep name
                GIT_EMAIL = "khushalbhavsar41@gmail.com"    // replace your email id
                GIT_USER_NAME = "khushalbhavsar"           // replace your user name
                YAML_FILE = "deployment.yaml"
            }
            steps {
                dir('gitops/apps/swiggy') {
                    withCredentials([string(credentialsId: 'my-git-pattoken', variable: 'git_token')]) {
                        sh '''
                            git config user.email "${GIT_EMAIL}"
                            git config user.name "${GIT_USER_NAME}"
                            BUILD_NUMBER=${BUILD_NUMBER}
                            echo $BUILD_NUMBER

                            # Update the deployment image tag
                            sed -i "s#image:.*#image: ${REPOSITORY_URI}/${AWS_ECR_REPO_NAME}:$BUILD_NUMBER#g" ${YAML_FILE}
                            git add .
                            git commit -m "Update ${AWS_ECR_REPO_NAME} Image to version \${BUILD_NUMBER}"
                            git push https://${git_token}@github.com/${GIT_USER_NAME}/${GIT_REPO_NAME} HEAD:main
        
                        '''
                    }
                }
            }
        }
    }
    post {
    always {
        script {
            // Ensure required files exist or create dummy files
            sh 'if [ ! -f trivyfs.txt ]; then echo "No trivyfs report found" > trivyfs.txt; fi'
            sh 'if [ ! -f trivyimage.txt ]; then echo "No trivy image report found" > trivyimage.txt; fi'
            sh 'if [ ! -f dependency-check-report.xml ]; then echo "No dependency check report found" > dependency-check-report.xml; fi'
        }
        emailext(
            from: 'khushalbhavsar41@gmail.com',
            replyTo: 'khushalbhavsar41@gmail.com',
            attachLog: true,
            subject: "Build ${currentBuild.result}",
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
            to: 'khushalbhavsar41@gmail.com',
            mimeType: 'text/html',
            attachmentsPattern: 'trivyfs.txt,trivyimage.txt,**/dependency-check-report.xml'
        )
    }
  }
}





















