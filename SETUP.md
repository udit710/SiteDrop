# SiteDrop Setup Guide 🛠️

This guide walks you through setting up SiteDrop from scratch, including AWS configuration and GitHub setup.

## Prerequisites

- AWS Account (free tier works)
- GitHub Account
- Basic familiarity with Git

## 📋 Step-by-Step Setup

### Step 1: Fork the Repository

1. Go to the [SiteDrop repository](https://github.com/udit710/SiteDrop)
2. Click the **"Fork"** button in the top-right corner
3. Choose your GitHub account as the destination
4. Wait for the fork to complete

### Step 2: AWS IAM Setup

#### 2.1 Create IAM User

1. Log into [AWS Console](https://console.aws.amazon.com/)
2. Navigate to **IAM** → **Users** → **Create user**
3. Enter username: `sitedrop-deployer` (or any name you prefer)
4. Select **"Provide user access to the AWS Management Console"** - **NOT required**
5. Click **"Next"**

#### 2.2 Attach Permissions

1. Choose **"Attach policies directly"**
2. Click **"Create policy"** to create a custom policy
3. In the policy editor, select **"JSON"** tab
4. Replace the default policy with this **SiteDrop policy**:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "SiteDropFullAccess",
            "Effect": "Allow",
            "Action": [
                "s3:*",
                "cloudfront:*",
                "iam:*",
                "dynamodb:*"
            ],
            "Resource": "*"
        }
    ]
}
```

5. Click **"Next"**
6. Enter policy name: `SiteDropDeploymentPolicy`
7. Enter description: `Full access policy for SiteDrop static site deployment`
8. Click **"Create policy"**
9. Go back to user creation, refresh policies, and search for `SiteDropDeploymentPolicy`
10. Select the policy and click **"Next"**
11. Click **"Create user"**

#### 2.3 Generate Access Keys

1. In the IAM Users list, click on your newly created user
2. Navigate to **"Security credentials"** tab
3. Scroll down to **"Access keys"** section
4. Click **"Create access key"**
5. Select **"Command Line Interface (CLI)"**
6. Check the confirmation checkbox
7. Click **"Next"**
8. Add description: `SiteDrop GitHub Actions deployment`
9. Click **"Create access key"**
10. **IMPORTANT**: Copy and save both:
    - **Access key ID**
    - **Secret access key**

⚠️ **Security Note**: Never commit these keys to your repository or share them publicly.

### Step 3: GitHub Personal Access Token (PAT)

#### 3.1 Create Fine-Grained PAT

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens**
2. Click **"Generate new token"**
3. Configure the token:
   - **Token name**: `SiteDrop Repository Update`
   - **Expiration**: 90 days (or longer as preferred)
   - **Resource owner**: Select your account
   - **Repository access**: Select your forked SiteDrop repository

#### 3.2 Set Repository Permissions

In the **"Repository permissions"** section, grant these permissions:

| Permission | Access Level | Why Needed |
|------------|--------------|------------|
| **Administration** | **Write** | Update repository description with live URL |
| **Contents** | Read | Access repository files |
| **Metadata** | Read | Access repository information |

#### 3.3 Generate Token

1. Click **"Generate token"**
2. **IMPORTANT**: Copy and save the token immediately
3. You won't be able to see it again!

### Step 4: Configure GitHub Secrets

#### 4.1 Add Repository Secrets

1. Go to your forked repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"** for each of the following:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key ID | From Step 2.3 |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret access key | From Step 2.3 |
| `GH_PAT` | Your GitHub fine-grained PAT | From Step 3.3 |

#### 4.2 Verify Secrets

After adding all secrets, you should see:
- ✅ `AWS_ACCESS_KEY_ID`
- ✅ `AWS_SECRET_ACCESS_KEY`
- ✅ `GH_PAT`

### Step 5: Prepare Your Website

#### 5.1 Clone Your Fork

```bash
git clone https://github.com/YOUR_USERNAME/SiteDrop.git
cd SiteDrop
```

#### 5.2 Replace Default Content

The `site/` directory contains a sample portfolio. Replace it with your content:

```
site/
├── index.html          # Your main page (required)
├── style.css          # Your stylesheets
├── main.js           # Your JavaScript
├── images/           # Your images
├── assets/           # Other assets
└── [other files]     # Any other static files
```

**Requirements**:
- Must have `index.html` as the main page
- All files must be static (no server-side processing)
- Recommended: Keep total size under 100MB for fast uploads

#### 5.3 Test Locally (Optional)

```bash
# Simple HTTP server with Python
cd site/
python -m http.server 8000

# Or with Node.js
npx serve .

# Open http://localhost:8000 in your browser
```

### Step 6: Deploy Your Site

#### 6.1 Push Your Changes

```bash
git add .
git commit -m "Add my website content"
git push origin main
```

#### 6.2 Monitor Deployment

1. Go to your repository on GitHub
2. Click the **"Actions"** tab
3. You should see a **"Deploy SiteDrop"** workflow running
4. Click on the workflow to see detailed logs
5. Wait for completion (usually 3-5 minutes)

#### 6.3 Get Your Live URL

After successful deployment, check:
1. The workflow output for your live URL
2. Your repository description (should be updated automatically)
3. The URL format: `https://d[random].cloudfront.net`

