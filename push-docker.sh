#!/bin/bash
set -e

# Variables
IMAGE_NAME="your-dockerhub-username/docker-cicd-demo"
BUILD_NUMBER=${BUILD_NUMBER:-latest}
GIT_COMMIT=${GIT_COMMIT:-$(git rev-parse HEAD)}

echo "Pushing Docker images to Docker Hub..."
docker push ${IMAGE_NAME}:${BUILD_NUMBER}
docker push ${IMAGE_NAME}:latest
docker push ${IMAGE_NAME}:${GIT_COMMIT:0:8}

echo "Images pushed successfully!"
