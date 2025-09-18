# Index Hoster - Terraform Edition

A modern, automated solution for hosting static websites on AWS EC2 using **Terraform** for infrastructure management and **GitHub Actions** for CI/CD with Docker containerization.

## ✨ Key Features

- **🏗️ Infrastructure as Code**: Terraform manages all AWS resources (EC2, Security Groups, Elastic IP)
- **🐳 Docker-Powered**: Containerized deployments for consistency and reliability
- **🔄 Zero-Downtime**: Rolling updates with automatic health checks and rollbacks
- **💰 Cost Efficient**: t3.micro instances (Free tier eligible) with smart management
- **🚀 Developer Friendly**: Simple fork-and-deploy workflow for teams
- **⚙️ Easy Management**: Web interface and CLI tools for operations
- **🛡️ Production Ready**: Nginx reverse proxy, health checks, and automatic backups

## Quick Start

1. **Fork this repository**
2. **Set up AWS credentials** in GitHub Secrets
3. **Run the deployment workflow** to create infrastructure
4. **Push changes** to automatically deploy updates

Your site will be live with a static IP address!

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub        │    │   AWS EC2        │    │   Docker        │
│   Actions       │───▶│   t3.micro       │───▶│   Nginx         │
│   (CI/CD)       │    │   + Elastic IP   │    │   Container     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                              │
                       ┌──────▼──────┐
                       │  Terraform  │
                       │  (IaC)      │
                       └─────────────┘
```

### Why This Architecture?

- **Terraform**: Manages infrastructure separately from application code
- **Docker**: Ensures consistent deployments across environments
- **GitHub Actions**: Automates the entire deployment pipeline
- **Elastic IP**: Your site keeps the same IP address forever
- **Separation of Concerns**: Infrastructure, deployment, and application are managed independently

## Setup Guide

### Prerequisites

- AWS Account with admin privileges
- GitHub account (free tier works)

### Step 1: AWS Configuration

#### Required GitHub Secrets

Add these to your repository (Settings → Secrets and variables → Actions):

```
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
```

#### AWS Permissions Required

Your AWS user/role needs these permissions:
- `EC2FullAccess` (manage instances, security groups, key pairs)
- `VPCFullAccess` (network management)
- `ElasticIPManagement` (static IP allocation)

### Step 2: First Deployment

1. Go to **Actions** tab in your GitHub repository
2. Select **"Deploy with Terraform and Docker"**
3. Click **"Run workflow"**
4. Wait for completion (~5 minutes)
5. Your site will be live at the IP shown in the workflow output

## Usage

### 🔄 Updating Your Site

1. Edit `index.html` or any files in your repository
2. Commit and push to main branch
3. GitHub Actions automatically deploys changes
4. Zero-downtime update via Docker containers

### 🛠️ Instance Management

Use the **"Manage Terraform Infrastructure"** workflow for:

| Action | Description | When to Use |
|--------|-------------|-------------|
| **status** | Check instance and container health | Regular monitoring |
| **restart-container** | Restart Docker container (zero-downtime) | App issues, config changes |
| **stop-instance** | Stop EC2 to save costs (preserves data) | Cost optimization |
| **start-instance** | Start stopped instance | Resume after cost savings |
| **restart-instance** | Reboot the server | System-level issues |
| **destroy-infrastructure** | ⚠️ Delete everything (PERMANENT) | Project cleanup |

### 📊 Monitoring & Health Checks

Your deployed site includes:
- **Website**: `http://YOUR_IP/`
- **Health endpoint**: `http://YOUR_IP/health`
- **Container status**: Available via management workflows
- **Automatic monitoring**: Built into all deployments

## Project Structure

```
├── .github/workflows/         # GitHub Actions workflows
│   ├── terraform-deploy.yml   # Main deployment workflow
│   └── terraform-manage.yml   # Instance management
├── terraform/                 # Infrastructure as Code
│   ├── main.tf               # Main Terraform configuration
│   ├── variables.tf          # Input variables
│   ├── outputs.tf            # Output values
│   └── user-data.sh          # Instance initialization script
├── scripts/                   # Deployment utilities
│   ├── deploy.sh             # Application deployment script
│   └── manage.sh             # Container management script
├── css/                      # Stylesheets
├── js/                       # JavaScript files
├── images/                   # Image assets
├── examples/                 # Example projects
└── index.html               # Your website content
```

## Advanced Usage

### SSH Access

Get connection details from workflow output:

```bash
ssh -i your-key.pem ec2-user@YOUR_ELASTIC_IP
```

### Container Management (On EC2)

```bash
# Check status
/opt/static-site/manage.sh status

# Restart container (zero-downtime)
/opt/static-site/manage.sh restart

# View logs
/opt/static-site/manage.sh logs

# Interactive shell in container
/opt/static-site/manage.sh exec
```

### Manual Deployment (On EC2)

