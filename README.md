# AWS Lambda Image Resize

A serverless image resizing pipeline using AWS Lambda, Lambda Layers, and S3 Event Triggers. This solution automatically resizes images uploaded to an S3 bucket using the Sharp image processing library.

## Architecture

```
┌─────────────────┐     S3 Event      ┌──────────────────┐     Resized      ┌────────────────────┐
│   Source S3     │ ──Trigger──────▶  │  Lambda Function │ ───Image───────▶ │  Destination S3    │
│    Bucket       │                    │  (with Sharp)    │                   │     Bucket         │
└─────────────────┘                    └──────────────────┘                   └────────────────────┘
                                              │
                                              │ Uses
                                              ▼
                                       ┌──────────────┐
                                       │ Lambda Layer │
                                       │   (Sharp)    │
                                       └──────────────┘
                                              │
                                              │ Logs
                                              ▼
                                       ┌──────────────┐
                                       │  CloudWatch  │
                                       │    Logs      │
                                       └──────────────┘
```

## Features

- **Event-Driven**: Automatically triggered when images are uploaded to S3
- **Serverless**: No server management required, scales automatically
- **Cost-Effective**: Pay only for what you use
- **Fast Processing**: Low-latency image resizing using Sharp
- **Multiple Formats**: Supports JPEG, PNG, and WebP formats
- **Configurable**: Adjustable dimensions, quality, and output settings
- **Monitoring**: Complete logging via CloudWatch

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured with credentials
- AWS SAM CLI installed ([Installation Guide](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html))
- Node.js 18.x or later
- Bash shell (for deployment scripts)

## Project Structure

```
.
├── lambda/                    # Lambda function code
│   ├── index.js              # Main handler for image resizing
│   └── package.json          # Lambda dependencies
├── layer/                     # Lambda Layer for Sharp
│   ├── package.json          # Layer dependencies
│   └── build-layer.sh        # Script to build the layer
├── scripts/                   # Deployment and testing scripts
│   ├── deploy.sh             # Deploy the stack to AWS
│   ├── test.sh               # Test the pipeline
│   └── cleanup.sh            # Clean up AWS resources
├── template.yaml             # SAM/CloudFormation template
└── README.md                 # This file
```

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd AWSLamdaImageResize
```

### 2. Deploy the Stack

```bash
# Basic deployment with default settings
./scripts/deploy.sh

# Or with custom parameters
STACK_NAME=my-image-resize \
AWS_REGION=us-west-2 \
SOURCE_BUCKET_NAME=my-source-bucket \
DESTINATION_BUCKET_NAME=my-destination-bucket \
RESIZE_WIDTH=1024 \
RESIZE_HEIGHT=768 \
IMAGE_QUALITY=85 \
./scripts/deploy.sh
```

### 3. Test the Pipeline

```bash
# Upload a test image
./scripts/test.sh path/to/your/test-image.jpg

# Or manually upload using AWS CLI
aws s3 cp test-image.jpg s3://your-source-bucket/
```

### 4. Monitor Execution

```bash
# View CloudWatch logs
aws logs tail /aws/lambda/ImageResizeFunction --follow

