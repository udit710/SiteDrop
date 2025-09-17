# Static Site Auto-Deployer

Deploy and update your static HTML site on AWS EC2 with persistent CI/CD. Fork once, update forever!

## ✨ Key Features

- **🔄 Smart CI/CD**: Updates existing instance instead of creating new ones
- **💰 Cost Efficient**: Reuses infrastructure, stops/starts instances as needed
- **🚀 One-Click Deploy**: Fork → Add creds → Push = Live site
- **⚙️ Instance Management**: Start, stop, restart, or terminate via GitHub Actions
- **🛡️ Secure**: Isolated security groups, temporary SSH keys
- **📱 Production Ready**: Nginx with caching, security headers, and backups

## Quick Start

1. **Fork this repository**
2. **Add your static files** - Replace `index.html` with your site
3. **Configure AWS credentials** in repository secrets
4. **Push to main branch** - Your site will be automatically deployed!

## How It Works

### First Deployment
- Creates EC2 instance, security group, and key pair
- Installs and configures nginx
- Deploys your static files
- Outputs the live URL

### Subsequent Updates
- Finds existing instance
- Updates files without recreating infrastructure
- Backs up previous version
- Zero-downtime deployment

### Instance Management
- **Stop**: Saves costs while preserving data
- **Start**: Resume from stopped state
- **Restart**: Reboot running instance
- **Terminate**: Permanently destroy (use with caution!)

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

## Managing Your Instance

Use the "Manage EC2 Instance" workflow (Actions tab) to:

- **Check Status**: View instance state, IP, and site accessibility
- **Stop Instance**: Save money when site isn't needed (keeps data)
- **Start Instance**: Resume stopped instance (may get new IP)
- **Restart**: Reboot running instance (keeps same IP)
- **Terminate**: Permanently destroy instance and data

## Configuration Options

### Instance Type
Edit `.github/workflows/deploy.yml` and change the `INSTANCE_TYPE`:
```yaml
env:
  INSTANCE_TYPE: t3.micro  # or t2.small, t3.small, etc.
```

### Force Recreate
Use the "Force recreate" option in manual workflow dispatch to start fresh.

## Requirements

- AWS account with EC2 permissions
- GitHub repository with Actions enabled
- Static HTML files (index.html required)

## Cost Breakdown

### t2.micro (Free Tier)
- **Running**: ~$8.50/month (free for first 750 hours)
- **Stopped**: ~$1/month (EBS storage only)
- **Data Transfer**: First 1GB/month free

### Cost Optimization Tips
- Stop instance when not needed (preserves data, stops compute charges)
- Use t2.micro for free tier eligibility
- Monitor usage in AWS billing dashboard

## Security Features

- Isolated security groups per deployment
- SSH access only during deployment
- Security headers (XSS protection, content type sniffing)
- Automatic backup of previous deployments
- Nginx configuration with proper caching

## File Structure Support

The deployer handles all common static site files:
```
your-repo/
├── index.html          (required)
├── css/               (stylesheets)
├── js/                (javascript)
├── images/            (images and assets)
├── assets/            (additional assets)
└── any other static files
```