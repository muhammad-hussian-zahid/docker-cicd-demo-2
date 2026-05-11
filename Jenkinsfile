pipeline {
    agent any
    
    environment {
        DOCKER_IMAGE = 'your-dockerhub-username/docker-cicd-demo'
        DOCKER_CREDENTIALS = 'dockerhub-credentials'
        BUILD_NUMBER = "${env.BUILD_NUMBER}"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'npm test'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    def image = docker.build("${DOCKER_IMAGE}:${BUILD_NUMBER}")
                    docker.build("${DOCKER_IMAGE}:latest")
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                echo 'Running security scan...'
                sh '''
                    # Install Trivy if not present
                    if ! command -v trivy &> /dev/null; then
                        wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
                        echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
                        sudo apt-get update
                        sudo apt-get install trivy -y
                    fi
                    
                    # Scan the image
                    trivy image --exit-code 0 --severity HIGH,CRITICAL ${DOCKER_IMAGE}:${BUILD_NUMBER}
                '''
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing to Docker Hub...'
                script {
                    docker.withRegistry('https://registry.hub.docker.com', DOCKER_CREDENTIALS) {
                        def image = docker.image("${DOCKER_IMAGE}:${BUILD_NUMBER}")
                        image.push()
                        image.push("latest")
                        
                        // Tag with git commit
                        def gitCommit = sh(returnStdout: true, script: 'git rev-parse HEAD').trim()
                        image.push(gitCommit.take(8))
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            steps {
                echo 'Deploying to staging environment...'
                sh '''
                    # Stop existing container if running
                    docker stop docker-cicd-staging || true
                    docker rm docker-cicd-staging || true
                    
                    # Run new container
                    docker run -d --name docker-cicd-staging -p 3001:3000 ${DOCKER_IMAGE}:${BUILD_NUMBER}
                    
                    # Wait for container to be ready
                    sleep 10
                    
                    # Health check
                    curl -f http://localhost:3001/health || exit 1
                '''
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning up...'
            sh 'docker system prune -f'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo 'Deploying to production EC2...'
                script {
                    // Add EC2 SSH credentials to Jenkins first
                    sshagent(['ec2-ssh-key']) {
                        sh '''
                            ssh -o StrictHostKeyChecking=no ubuntu@your-ec2-ip << 'ENDSSH'
                                # Pull and deploy latest image
                                docker pull ${DOCKER_IMAGE}:${BUILD_NUMBER}
                                docker stop docker-cicd-prod || true
                                docker rm docker-cicd-prod || true
                                docker run -d --name docker-cicd-prod -p 80:3000 --restart unless-stopped ${DOCKER_IMAGE}:${BUILD_NUMBER}
                                
                                # Health check
                                sleep 10
                                curl -f http://localhost/health
ENDSSH
                        '''
                    }
                }
            }
        }
