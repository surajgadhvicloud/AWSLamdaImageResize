#!/bin/bash

# Script to clean up AWS resources
# WARNING: This will delete all resources created by the stack

set -e

echo "=========================================="
echo "Image Resizing Pipeline - Cleanup"
echo "=========================================="

# Configuration
STACK_NAME="${STACK_NAME:-image-resize-stack}"
REGION="${AWS_REGION:-us-east-1}"

echo "WARNING: This will delete the following:"
echo "  - Lambda Function and Layer"
echo "  - S3 Buckets (and all their contents)"
echo "  - CloudWatch Log Groups"
echo ""
echo "Stack Name: $STACK_NAME"
echo "Region: $REGION"
echo ""
read -p "Are you sure you want to continue? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Get bucket names before deleting stack
echo "Fetching bucket names..."
SOURCE_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`SourceBucketName`].OutputValue' \
    --output text 2>/dev/null || echo "")

DESTINATION_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`DestinationBucketName`].OutputValue' \
    --output text 2>/dev/null || echo "")

# Empty S3 buckets before deletion
if [ -n "$SOURCE_BUCKET" ]; then
    echo "Emptying source bucket: $SOURCE_BUCKET"
    aws s3 rm "s3://$SOURCE_BUCKET" --recursive --region "$REGION" 2>/dev/null || true
fi

if [ -n "$DESTINATION_BUCKET" ]; then
    echo "Emptying destination bucket: $DESTINATION_BUCKET"
    aws s3 rm "s3://$DESTINATION_BUCKET" --recursive --region "$REGION" 2>/dev/null || true
fi

# Delete CloudFormation stack
echo "Deleting CloudFormation stack..."
aws cloudformation delete-stack \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

echo "Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete \
    --stack-name "$STACK_NAME" \
    --region "$REGION"

echo ""
echo "=========================================="
echo "Cleanup Complete!"
echo "=========================================="
