# Docker-Powered Static Site Deployer

Deploy and update your static HTML site on AWS EC2 with Docker containers and zero-downtime CI/CD. Fork once, deploy in containers forever!

## ✨ Key Features

- **� Docker-Powered**: Containerized deployments for consistency and reliability
- **🔄 Zero-Downtime**: Rolling updates with automatic health checks and rollbacks
- **💰 Cost Efficient**: Smart instance management - containers restart automatically
- **🚀 One-Click Deploy**: Fork → Add creds → Push = Live containerized site
- **⚙️ Container Management**: Start, stop, restart containers without touching the instance
- **🛡️ Production Ready**: Nginx reverse proxy, health checks, and automatic backups
- **� Environment Consistency**: Same container runs everywhere (dev, staging, prod)

## Quick Start

1. **Fork this repository**
2. **Add your static files** - Replace `index.html` with your site
3. **Configure AWS credentials** in repository secrets
4. **Push to main branch** - Your site will be automatically deployed!

## How It Works

### First Deployment
- Creates EC2 instance with Docker pre-installed
- Sets up nginx reverse proxy for load balancing
- Builds and deploys your site in a Docker container
- Outputs the live URL

### Subsequent Updates
- Finds existing Docker-enabled instance
- Performs rolling update (zero-downtime deployment)
- Builds new container image
- Stops old container, starts new one
- Automatic rollback on health check failure

### Container Management
- **Restart Container**: Quick restart without affecting instance
- **Stop/Start Container**: Manage site availability independently
- **View Logs**: Monitor container and nginx logs
- **Instance Control**: Traditional stop/start/restart for cost savings

## Local Development

Test your site locally with Docker:

```bash
# Build and run locally
docker-compose up --build

# Your site will be available at http://localhost
# Make changes and rebuild as needed
```

## Setup Instructions

### 1. Fork & Clone
Fork this repository and add your static site files to the root directory.

### 2. AWS Credentials Setup
Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key
- `AWS_REGION` - AWS region (optional, defaults to us-east-1)

### 3. Deploy
Push to the main branch and GitHub Actions will handle everything automatically.

## Managing Your Deployment

Use the "Manage Docker Instance" workflow (Actions tab) to:

### Container Operations
- **Container Status**: View running containers and health
- **Restart Container**: Zero-downtime restart of web container
- **Stop Container**: Stop serving the site (instance keeps running)
- **Start Container**: Resume serving after stop
- **Container Logs**: View recent container and nginx logs

### Instance Operations
- **Stop Instance**: Save money when site isn't needed (preserves containers)
- **Start Instance**: Resume stopped instance (containers auto-restart)
- **Restart Instance**: Reboot running instance (containers auto-restart)
- **Terminate**: Permanently destroy instance and all data

## Configuration Options

### Instance Type
Edit `.github/workflows/deploy.yml` and change the `INSTANCE_TYPE`:
```yaml
env:
  INSTANCE_TYPE: t3.small  # or t2.micro, t3.micro, etc.
```

### Container Configuration
- Edit `Dockerfile` to customize the container build
- Modify `docker/nginx.conf` for advanced nginx settings
- Update `docker-compose.yml` for local development changes

### Force Recreate
Use the "Force recreate" option in manual workflow dispatch to start completely fresh.

## Requirements

- AWS account with EC2 permissions
- GitHub repository with Actions enabled
- Static HTML files (index.html required)

## Cost Breakdown

### t3.micro (Recommended)
- **Running**: ~$7.60/month (free for first 750 hours)
- **Stopped**: ~$1/month (EBS storage only)
- **Data Transfer**: First 1GB/month free

### Cost Optimization Tips
- Stop instance when not needed (containers preserved, compute charges stop)
- Use t3.micro for free tier eligibility and better performance
- Monitor container resource usage in Docker logs
- Containers automatically restart when instance resumes

## Docker Benefits

### Zero-Downtime Deployments
- Rolling updates with health checks
- Automatic rollback on failure
- No service interruption during updates

### Environment Consistency
- Same container runs in development and production
- Eliminates "works on my machine" problems
- Easy testing with `docker-compose up`

### Better Resource Management
- Containers use only needed resources
- Easy horizontal scaling in the future
- Built-in health monitoring

## Security Features

- Docker container isolation for better security
- Nginx reverse proxy with security headers
- Isolated security groups per deployment
- SSH access only during deployment
- Automatic container health monitoring
- Built-in backup system for container rollbacks

## File Structure Support

The Docker deployer handles all common static site files:
```
your-repo/
├── index.html              (required)
├── css/                   (stylesheets)
├── js/                    (javascript)
├── images/                (images and assets)
├── assets/                (additional assets)
├── Dockerfile             (container definition)
├── docker-compose.yml     (local development)
├── docker/
│   ├── nginx.conf         (nginx configuration)
│   ├── deploy.sh          (deployment script)
│   └── setup-ec2.sh       (initial server setup)
└── any other static files
```

## Advanced Usage

### SSH Access for Container Management
For direct container management, SSH to your instance:
```bash
ssh -i your-key.pem ec2-user@YOUR_IP

# Container management commands
docker ps                          # List running containers
docker logs static-site-web        # View container logs
docker restart static-site-web     # Restart container
cd /opt/static-site && ./manage.sh status  # Use management script
```

### Custom Domain Setup
After deployment:
1. Point your domain's A record to the instance's public IP
2. Update nginx configuration for your domain (optional)
3. Set up SSL with Let's Encrypt (advanced setup)