# Check resized images
aws s3 ls s3://your-destination-bucket/
```

## Configuration

The solution can be configured via environment variables or CloudFormation parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `SourceBucketName` | `image-resize-source-bucket` | Source S3 bucket name |
| `DestinationBucketName` | `image-resize-destination-bucket` | Destination S3 bucket name |
| `ResizeWidth` | `800` | Target width in pixels |
| `ResizeHeight` | `600` | Target height in pixels |
| `ImageQuality` | `80` | Image quality (1-100) |

## Lambda Function Details

### Handler: `index.handler`

The Lambda function:
1. Receives S3 event notifications when images are uploaded
2. Downloads the image from the source bucket
3. Resizes the image using Sharp with configured dimensions
4. Maintains aspect ratio (fit inside dimensions)
5. Applies quality compression based on format
6. Uploads the resized image to the destination bucket
7. Stores metadata about the resizing operation

### Environment Variables

- `DESTINATION_BUCKET`: Destination S3 bucket name
- `RESIZE_WIDTH`: Target width for resized images
- `RESIZE_HEIGHT`: Target height for resized images
- `IMAGE_QUALITY`: Image quality setting (1-100)

### Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- WebP (.webp)

## Lambda Layer

The Sharp library is packaged as a Lambda Layer for:
- Reduced deployment package size
- Reusability across multiple functions
- Easier updates and version management

### Building the Layer

```bash
cd layer
./build-layer.sh
cd nodejs
zip -r ../sharp-layer.zip .
```

## Performance Considerations

- **Memory**: Function configured with 1024 MB (adjustable based on image sizes)
- **Timeout**: 300 seconds (5 minutes) maximum execution time
- **Concurrency**: Automatically scales based on incoming events
- **Cold Starts**: Minimized by keeping function warm with periodic invocations

## Cost Estimation

Approximate costs (US East 1 region):
- Lambda execution: $0.20 per 1M requests + $0.0000166667 per GB-second
- S3 storage: $0.023 per GB/month
- S3 requests: $0.005 per 1,000 PUT requests
- Data transfer: First 1 GB/month free

Example: Processing 10,000 images/month with 1024MB memory and 5-second execution:
- Lambda: ~$8.50/month
- S3: Varies based on storage

## Monitoring and Logging

### CloudWatch Logs

All Lambda executions are logged to CloudWatch:

```bash
# View logs
aws logs tail /aws/lambda/ImageResizeFunction --follow

# Filter errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/ImageResizeFunction \
  --filter-pattern "ERROR"
```

### Metrics

Monitor these CloudWatch metrics:
- `Invocations`: Number of times Lambda was invoked
- `Duration`: Execution time per invocation
- `Errors`: Number of failed invocations
- `Throttles`: Number of throttled invocations

## Troubleshooting

### Common Issues

1. **Lambda timeout**
   - Solution: Increase memory allocation or timeout limit
   - Large images may need more processing time

2. **Permission denied errors**
   - Solution: Verify IAM roles have correct S3 permissions
   - Check bucket policies

3. **Sharp module not found**
   - Solution: Ensure Lambda Layer is correctly attached
   - Verify Layer is compatible with Lambda runtime

4. **Infinite loop (Lambda triggering itself)**
   - Solution: Source and destination buckets must be different
   - Function checks for this condition automatically

### Debug Mode

Enable detailed logging by adding to Lambda environment:
```bash
NODE_ENV=development
```

## Security Best Practices

- S3 buckets have public access blocked by default
- Lambda execution role follows least privilege principle
- CloudWatch logs retention set to 7 days (adjustable)
- Use VPC endpoints for private network access (optional)

## Cleanup

To remove all resources:

```bash
./scripts/cleanup.sh
```

This will delete:
- Lambda function and layer
- S3 buckets (after emptying them)
- CloudWatch log groups
- IAM roles and policies

## Advanced Usage

### Custom Resize Logic

Modify `lambda/index.js` to implement custom resizing logic:

```javascript
// Example: Multiple sizes
const sizes = [
  { width: 400, height: 300, suffix: '-small' },
  { width: 800, height: 600, suffix: '-medium' },
  { width: 1600, height: 1200, suffix: '-large' }
];
```

### Additional Image Formats

Add support for more formats by updating the S3 notification configuration in `template.yaml`.

### Error Handling

Implement Dead Letter Queue (DLQ) for failed invocations:

```yaml
DeadLetterQueue:
  Type: SQS
  TargetArn: !GetAtt DLQueue.Arn
```

## Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - See LICENSE file for details

## Support

For issues and questions:
- Open an issue on GitHub
- Check CloudWatch logs for error details
- Review AWS Lambda documentation

## Additional Resources

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [AWS SAM Documentation](https://docs.aws.amazon.com/serverless-application-model/)
- [Sharp Documentation](https://sharp.pixelplumbing.com/)
- [S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html)

## Acknowledgments

- Sharp library by Lovell Fuller
- AWS Serverless Application Model team
- Open source community 
