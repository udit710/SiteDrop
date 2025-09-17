# Detailed Setup Guide

## Prerequisites

1. **AWS Account** with the following permissions:
   - EC2 (launch instances, manage security groups, key pairs)
   - Basic IAM permissions for the access key

2. **GitHub Repository** with Actions enabled

## Step-by-Step Setup

### 1. Fork the Repository
Click the "Fork" button on GitHub to create your own copy.

### 2. AWS IAM Setup
Create an IAM user with programmatic access:

1. Go to AWS Console → IAM → Users → Add User
2. Choose "Programmatic access"
3. Attach the policy: `AmazonEC2FullAccess` (or create a custom policy with minimal permissions)
4. Save the Access Key ID and Secret Access Key

### 3. GitHub Secrets Configuration
In your forked repository:

1. Go to Settings → Secrets and variables → Actions
2. Add these repository secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `AWS_REGION`: Your preferred region (optional, defaults to us-east-1)

### 4. Customize Your Site
Replace the default `index.html` with your own content. You can also add:
- CSS files in a `css/` directory
- JavaScript files in a `js/` directory
- Images in an `images/` or `assets/` directory
- Any other static files

### 5. Deploy
Push your changes to the main branch:
```bash
git add .
git commit -m "Add my static site"
git push origin main
```

## First Deployment
The GitHub Action will automatically:
1. Create an EC2 instance (if none exists)
2. Set up security group and SSH key
3. Install and configure nginx
4. Deploy your static files
5. Output the public URL

## Subsequent Updates
For future changes:
1. Update your files locally
2. Commit and push to main branch
3. GitHub Actions will:
   - Find your existing instance
   - Update the files (with backup)
   - Reload nginx
   - Test the deployment

## Managing Your Instance

### Using GitHub Actions UI
1. Go to your repository's "Actions" tab
2. Select "Manage EC2 Instance" workflow
3. Click "Run workflow" and choose an action:
   - **Status**: Check instance state and site accessibility
   - **Stop**: Stop instance to save costs (preserves data)
   - **Start**: Start stopped instance (may get new IP)
   - **Restart**: Reboot running instance
   - **Terminate**: Permanently destroy instance

### Cost Management
- **Stop when not needed**: Reduces costs to ~$1/month (storage only)
- **Start when needed**: Resume with all your data intact
- **Monitor in AWS Console**: Track actual usage and costs

## Configuration Options

### Instance Type
Edit `.github/workflows/deploy.yml` and change the `INSTANCE_TYPE` environment variable:
```yaml
env:
  INSTANCE_TYPE: t3.micro  # or t2.small, t3.small, etc.
```

### AWS Region
Change the `AWS_REGION` environment variable or add it as a repository secret.

### Custom Domain (Advanced)
After deployment, you can:
1. Point your domain's A record to the instance's public IP
2. Configure SSL with Let's Encrypt (manual setup required)

## Cost Considerations

- **t2.micro**: Free tier eligible (750 hours/month)
- **Storage**: ~$1/month for 8GB EBS volume
- **Data transfer**: First 1GB/month free, then $0.09/GB
- **Instance hours**: After free tier, ~$8.50/month for t2.micro

## Troubleshooting

### Deployment Fails
1. Check GitHub Actions logs for specific errors
2. Verify AWS credentials are correct
3. Ensure your AWS account has EC2 permissions

### Site Not Accessible
1. Check if the instance is running in AWS Console
2. Verify security group allows HTTP traffic on port 80
3. Check nginx status: SSH to instance and run `sudo systemctl status nginx`

### SSH Issues
The workflow creates temporary SSH keys. If you need persistent access:
1. Create a permanent key pair in AWS Console
2. Update the workflow to use your key pair name

## Security Notes

- The instance allows HTTP traffic from anywhere (0.0.0.0/0)
- SSH access is temporarily enabled during deployment
- Consider using HTTPS for production sites
- The security group is created per deployment for isolation

## Instance Lifecycle Management

### Smart Cost Control
The new CI/CD approach gives you flexible cost control:

- **Development**: Stop instance when not actively developing
- **Production**: Keep running for 24/7 availability
- **Staging**: Start only when testing changes

### Cleanup Options

#### Temporary Shutdown (Recommended)
Use the "Manage EC2 Instance" workflow to stop the instance:
- Preserves all data and configuration
- Costs only ~$1/month for storage
- Can be restarted anytime

#### Permanent Cleanup
Use the "Manage EC2 Instance" workflow to terminate:
- Permanently destroys instance and data
- Stops all charges except for security group (free)
- Cannot be undone - you'll need to redeploy from scratch

#### Manual Cleanup (AWS Console)
If needed, you can also manage via AWS Console:
1. Go to AWS Console → EC2 → Instances
2. Select your instance and choose "Stop" or "Terminate"
3. Optionally delete security group "static-site-sg"
4. Optionally delete key pair "static-site-key"