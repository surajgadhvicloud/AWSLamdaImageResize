#!/bin/bash

# Deployment script for Image Resizing Pipeline
# This script deploys the SAM application to AWS

set -e

echo "=========================================="
echo "Image Resizing Pipeline - Deployment"
echo "=========================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "Error: SAM CLI is not installed. Please install it first."
    echo "Visit: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html"
    exit 1
fi

# Configuration
STACK_NAME="${STACK_NAME:-image-resize-stack}"
REGION="${AWS_REGION:-us-east-1}"
S3_BUCKET="${DEPLOYMENT_BUCKET:-sam-deployment-bucket-$(aws sts get-caller-identity --query Account --output text)}"

echo "Configuration:"
echo "  Stack Name: $STACK_NAME"
echo "  Region: $REGION"
echo "  Deployment Bucket: $S3_BUCKET"
echo ""

# Build the Lambda Layer
echo "Step 1: Building Lambda Layer..."
cd layer
if [ ! -d "nodejs" ]; then
    bash build-layer.sh
fi
cd ..

# Install Lambda dependencies
echo "Step 2: Installing Lambda dependencies..."
cd lambda
npm install
cd ..

# Build SAM application
echo "Step 3: Building SAM application..."
sam build

# Deploy SAM application
echo "Step 4: Deploying to AWS..."
sam deploy \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --s3-bucket "$S3_BUCKET" \
    --capabilities CAPABILITY_IAM \
    --no-fail-on-empty-changeset \
    --parameter-overrides \
        SourceBucketName="${SOURCE_BUCKET_NAME:-image-resize-source-bucket}" \
        DestinationBucketName="${DESTINATION_BUCKET_NAME:-image-resize-destination-bucket}" \
        ResizeWidth="${RESIZE_WIDTH:-800}" \
        ResizeHeight="${RESIZE_HEIGHT:-600}" \
        ImageQuality="${IMAGE_QUALITY:-80}"

echo ""
echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Upload a test image to the source bucket"
echo "2. Check CloudWatch Logs for Lambda execution"
echo "3. Verify resized image in destination bucket"
echo ""
echo "To get stack outputs:"
echo "aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION --query 'Stacks[0].Outputs'"
