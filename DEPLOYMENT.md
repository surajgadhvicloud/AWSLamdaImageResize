# Deployment Guide

This guide provides detailed instructions for deploying the serverless image resizing pipeline.

## Prerequisites

Before deploying, ensure you have:

1. **AWS Account**: Active AWS account with billing enabled
2. **AWS CLI**: Version 2.x installed and configured
3. **SAM CLI**: Version 1.50 or later
4. **Node.js**: Version 18.x or later
5. **IAM Permissions**: Required permissions for:
   - Lambda (create, update, delete functions and layers)
   - S3 (create, configure buckets)
   - CloudFormation (create, update stacks)
   - IAM (create roles and policies)
   - CloudWatch Logs (create log groups)

## Installation Steps

### Step 1: Configure AWS CLI

```bash
# Configure AWS credentials
aws configure

# Verify configuration
aws sts get-caller-identity
```

### Step 2: Install SAM CLI

**macOS (Homebrew):**
```bash
brew install aws-sam-cli
```

**Linux:**
```bash
# Download the installer
wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
sudo ./sam-installation/install
```

**Windows:**
Download from [AWS SAM CLI releases](https://github.com/aws/aws-sam-cli/releases)

### Step 3: Clone Repository

```bash
git clone <repository-url>
cd AWSLamdaImageResize
```

### Step 4: Configure Deployment

Create a deployment configuration file (optional):

```bash
# Create config file
cat > deploy-config.env << EOF
STACK_NAME=my-image-resize-stack
AWS_REGION=us-east-1
SOURCE_BUCKET_NAME=my-images-source
DESTINATION_BUCKET_NAME=my-images-resized
RESIZE_WIDTH=1024
RESIZE_HEIGHT=768
IMAGE_QUALITY=85
EOF
```

### Step 5: Deploy

```bash
# Load configuration
source deploy-config.env

# Deploy the stack
./scripts/deploy.sh
```

## Deployment Options

### Option 1: Default Deployment

Uses default configuration values:

```bash
./scripts/deploy.sh
```

### Option 2: Custom Configuration

Specify custom parameters:

```bash
STACK_NAME=prod-image-resize \
AWS_REGION=us-west-2 \
SOURCE_BUCKET_NAME=prod-source \
DESTINATION_BUCKET_NAME=prod-destination \
RESIZE_WIDTH=1920 \
RESIZE_HEIGHT=1080 \
IMAGE_QUALITY=90 \
./scripts/deploy.sh
```

### Option 3: Using SAM CLI Directly

```bash
# Build
sam build

# Deploy with guided mode
sam deploy --guided

# Or deploy with parameters
sam deploy \
  --stack-name image-resize-stack \
  --region us-east-1 \
  --capabilities CAPABILITY_IAM \
  --parameter-overrides \
    SourceBucketName=my-source \
    DestinationBucketName=my-destination
```

## Post-Deployment Verification

### 1. Check Stack Status

```bash
aws cloudformation describe-stacks \
  --stack-name image-resize-stack \
  --query 'Stacks[0].StackStatus'
```

Expected output: `CREATE_COMPLETE` or `UPDATE_COMPLETE`

### 2. Verify Resources

```bash
# List stack resources
aws cloudformation describe-stack-resources \
  --stack-name image-resize-stack

# Check Lambda function
aws lambda get-function --function-name ImageResizeFunction

# Verify S3 buckets
aws s3 ls | grep image-resize
```

### 3. Test the Pipeline

```bash
# Create a test image (requires ImageMagick)
convert -size 1920x1080 xc:blue test-image.jpg

# Upload and test
./scripts/test.sh test-image.jpg
```

## Troubleshooting Deployment

### Issue: "Bucket already exists"

**Problem**: S3 bucket names must be globally unique.

**Solution**: Use a unique bucket name:
```bash
SOURCE_BUCKET_NAME=my-unique-source-$(date +%s) \
DESTINATION_BUCKET_NAME=my-unique-dest-$(date +%s) \
./scripts/deploy.sh
```

### Issue: "Insufficient permissions"

**Problem**: IAM user/role lacks required permissions.

**Solution**: Ensure your IAM user has these managed policies:
- `AWSLambda_FullAccess`
- `AmazonS3FullAccess`
- `CloudFormationFullAccess`
- `IAMFullAccess` (or custom policy for role creation)

### Issue: "Layer build fails"

**Problem**: Sharp layer build fails due to architecture mismatch.

**Solution**: Build the layer with correct architecture:
```bash
cd layer
docker run --rm -v "$PWD":/var/task \
  public.ecr.aws/lambda/nodejs:18 \
  npm install --arch=x64 --platform=linux sharp
```

### Issue: "Stack rollback"

**Problem**: Deployment fails and stack rolls back.

**Solution**:
1. Check CloudFormation events:
   ```bash
   aws cloudformation describe-stack-events \
     --stack-name image-resize-stack \
     --max-items 10
   ```
2. Fix the issue and redeploy
3. Or delete the stack and start fresh:
   ```bash
   ./scripts/cleanup.sh
   ```

## Multi-Environment Deployment

### Development Environment

```bash
STACK_NAME=dev-image-resize \
AWS_REGION=us-east-1 \
SOURCE_BUCKET_NAME=dev-images-source \
DESTINATION_BUCKET_NAME=dev-images-dest \
RESIZE_WIDTH=800 \
RESIZE_HEIGHT=600 \
./scripts/deploy.sh
```

### Production Environment

```bash
STACK_NAME=prod-image-resize \
AWS_REGION=us-east-1 \
SOURCE_BUCKET_NAME=prod-images-source \
DESTINATION_BUCKET_NAME=prod-images-dest \
RESIZE_WIDTH=1920 \
RESIZE_HEIGHT=1080 \
IMAGE_QUALITY=95 \
./scripts/deploy.sh
```

## Updating the Stack

To update an existing deployment:

```bash
# Make code changes
# ...

# Redeploy
./scripts/deploy.sh
```

SAM will automatically detect changes and update only modified resources.

## Rollback

If deployment fails, CloudFormation automatically rolls back. To manually rollback:

```bash
# Rollback to previous version
aws cloudformation cancel-update-stack \
  --stack-name image-resize-stack
```

## Cleanup

To completely remove the deployment:

```bash
./scripts/cleanup.sh
```

This removes all resources including:
- Lambda function
- Lambda layer
- S3 buckets (after emptying)
- CloudWatch log groups
- IAM roles

## Best Practices

1. **Use version control**: Commit all configuration changes
2. **Tag resources**: Add tags for cost tracking and organization
3. **Monitor costs**: Enable AWS Cost Explorer
4. **Set up alarms**: Create CloudWatch alarms for errors and throttling
5. **Regular backups**: Backup important images before processing
6. **Test in dev first**: Always test changes in development environment
7. **Document changes**: Keep deployment notes and configurations

## Next Steps

After successful deployment:

1. Upload test images to source bucket
2. Monitor CloudWatch logs
3. Verify resized images in destination bucket
4. Set up CloudWatch alarms
5. Configure lifecycle policies for S3 buckets
6. Implement backup strategy
7. Document operational procedures

## Support

For deployment issues:
- Check CloudFormation events
- Review CloudWatch logs
- Consult AWS documentation
- Open an issue on GitHub
