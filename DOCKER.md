# Docker Development Guide

This guide helps you develop and test your static site locally using Docker before deploying to AWS.

## Quick Start

### 1. Local Development
```bash
# Build and run your site locally
docker-compose up --build

# Open http://localhost in your browser
# Your site is now running in the same container environment as production
```

### 2. Development Workflow
```bash
# Make changes to your HTML/CSS/JS files
# Rebuild and restart
docker-compose down
docker-compose up --build

# Or for quick rebuilds:
docker-compose build && docker-compose up
```

### 3. Testing Container
```bash
# Test your container build without docker-compose
docker build -t my-static-site .
docker run -p 80:80 my-static-site

# Check health endpoint
curl http://localhost/health
```

## Development Commands

### Container Management
```bash
# View running containers
docker ps

# View logs
docker logs static-site-web

# Execute commands in container
docker exec -it static-site-web /bin/sh

# Stop container
docker stop static-site-web

# Remove container
docker rm static-site-web
```

### Image Management
```bash
# List images
docker images

# Remove unused images
docker image prune

# Remove all stopped containers
docker container prune
```

## File Structure for Development

```
your-project/
├── index.html              # Your main page
├── css/                   # Stylesheets
├── js/                    # JavaScript files
├── images/                # Images and assets
├── Dockerfile             # Container definition
├── docker-compose.yml     # Local development config
├── docker/
│   └── nginx.conf         # Web server configuration
└── .dockerignore          # Files to exclude from container
```

## Customizing the Container

### Nginx Configuration
Edit `docker/nginx.conf` to:
- Add custom headers
- Configure caching rules
- Set up redirects
- Add custom locations

### Dockerfile Modifications
Edit `Dockerfile` to:
- Add build steps
- Install additional tools
- Copy additional files
- Set environment variables

Example custom Dockerfile:
```dockerfile
FROM nginx:alpine

# Install additional tools
RUN apk add --no-cache curl

# Copy custom nginx config
COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

# Copy static files
COPY . /usr/share/nginx/html/

# Remove unnecessary files
RUN rm -rf /usr/share/nginx/html/.git* \
    /usr/share/nginx/html/docker \
    /usr/share/nginx/html/Dockerfile

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost/health || exit 1

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## Testing Before Deployment

### 1. Build Test
```bash
# Ensure your container builds successfully
docker build -t test-build .
```

### 2. Run Test
```bash
# Test container runs and serves content
docker run -d --name test-run -p 8080:80 test-build
curl http://localhost:8080
docker stop test-run && docker rm test-run
```

### 3. Health Check Test
```bash
# Verify health endpoint works
docker run -d --name health-test -p 8080:80 test-build
curl http://localhost:8080/health
docker stop health-test && docker rm health-test
```

## Troubleshooting

### Container Won't Start
```bash
# Check container logs
docker logs static-site-web

# Check nginx configuration
docker exec static-site-web nginx -t
```

### Site Not Accessible
```bash
# Check if container is running
docker ps

# Check port mapping
docker port static-site-web

# Test inside container
docker exec static-site-web curl http://localhost/health
```

### Performance Issues
```bash
# Check container resource usage
docker stats static-site-web

# Monitor nginx logs
docker exec static-site-web tail -f /var/log/nginx/access.log
```

## Production Deployment

Once you're happy with local testing:

1. Commit your changes
2. Push to main branch
3. GitHub Actions will automatically:
   - Build your container on AWS
   - Deploy with zero-downtime
   - Run health checks
   - Rollback on failure

The exact same container that works locally will run in production!
