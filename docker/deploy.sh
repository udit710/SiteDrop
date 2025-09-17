#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting zero-downtime deployment...${NC}"

# Configuration
IMAGE_NAME="static-site"
CONTAINER_NAME="static-site-web"
BACKUP_CONTAINER_NAME="static-site-web-backup"
DEPLOYMENT_DIR="/opt/static-site"
HEALTH_CHECK_URL="http://localhost/health"

cd "$DEPLOYMENT_DIR"

# Pull latest code (this would be done by GitHub Actions)
echo -e "${YELLOW}📦 Building new Docker image...${NC}"
docker build -t "$IMAGE_NAME:latest" .

# Check if container is currently running
if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    echo -e "${YELLOW}🔄 Existing container found. Performing rolling update...${NC}"

    # Stop and rename current container as backup
    echo -e "${YELLOW}📦 Creating backup of current container...${NC}"
    docker stop "$CONTAINER_NAME" || true
    docker rename "$CONTAINER_NAME" "$BACKUP_CONTAINER_NAME" 2>/dev/null || true

    # Start new container
    echo -e "${YELLOW}🚀 Starting new container...${NC}"
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 80:80 \
        "$IMAGE_NAME:latest"

    # Wait for health check
    echo -e "${YELLOW}🏥 Waiting for health check...${NC}"
    for i in {1..30}; do
        if curl -f -s "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Health check passed!${NC}"
            break
        fi
        if [ $i -eq 30 ]; then
            echo -e "${RED}❌ Health check failed. Rolling back...${NC}"
            docker stop "$CONTAINER_NAME" || true
            docker rm "$CONTAINER_NAME" || true
            docker rename "$BACKUP_CONTAINER_NAME" "$CONTAINER_NAME" 2>/dev/null || true
            docker start "$CONTAINER_NAME" || true
            exit 1
        fi
        echo -e "${YELLOW}⏳ Attempt $i/30: Waiting for health check...${NC}"
        sleep 2
    done

    # Remove backup container
    echo -e "${YELLOW}🧹 Cleaning up backup container...${NC}"
    docker rm "$BACKUP_CONTAINER_NAME" 2>/dev/null || true

else
    echo -e "${YELLOW}🆕 No existing container found. Starting fresh deployment...${NC}"
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 80:80 \
        "$IMAGE_NAME:latest"

    # Wait for health check
    echo -e "${YELLOW}🏥 Waiting for health check...${NC}"
    for i in {1..30}; do
        if curl -f -s "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Health check passed!${NC}"
            break
        fi
        if [ $i -eq 30 ]; then
            echo -e "${RED}❌ Health check failed.${NC}"
            exit 1
        fi
        echo -e "${YELLOW}⏳ Attempt $i/30: Waiting for health check...${NC}"
        sleep 2
    done
fi

# Clean up old images (keep last 3)
echo -e "${YELLOW}🧹 Cleaning up old Docker images...${NC}"
docker images "$IMAGE_NAME" --format "table {{.ID}}\t{{.CreatedAt}}" | tail -n +2 | sort -k2 -r | tail -n +4 | awk '{print $1}' | xargs -r docker rmi || true

# Get container info
CONTAINER_ID=$(docker ps -q -f name="$CONTAINER_NAME")
CONTAINER_STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "not found")

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${BLUE}📊 Container Status:${NC}"
echo -e "  Container ID: $CONTAINER_ID"
echo -e "  Status: $CONTAINER_STATUS"
echo -e "  Health Check: $HEALTH_CHECK_URL"

# Test the deployment
echo -e "${BLUE}🧪 Testing deployment...${NC}"
if curl -f -s "http://localhost" > /dev/null; then
    echo -e "${GREEN}✅ Site is accessible!${NC}"
else
    echo -e "${RED}❌ Site is not accessible!${NC}"
    exit 1
fi

echo -e "${GREEN}🚀 Deployment completed successfully!${NC}"