## 🔧 Advanced Configuration

### Custom Domain Setup

After deployment, you can use your own domain:

1. **Get CloudFront URL** from deployment output
2. **Create DNS record**:
   - **CNAME**: `www.yourdomain.com` → `d1234567890.cloudfront.net`
   - **ALIAS/ANAME**: `yourdomain.com` → CloudFront URL (if supported)

### SSL Certificate (Custom Domain)

For custom domains with SSL:
1. Go to AWS Certificate Manager
2. Request certificate for your domain
3. Update CloudFront distribution to use the certificate

### Environment Variables

You can customize deployment by adding these optional secrets:

| Secret Name | Default | Description |
|-------------|---------|-------------|
| `AWS_REGION` | `us-east-1` | AWS region for resources |
| `PROJECT_NAME` | `sitedrop` | Prefix for AWS resource names |

## 📊 Cost Management

### Monitoring Costs

1. **AWS Cost Explorer**: Track actual usage
2. **CloudWatch**: Monitor CloudFront requests
3. **S3 Storage Lens**: Analyze storage usage

### Cost Optimization Tips

- **Compress files** before uploading (gzip, webp images)
- **Optimize images** to reduce S3 storage costs
- **Use CloudFront caching** effectively (default settings are good)
- **Monitor usage** regularly via AWS Cost Explorer

## 🔒 Security Best Practices

### AWS Security

- ✅ Use least-privilege IAM policy (provided above)
- ✅ Rotate access keys regularly (every 90 days)
- ✅ Enable CloudTrail for API logging
- ✅ Monitor AWS Config for compliance

### GitHub Security

- ✅ Use fine-grained PATs with minimal permissions
- ✅ Set PAT expiration dates
- ✅ Regularly review repository access
- ✅ Enable two-factor authentication

### Content Security

- ✅ Never commit sensitive data to the repository
- ✅ Use environment variables for configuration
- ✅ Scan dependencies for vulnerabilities
- ✅ Keep dependencies updated

## 🔍 Troubleshooting

### Common Setup Issues

| Issue | Solution |
|-------|----------|
| **AWS credentials invalid** | Verify access key ID and secret access key |
| **Insufficient permissions** | Ensure IAM policy includes all required actions |
| **GitHub PAT invalid** | Check PAT has Administration write permissions |
| **Repository access denied** | Verify PAT is scoped to correct repository |
| **Deployment fails** | Check GitHub Actions logs for detailed error |

### AWS Permission Errors

If you see permission errors, verify your IAM user has:
- `s3:*` permissions for S3 operations
- `cloudfront:*` permissions for CDN management
- `iam:*` permissions for role management (OAI)
- `dynamodb:*` permissions for state locking

### GitHub Actions Errors

Common errors and solutions:

```bash
# Error: AWS credentials not found
# Solution: Check AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets

# Error: Repository update failed
# Solution: Verify GH_PAT has Administration write permissions

# Error: Terraform state locked
# Solution: Wait for previous deployment to complete or check DynamoDB table
```

### Getting Help

1. **Check workflow logs**: Detailed error messages in GitHub Actions
2. **AWS CloudTrail**: See what API calls were made
3. **Create GitHub issue**: Include error logs and setup details
4. **GitHub Discussions**: Ask questions and get community help

## 🔄 Updating SiteDrop

To update SiteDrop itself (not your website):

1. **Check for updates** in the original repository
2. **Sync your fork**:
   ```bash
   git remote add upstream https://github.com/udit710/SiteDrop.git
   git fetch upstream
   git merge upstream/main
   git push origin main
   ```
3. **Test deployment** after updates

## 🗑️ Cleanup

### Destroy Infrastructure

To completely remove all AWS resources:

1. Go to **Actions** tab in your repository
2. Select **"Destroy SiteDrop Infra"** workflow
3. Click **"Run workflow"** → **"Run workflow"**
4. Confirm destruction in the workflow

### Remove GitHub Resources

1. **Delete repository** (if no longer needed)
2. **Revoke PAT**: Settings → Developer settings → Personal access tokens
3. **Remove AWS user**: IAM → Users → Delete user

---

## ✅ Setup Checklist

- [ ] AWS account created
- [ ] IAM user created with SiteDrop policy
- [ ] AWS access keys generated and saved
- [ ] GitHub fine-grained PAT created with Administration write permissions
- [ ] Repository forked
- [ ] GitHub secrets configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, GH_PAT)
- [ ] Website content added to `site/` directory
- [ ] Changes committed and pushed to main branch
- [ ] Deployment workflow completed successfully
- [ ] Live URL received and verified

**Congratulations! Your static website is now live on AWS CloudFront! 🎉**
