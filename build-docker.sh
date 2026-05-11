#!/bin/bash
set -e

# Variables
IMAGE_NAME="your-dockerhub-username/docker-cicd-demo"
BUILD_NUMBER=${BUILD_NUMBER:-latest}
GIT_COMMIT=${GIT_COMMIT:-$(git rev-parse HEAD)}

echo "Building Docker image..."
docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
docker build -t ${IMAGE_NAME}:latest .

echo "Tagging image with git commit..."
docker tag ${IMAGE_NAME}:${BUILD_NUMBER} ${IMAGE_NAME}:${GIT_COMMIT:0:8}

echo "Build completed successfully!"
