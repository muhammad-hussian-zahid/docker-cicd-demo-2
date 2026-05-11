#!/bin/bash
set -e

# Configuration
EC2_HOST="54.167.84.158"
EC2_USER="ubuntu"
KEY_PATH="~/key.pem"
IMAGE_NAME="hussain968/docker-cicd-demo"
BUILD_NUMBER=${BUILD_NUMBER:-latest}

echo "Deploying to EC2 instance: ${EC2_HOST}"

# Deploy via SSH
ssh -i ${KEY_PATH} -o StrictHostKeyChecking=no ${EC2_USER}@${EC2_HOST} << EOF
    # Update system and install Docker if needed
    sudo apt-get update
    
    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com -o get-docker.sh
        sudo sh get-docker.sh
        sudo usermod -aG docker ubuntu
    fi
    
    # Pull latest image
    docker pull ${IMAGE_NAME}:${BUILD_NUMBER}
    
    # Stop existing container
    docker stop docker-cicd-prod || true
    docker rm docker-cicd-prod || true
    
    # Run new container
    docker run -d --name docker-cicd-prod -p 80:3000 --restart unless-stopped ${IMAGE_NAME}:${BUILD_NUMBER}
    
    # Verify deployment
    sleep 10
    curl -f http://localhost/health || exit 1
    
    echo "Deployment completed successfully!"
