#!/bin/bash

# Container management script for Terraform-managed infrastructure
# This script provides container management operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="static-site-web"
DEPLOY_DIR="/opt/static-site"

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to check if container exists
container_exists() {
    docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Function to check if container is running
container_running() {
    docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Function to show container status
show_status() {
    echo ""
    echo "=== Container Status ==="

    # Docker daemon status
    if systemctl is-active --quiet docker; then
        success "Docker daemon: Running"
    else
        error "Docker daemon: Not running"
        return 1
    fi

    # Container status
    if container_running; then
        success "Container: Running"

        # Get detailed container info
        echo ""
        log "Container Details:"
        docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

        # Get container resource usage
        echo ""
        log "Resource Usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}" "${CONTAINER_NAME}" 2>/dev/null || warn "Could not get resource stats"

        # Test nginx
        echo ""
        log "Health Checks:"
        if docker exec "$CONTAINER_NAME" curl -f -s http://localhost > /dev/null 2>&1; then
            success "✅ Nginx is responding"
        else
            error "❌ Nginx is not responding"
        fi

        # Check if nginx config is valid
        if docker exec "$CONTAINER_NAME" nginx -t >/dev/null 2>&1; then
            success "✅ Nginx configuration is valid"
        else
            error "❌ Nginx configuration has errors"
        fi

    elif container_exists; then
        warn "Container: Exists but not running"

        # Show container info
        echo ""
        log "Container Details:"
        docker ps -a --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

    else
        warn "Container: Does not exist"
    fi

    # Show public IP and access URLs
    echo ""
    log "Access Information:"
    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "unknown")
    if [ "$PUBLIC_IP" != "unknown" ]; then
        log "Public IP: $PUBLIC_IP"
        log "Website URL: http://$PUBLIC_IP"
        log "Health endpoint: http://$PUBLIC_IP/health"
    fi

    echo "======================="
}

# Function to start container
start_container() {
    log "Starting container..."

    if container_running; then
        warn "Container is already running"
        return 0
    fi

    if container_exists; then
        # Start existing container
        log "Starting existing container..."
        docker start "$CONTAINER_NAME"
    else
        # Create and start new container
        log "Creating new container..."

        # Ensure deployment directory exists
        sudo mkdir -p "$DEPLOY_DIR/current"

        # Create container
        docker run -d \
            --name "$CONTAINER_NAME" \
            --restart unless-stopped \
            -p 8080:80 \
            -v "$DEPLOY_DIR/current:/usr/share/nginx/html:ro" \
            nginx:alpine
    fi

    # Wait for container to be ready
    sleep 3

    if container_running; then
        success "Container started successfully"
    else
        error "Failed to start container"
        return 1
    fi
}

# Function to stop container
stop_container() {
    log "Stopping container..."

    if ! container_running; then
        warn "Container is not running"
        return 0
    fi

    docker stop "$CONTAINER_NAME"

    # Wait for container to stop
    sleep 2

    if ! container_running; then
        success "Container stopped successfully"
    else
        error "Failed to stop container"
        return 1
    fi
}

# Function to restart container
restart_container() {
    log "Restarting container..."

    if container_exists; then
        docker restart "$CONTAINER_NAME"

        # Wait for container to be ready
        sleep 3

        if container_running; then
            success "Container restarted successfully"
        else
            error "Failed to restart container"
            return 1
        fi
    else
        warn "Container does not exist, creating new one..."
        start_container
    fi
}

# Function to show container logs
show_logs() {
    local lines=${1:-50}

    if ! container_exists; then
        error "Container does not exist"
        return 1
    fi

    log "Showing last $lines lines of container logs..."
    echo ""

    docker logs --tail "$lines" "$CONTAINER_NAME"
}

# Function to follow container logs
follow_logs() {
    if ! container_exists; then
        error "Container does not exist"
        return 1
    fi

    log "Following container logs (Press Ctrl+C to stop)..."
    echo ""

    docker logs -f "$CONTAINER_NAME"
}

# Function to execute command in container
exec_container() {
    if ! container_running; then
        error "Container is not running"
        return 1
    fi

    shift  # Remove 'exec' from arguments
    local cmd="$*"

    if [ -z "$cmd" ]; then
        # Interactive shell
        log "Opening interactive shell in container..."
        docker exec -it "$CONTAINER_NAME" /bin/sh
    else
        # Execute command
        log "Executing command in container: $cmd"
        docker exec "$CONTAINER_NAME" $cmd
    fi
}

# Function to update nginx config
update_nginx_config() {
    if ! container_running; then
        error "Container is not running"
        return 1
    fi

    log "Testing nginx configuration..."
    if docker exec "$CONTAINER_NAME" nginx -t; then
        log "Reloading nginx configuration..."
        docker exec "$CONTAINER_NAME" nginx -s reload
        success "Nginx configuration updated successfully"
    else
        error "Nginx configuration test failed"
        return 1
    fi
}

# Function to remove container
remove_container() {
    log "Removing container..."

    if container_running; then
        log "Stopping running container first..."
        docker stop "$CONTAINER_NAME"
    fi

    if container_exists; then
        docker rm "$CONTAINER_NAME"
        success "Container removed successfully"
    else
        warn "Container does not exist"
    fi
}

# Function to show help
show_help() {
    echo "Container Management Script"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  status                    - Show container status and health"
    echo "  start                     - Start the container"
    echo "  stop                      - Stop the container"
    echo "  restart                   - Restart the container"
    echo "  logs [lines]              - Show container logs (default: 50 lines)"
    echo "  follow                    - Follow container logs in real-time"
    echo "  exec [command]            - Execute command in container (interactive shell if no command)"
    echo "  reload                    - Reload nginx configuration"
    echo "  remove                    - Remove the container"
    echo "  help                      - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 status                 - Check container status"
    echo "  $0 logs 100              - Show last 100 log lines"
    echo "  $0 exec ls -la            - List files in container"
    echo "  $0 exec                   - Open interactive shell"
}

# Function to check docker is available
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
        exit 1
    fi

    if ! systemctl is-active --quiet docker; then
        error "Docker service is not running"
        log "Try: sudo systemctl start docker"
        exit 1
    fi
}

# Main function
main() {
    # Check docker availability
    check_docker

    local command=${1:-status}

    case "$command" in
        "status")
            show_status
            ;;
        "start")
            start_container
            ;;
        "stop")
            stop_container
            ;;
        "restart")
            restart_container
            ;;
        "logs")
            show_logs "${2:-50}"
            ;;
        "follow")
            follow_logs
            ;;
        "exec")
            exec_container "$@"
            ;;
        "reload")
            update_nginx_config
            ;;
        "remove")
            remove_container
            ;;
        "help")
            show_help
            ;;
        *)
            error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
