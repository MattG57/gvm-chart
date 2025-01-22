#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Prompt the user for Docker credentials
echo "Enter your Docker Hub username:"
read -r DOCKER_USERNAME

echo "Enter your Docker Hub password:"
read -s DOCKER_PASSWORD  # Use -s to hide the password input

DOCKER_IMAGE="github-value-mongodb"            # Docker image name
DOCKER_TAG="latest"                    # Docker image tag
REGISTRY="mgunter"                     # Container registry (Docker Hub username or org)

# Ensure Buildx is set up
docker buildx create --use --name multiarch-builder || true
docker buildx inspect multiarch-builder --bootstrap

# Log in to Docker Hub
echo "Logging into Docker Hub..."
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Build and push the multi-architecture image
echo "Building and pushing multi-architecture Docker image..."
docker buildx build \
  --no-cache \
  --platform linux/amd64,linux/arm64 \
  -t "$REGISTRY/$DOCKER_IMAGE:$DOCKER_TAG" \
  --push .

# Verify the image manifest
echo "Verifying Docker image manifest..."
docker manifest inspect "$REGISTRY/$DOCKER_IMAGE:$DOCKER_TAG"

# Output success message
echo "Docker image successfully built and pushed to $REGISTRY/$DOCKER_IMAGE:$DOCKER_TAG"
