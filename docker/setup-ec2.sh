#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐳 Setting up Docker environment on EC2...${NC}"

# Update system
echo -e "${YELLOW}📦 Updating system packages...${NC}"
sudo yum update -y

# Install Docker
echo -e "${YELLOW}🐳 Installing Docker...${NC}"
sudo yum install -y docker

# Start and enable Docker service
echo -e "${YELLOW}🚀 Starting Docker service...${NC}"
sudo systemctl start docker
sudo systemctl enable docker

# Add ec2-user to docker group
echo -e "${YELLOW}👤 Adding ec2-user to docker group...${NC}"
sudo usermod -a -G docker ec2-user

# Install Docker Compose
echo -e "${YELLOW}📦 Installing Docker Compose...${NC}"
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create deployment directory
echo -e "${YELLOW}📁 Creating deployment directory...${NC}"
sudo mkdir -p /opt/static-site
sudo chown ec2-user:ec2-user /opt/static-site

# Install additional tools
echo -e "${YELLOW}🛠️ Installing additional tools...${NC}"
sudo yum install -y git curl wget

# Install nginx for health checks and potential load balancing
echo -e "${YELLOW}🌐 Installing nginx for health checks...${NC}"
sudo amazon-linux-extras install -y nginx1

# Create nginx configuration for Docker proxy
echo -e "${YELLOW}⚙️ Configuring nginx as reverse proxy...${NC}"
sudo tee /etc/nginx/conf.d/docker-proxy.conf > /dev/null << 'EOF'
upstream docker_backend {
    server 127.0.0.1:8080;
}

server {
    listen 80;
    server_name _;

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "nginx healthy\n";
        add_header Content-Type text/plain;
    }

    # Proxy to Docker container
    location / {
        proxy_pass http://docker_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Handle WebSocket upgrades
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Timeouts
        proxy_connect_timeout 30s;
        proxy_send_timeout 30s;
        proxy_read_timeout 30s;
    }
}
EOF

# Disable default nginx site
sudo rm -f /etc/nginx/conf.d/default.conf

# Start nginx
echo -e "${YELLOW}🚀 Starting nginx...${NC}"
sudo systemctl start nginx
sudo systemctl enable nginx

# Create deployment script
echo -e "${YELLOW}📝 Creating deployment scripts...${NC}"
cat > /opt/static-site/deploy.sh << 'EOF'
#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Docker deployment...${NC}"

# Configuration
IMAGE_NAME="static-site"
CONTAINER_NAME="static-site-web"
BACKUP_CONTAINER_NAME="static-site-web-backup"
DEPLOYMENT_DIR="/opt/static-site"
HEALTH_CHECK_URL="http://localhost:8080/health"

cd "$DEPLOYMENT_DIR"

# Build new image
echo -e "${YELLOW}📦 Building Docker image...${NC}"
docker build -t "$IMAGE_NAME:latest" .

# Check if container is running
if docker ps -q -f name="$CONTAINER_NAME" | grep -q .; then
    echo -e "${YELLOW}🔄 Performing rolling update...${NC}"

    # Create backup
    docker stop "$CONTAINER_NAME" || true
    docker rename "$CONTAINER_NAME" "$BACKUP_CONTAINER_NAME" 2>/dev/null || true

    # Start new container
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 8080:80 \
        "$IMAGE_NAME:latest"

    # Health check
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
        sleep 2
    done

    # Cleanup backup
    docker rm "$BACKUP_CONTAINER_NAME" 2>/dev/null || true
else
    echo -e "${YELLOW}🆕 Fresh deployment...${NC}"
    docker run -d \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        -p 8080:80 \
        "$IMAGE_NAME:latest"

    # Health check
    for i in {1..30}; do
        if curl -f -s "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Health check passed!${NC}"
            break
        fi
        if [ $i -eq 30 ]; then
            echo -e "${RED}❌ Health check failed.${NC}"
            exit 1
        fi
        sleep 2
    done
fi

# Cleanup old images
docker images "$IMAGE_NAME" --format "table {{.ID}}\t{{.CreatedAt}}" | tail -n +2 | sort -k2 -r | tail -n +4 | awk '{print $1}' | xargs -r docker rmi || true

echo -e "${GREEN}🎉 Deployment completed!${NC}"
EOF

chmod +x /opt/static-site/deploy.sh

# Create container management script
cat > /opt/static-site/manage.sh << 'EOF'
#!/bin/bash

CONTAINER_NAME="static-site-web"

case "$1" in
    "status")
        echo "Container Status:"
        docker ps -a --filter name="$CONTAINER_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        ;;
    "logs")
        docker logs -f "$CONTAINER_NAME"
        ;;
    "restart")
        docker restart "$CONTAINER_NAME"
        echo "Container restarted"
        ;;
    "stop")
        docker stop "$CONTAINER_NAME"
        echo "Container stopped"
        ;;
    "start")
        docker start "$CONTAINER_NAME"
        echo "Container started"
        ;;
    "shell")
        docker exec -it "$CONTAINER_NAME" /bin/sh
        ;;
    *)
        echo "Usage: $0 {status|logs|restart|stop|start|shell}"
        ;;
esac
EOF

chmod +x /opt/static-site/manage.sh

# Create systemd service for auto-restart
echo -e "${YELLOW}⚙️ Creating systemd service...${NC}"
sudo tee /etc/systemd/system/static-site.service > /dev/null << 'EOF'
[Unit]
Description=Static Site Docker Container
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/static-site
ExecStart=/bin/bash -c 'docker start static-site-web || docker run -d --name static-site-web --restart unless-stopped -p 8080:80 static-site:latest'
ExecStop=/usr/bin/docker stop static-site-web
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable static-site.service

echo -e "${GREEN}✅ Docker setup completed!${NC}"
echo -e "${BLUE}📋 Summary:${NC}"
echo -e "  - Docker installed and configured"
echo -e "  - Docker Compose installed"
echo -e "  - Deployment directory: /opt/static-site"
echo -e "  - Deploy script: /opt/static-site/deploy.sh"
echo -e "  - Management script: /opt/static-site/manage.sh"
echo -e "  - Nginx reverse proxy configured"
echo -e "  - Container will run on port 8080 (proxied via nginx on port 80)"

echo -e "${YELLOW}🔄 Please log out and log back in for docker group changes to take effect${NC}"
echo -e "${GREEN}🚀 Ready for Docker-based deployments!${NC}"
