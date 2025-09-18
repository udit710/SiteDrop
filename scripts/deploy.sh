#!/bin/bash

# Deploy script for Terraform-managed infrastructure
# This script deploys the static site to a running Docker container on EC2

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DEPLOY_DIR="/opt/static-site"
CONTAINER_NAME="static-site-web"
BACKUP_DIR="/opt/static-site/backups"
MAX_BACKUPS=5

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

# Function to check if Docker is running
check_docker() {
    if ! systemctl is-active --quiet docker; then
        error "Docker is not running"
        log "Starting Docker..."
        sudo systemctl start docker
    fi
}

# Function to check if container exists
container_exists() {
    docker ps -a --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Function to check if container is running
container_running() {
    docker ps --format "table {{.Names}}" | grep -q "^${CONTAINER_NAME}$"
}

# Function to create backup of current deployment
create_backup() {
    if container_exists; then
        log "Creating backup of current deployment..."

        # Create backup directory if it doesn't exist
        sudo mkdir -p "$BACKUP_DIR"

        # Create backup with timestamp
        BACKUP_NAME="backup-$(date +%Y%m%d-%H%M%S)"
        BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"

        # Copy current files if they exist
        if [ -d "$DEPLOY_DIR/current" ]; then
            sudo cp -r "$DEPLOY_DIR/current" "$BACKUP_PATH"
            success "Backup created: $BACKUP_PATH"
        else
            warn "No current deployment found to backup"
        fi

        # Clean up old backups (keep only MAX_BACKUPS)
        BACKUP_COUNT=$(sudo find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup-*" | wc -l)
        if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
            log "Cleaning up old backups..."
            sudo find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup-*" | \
                sort | head -n -"$MAX_BACKUPS" | \
                sudo xargs rm -rf
        fi
    fi
}

# Function to prepare deployment directory
prepare_deployment() {
    log "Preparing deployment directory..."

    # Create directories if they don't exist
    sudo mkdir -p "$DEPLOY_DIR/"{current,new,backups}

    # Copy new files to deployment directory
    log "Copying new files..."
    sudo cp -r /tmp/site-content/* "$DEPLOY_DIR/new/"

    # Set proper permissions
    sudo chown -R ec2-user:ec2-user "$DEPLOY_DIR/new"
    sudo chmod -R 755 "$DEPLOY_DIR/new"

    success "Files prepared for deployment"
}

# Function to validate deployment files
validate_deployment() {
    log "Validating deployment files..."

    # Check if index.html exists
    if [ ! -f "$DEPLOY_DIR/new/index.html" ]; then
        error "index.html not found in deployment files"
        return 1
    fi

    # Basic HTML validation
    if ! grep -q "<html" "$DEPLOY_DIR/new/index.html"; then
        warn "index.html might not be a valid HTML file"
    fi

    success "Deployment files validated"
}

# Function to update container
update_container() {
    log "Updating container with new content..."

    if container_running; then
        # Copy new files to running container
        docker cp "$DEPLOY_DIR/new/." "$CONTAINER_NAME:/usr/share/nginx/html/"

        # Test nginx configuration in container
        if docker exec "$CONTAINER_NAME" nginx -t; then
            # Reload nginx gracefully
            docker exec "$CONTAINER_NAME" nginx -s reload
            success "Container updated with zero downtime"
        else
            error "Nginx configuration test failed"
            return 1
        fi
    else
        error "Container is not running"
        return 1
    fi
}

# Function to start container if not running
start_container() {
    if ! container_running; then
        if container_exists; then
            log "Starting existing container..."
            docker start "$CONTAINER_NAME"
        else
            log "Creating and starting new container..."
            docker run -d \
                --name "$CONTAINER_NAME" \
                --restart unless-stopped \
                -p 8080:80 \
                -v "$DEPLOY_DIR/current:/usr/share/nginx/html:ro" \
                nginx:alpine
        fi

        # Wait for container to be ready
        sleep 5

        if container_running; then
            success "Container is running"
        else
            error "Failed to start container"
            return 1
        fi
    fi
}

# Function to health check
health_check() {
    log "Performing health check..."

    # Wait a moment for nginx to reload
    sleep 2

    # Check if container is healthy
    if ! container_running; then
        error "Container is not running"
        return 1
    fi

    # Check if nginx is responding
    if docker exec "$CONTAINER_NAME" curl -f -s http://localhost > /dev/null; then
        success "Health check passed"
        return 0
    else
        error "Health check failed"
        return 1
    fi
}

# Function to finalize deployment
finalize_deployment() {
    log "Finalizing deployment..."

    # Move new files to current
    sudo rm -rf "$DEPLOY_DIR/current"
    sudo mv "$DEPLOY_DIR/new" "$DEPLOY_DIR/current"

    # Update ownership
    sudo chown -R ec2-user:ec2-user "$DEPLOY_DIR/current"

    success "Deployment finalized"
}

# Function to rollback deployment
rollback_deployment() {
    error "Deployment failed, initiating rollback..."

    # Remove failed deployment
    sudo rm -rf "$DEPLOY_DIR/new"

    # Find latest backup
    LATEST_BACKUP=$(sudo find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup-*" | sort | tail -n 1)

    if [ -n "$LATEST_BACKUP" ]; then
        log "Rolling back to: $(basename "$LATEST_BACKUP")"

        # Restore from backup
        sudo rm -rf "$DEPLOY_DIR/current"
        sudo cp -r "$LATEST_BACKUP" "$DEPLOY_DIR/current"

        # Update container with backup content
        if container_running; then
            docker cp "$DEPLOY_DIR/current/." "$CONTAINER_NAME:/usr/share/nginx/html/"
            docker exec "$CONTAINER_NAME" nginx -s reload
        fi

        warn "Rollback completed"
    else
        error "No backup found for rollback"
    fi
}

# Function to show deployment status
show_status() {
    echo ""
    echo "=== Deployment Status ==="

    # Docker status
    if systemctl is-active --quiet docker; then
        success "Docker: Running"
    else
        error "Docker: Not running"
    fi

    # Container status
    if container_running; then
        success "Container: Running"

        # Get container info
        CONTAINER_INFO=$(docker inspect "$CONTAINER_NAME" --format='{{.State.Status}} ({{.State.StartedAt}})')
        log "Container Info: $CONTAINER_INFO"

        # Check nginx
        if docker exec "$CONTAINER_NAME" curl -f -s http://localhost > /dev/null 2>&1; then
            success "Nginx: Responding"
        else
            warn "Nginx: Not responding"
        fi

    elif container_exists; then
        warn "Container: Exists but not running"
    else
        warn "Container: Does not exist"
    fi

    # Deployment info
    if [ -d "$DEPLOY_DIR/current" ]; then
        DEPLOY_TIME=$(sudo stat -c %Y "$DEPLOY_DIR/current" 2>/dev/null || echo "0")
        if [ "$DEPLOY_TIME" != "0" ]; then
            DEPLOY_DATE=$(date -d "@$DEPLOY_TIME" "+%Y-%m-%d %H:%M:%S")
            log "Last deployment: $DEPLOY_DATE"
        fi
    else
        warn "No current deployment found"
    fi

    # Backup info
    BACKUP_COUNT=$(sudo find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup-*" 2>/dev/null | wc -l)
    log "Available backups: $BACKUP_COUNT"

    echo "========================="
}

# Main deployment function
main() {
    log "Starting deployment process..."

    # Check if running as root or with sudo access
    if [ "$EUID" -eq 0 ]; then
        error "Do not run this script as root. Run as ec2-user with sudo access."
        exit 1
    fi

    # Check if deployment files exist
    if [ ! -d "/tmp/site-content" ]; then
        error "No deployment files found in /tmp/site-content"
        exit 1
    fi

    # Show initial status
    show_status

    # Perform deployment steps
    check_docker
    create_backup
    prepare_deployment

    if validate_deployment; then
        start_container

        if update_container && health_check; then
            finalize_deployment
            success "Deployment completed successfully!"
        else
            rollback_deployment
            exit 1
        fi
    else
        error "Deployment validation failed"
        sudo rm -rf "$DEPLOY_DIR/new"
        exit 1
    fi

    # Show final status
    show_status

    # Show access information
    echo ""
    log "Access your site at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
    log "Health check: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/health"
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "status")
        show_status
        ;;
    "rollback")
        if [ -z "$2" ]; then
            error "Usage: $0 rollback <backup-name>"
            error "Available backups:"
            sudo find "$BACKUP_DIR" -maxdepth 1 -type d -name "backup-*" | sort
            exit 1
        fi

        BACKUP_PATH="$BACKUP_DIR/$2"
        if [ -d "$BACKUP_PATH" ]; then
            log "Rolling back to: $2"
            sudo rm -rf "$DEPLOY_DIR/current"
            sudo cp -r "$BACKUP_PATH" "$DEPLOY_DIR/current"

            if container_running; then
                docker cp "$DEPLOY_DIR/current/." "$CONTAINER_NAME:/usr/share/nginx/html/"
                docker exec "$CONTAINER_NAME" nginx -s reload
            fi

            success "Rollback completed"
        else
            error "Backup not found: $2"
            exit 1
        fi
        ;;
    "help")
        echo "Usage: $0 [deploy|status|rollback|help]"
        echo ""
        echo "Commands:"
        echo "  deploy          - Deploy new content (default)"
        echo "  status          - Show deployment status"
        echo "  rollback <name> - Rollback to specific backup"
        echo "  help            - Show this help"
        ;;
    *)
        error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;
esac
