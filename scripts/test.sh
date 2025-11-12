#!/bin/bash

# Script to test the Image Resizing Pipeline
# This script uploads a test image to the source bucket and verifies processing

set -e

echo "=========================================="
echo "Image Resizing Pipeline - Test Script"
echo "=========================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Configuration
STACK_NAME="${STACK_NAME:-image-resize-stack}"
REGION="${AWS_REGION:-us-east-1}"

# Get stack outputs
echo "Fetching stack information..."
SOURCE_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`SourceBucketName`].OutputValue' \
    --output text)

DESTINATION_BUCKET=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`DestinationBucketName`].OutputValue' \
    --output text)

if [ -z "$SOURCE_BUCKET" ] || [ -z "$DESTINATION_BUCKET" ]; then
    echo "Error: Could not retrieve bucket names from stack outputs."
    echo "Please ensure the stack is deployed successfully."
    exit 1
fi

echo "Source Bucket: $SOURCE_BUCKET"
echo "Destination Bucket: $DESTINATION_BUCKET"
echo ""

# Check if test image is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-test-image>"
    echo ""
    echo "Example:"
    echo "  $0 test-images/sample.jpg"
    echo ""
    echo "You can also create a test image using ImageMagick:"
    echo "  convert -size 1920x1080 xc:blue test-image.jpg"
    exit 1
fi

TEST_IMAGE="$1"

if [ ! -f "$TEST_IMAGE" ]; then
    echo "Error: Test image not found: $TEST_IMAGE"
    exit 1
fi

IMAGE_NAME=$(basename "$TEST_IMAGE")

echo "Uploading test image: $IMAGE_NAME"
aws s3 cp "$TEST_IMAGE" "s3://$SOURCE_BUCKET/$IMAGE_NAME" --region "$REGION"

echo ""
echo "Image uploaded successfully!"
echo "Waiting for Lambda to process the image (30 seconds)..."
sleep 30

echo ""
echo "Checking if resized image exists in destination bucket..."
if aws s3 ls "s3://$DESTINATION_BUCKET/$IMAGE_NAME" --region "$REGION" &> /dev/null; then
    echo "✓ Success! Resized image found in destination bucket"
    
    # Get image metadata
    echo ""
    echo "Image metadata:"
    aws s3api head-object \
        --bucket "$DESTINATION_BUCKET" \
        --key "$IMAGE_NAME" \
        --region "$REGION" \
        --query 'Metadata' \
        --output json
    
    echo ""
    echo "To download the resized image:"
    echo "aws s3 cp s3://$DESTINATION_BUCKET/$IMAGE_NAME resized-$IMAGE_NAME --region $REGION"
else
    echo "✗ Resized image not found in destination bucket"
    echo "Checking Lambda logs for errors..."
    
    FUNCTION_NAME=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`ImageResizeFunctionArn`].OutputValue' \
        --output text | awk -F':' '{print $NF}')
    
    echo "Fetching recent logs for function: $FUNCTION_NAME"
    aws logs tail "/aws/lambda/$FUNCTION_NAME" --region "$REGION" --follow
fi
