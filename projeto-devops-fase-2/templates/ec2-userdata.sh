#!/bin/bash
# Bootstrap: install Docker and run ECR image with retry (Amazon Linux 2)
# Template vars: ecr_repository_url, aws_region, ecr_image_tag

set -e

yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

REGION="${aws_region}"
ECR_URL="${ecr_repository_url}"
TAG="${ecr_image_tag}"
IMAGE="$${ECR_URL}:$${TAG}"
REGISTRY=$$(echo "$$ECR_URL" | cut -d'/' -f1)
CONTAINER_NAME="site-prod"

# Retry loop: pull and run container until image exists in ECR (e.g. after first push)
while true; do
  if aws ecr get-login-password --region "$$REGION" | docker login --username AWS --password-stdin "$$REGISTRY" 2>/dev/null; then
    if docker pull "$$IMAGE" 2>/dev/null; then
      docker rm -f "$$CONTAINER_NAME" 2>/dev/null || true
      docker run -d -p 80:80 --restart always --name "$$CONTAINER_NAME" "$$IMAGE" && break
    fi
  fi
  sleep 120
done