```bash
# Deploy new version
cd /opt/static-site
./deploy.sh

# Check deployment status
./deploy.sh status

# Rollback to previous version
./deploy.sh rollback backup-20240101-120000
```

### Terraform Commands (Local)

```bash
cd terraform

# Plan infrastructure changes
terraform plan

# Apply changes
terraform apply

# Destroy infrastructure
terraform destroy
```

## Cost Optimization

### Monthly Costs (US East)

| Resource | Running | Stopped | Notes |
|----------|---------|---------|--------|
| **t3.micro** | ~$7.60 | ~$2.00 | FREE with AWS Free Tier |
| **Elastic IP** | $0.00 | $0.00 | Free when attached |
| **EBS Storage** | ~$2.00 | ~$2.00 | Always charged |
| **Total** | **~$9.60** | **~$4.00** | **FREE** for new AWS accounts |

### Cost-Saving Tips

1. **Use AWS Free Tier**: First 12 months free for new accounts
2. **Stop when not needed**: Use "stop-instance" workflow action
3. **Monitor usage**: Check AWS Cost Explorer regularly
4. **Right-size instances**: t3.micro is perfect for static sites

## Troubleshooting

### Common Issues

| Problem | Solution |
|---------|----------|
| Deployment fails | Check AWS credentials and permissions |
| Site not accessible | Verify security group and instance state |
| Container issues | Use management workflow to check status |
| Terraform errors | Ensure AWS credentials have required permissions |
| SSH access denied | Check key pair configuration in Terraform |

### Debugging Steps

1. **Check workflow logs** in GitHub Actions tab
2. **Use management workflow** to check instance status
3. **SSH to instance** for manual debugging:

```bash
# Check Docker status
docker ps -a

# Check nginx status
curl localhost:8080

# Check system logs
sudo journalctl -f

# Check container logs
docker logs static-site-web
```

### Health Monitoring

The system includes comprehensive health checks:
- **Container health**: Docker container status
- **Application health**: HTTP response testing
- **System health**: Resource usage monitoring
- **Network health**: Connectivity verification

## Security Features

- ✅ **Minimal attack surface**: Only required ports open (80, 443, 22)
- ✅ **Infrastructure as Code**: Auditable and versioned
- ✅ **Automated updates**: Regular security patches via deployment
- ✅ **Container isolation**: Docker provides process isolation
- ✅ **SSH key management**: Automated key generation and cleanup
- ✅ **Network security**: VPC and security group isolation

## Development Workflow

### Local Testing

```bash
# Simple HTTP server
python -m http.server 8000

# With Node.js
npx serve .

# Test with Docker (matches production)
docker run -p 8080:80 -v $(pwd):/usr/share/nginx/html:ro nginx:alpine
```

### Customization

1. **Content**: Edit `index.html`, CSS, and JS files
2. **Infrastructure**: Modify `terraform/*.tf` files
3. **Deployment**: Customize `scripts/*.sh` files
4. **Workflows**: Update `.github/workflows/*.yml` files

### Testing Changes

1. Test locally first
2. Create feature branch for major changes
3. Use pull requests for code review
4. Monitor deployment workflows for issues

## Examples & Templates

Check the [examples/](examples/) directory for:
- Simple portfolio sites
- Multi-page websites
- Custom CSS/JS examples
- Integration patterns

## Migration Guide

### From Old GitHub Actions Only

If you're upgrading from a previous version:

1. **Backup your data**: Export current site files
2. **Run destroy workflow**: Clean up old infrastructure
3. **Update repository**: Pull latest Terraform version
4. **Redeploy**: Use new Terraform-based workflows

### From Other Platforms

1. **Export your site**: Download all static files
2. **Update index.html**: Replace with your content
3. **Configure AWS**: Set up credentials and permissions
4. **Deploy**: Run the deployment workflow

## FAQ

**Q: Can I use my own domain name?**
A: Yes! Point your domain's A record to the Elastic IP address.

**Q: How do I add SSL/HTTPS?**
A: Use AWS Certificate Manager + CloudFront or Let's Encrypt on the instance.

**Q: Can I deploy multiple sites?**
A: Yes! Use different project names in Terraform variables.

**Q: What if I need more resources?**
A: Modify `instance_type` in `terraform/variables.tf` (e.g., t3.small).

**Q: How do I backup my site?**
A: Automatic backups are created on each deployment. Use EBS snapshots for full backups.

## Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Test your changes thoroughly
4. Submit a pull request with detailed description
5. Follow existing code style and conventions

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Support & Community

- 📚 **Documentation**: This README + inline code comments
- 🐛 **Bug Reports**: Submit GitHub issues with full details
- 💡 **Feature Requests**: Create issues with use case descriptions
- 🆘 **Help**: Check workflow logs for detailed error messages
- 💬 **Discussions**: Use GitHub Discussions for questions

---

**Made with ❤️ for developers who want simple, reliable static site hosting.**
