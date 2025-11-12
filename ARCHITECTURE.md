# Architecture Overview

## System Architecture

The serverless image resizing pipeline is built using AWS managed services to provide a scalable, cost-effective solution for automatic image optimization.

## Components

### 1. Source S3 Bucket

**Purpose**: Storage for original, high-resolution images

**Configuration**:
- Event notifications enabled for object creation
- Public access blocked for security
- Versioning optional (recommended for production)

**Events Triggered**:
- `s3:ObjectCreated:*` for `.jpg`, `.jpeg`, `.png`, `.webp` files

### 2. AWS Lambda Function

**Purpose**: Process and resize images

**Runtime**: Node.js 18.x

**Key Features**:
- Triggered automatically by S3 events
- Uses Sharp library via Lambda Layer
- Configurable resize dimensions and quality
- Error handling and logging
- Prevents infinite loops (source/dest bucket check)

**Execution Flow**:
```
1. Receive S3 event notification
2. Download image from source bucket
3. Resize image using Sharp
4. Apply compression based on format
5. Upload to destination bucket
6. Log results to CloudWatch
```

**Resource Allocation**:
- Memory: 1024 MB (adjustable)
- Timeout: 300 seconds (5 minutes)
- Ephemeral storage: 512 MB (default)

### 3. Lambda Layer (Sharp)

**Purpose**: Provide Sharp image processing library

**Why a Layer?**:
- Reduces deployment package size
- Enables sharing across multiple functions
- Simplifies dependency management
- Faster deployments

**Contents**:
- Sharp npm package (compiled for Linux x64)
- Native dependencies (libvips)

**Size**: ~30-40 MB (varies by version)

### 4. Destination S3 Bucket

**Purpose**: Storage for resized, optimized images

**Configuration**:
- Public access blocked by default
- Metadata stored with each image
- Lifecycle policies optional (for archival)

**Metadata Stored**:
- Original image size
- Resized image size
- Resize dimensions used
- Compression ratio achieved

### 5. CloudWatch Logs

**Purpose**: Monitoring and debugging

**Log Groups**:
- `/aws/lambda/ImageResizeFunction`

**Information Logged**:
- Function invocations
- Processing time
- Image sizes (before/after)
- Errors and exceptions
- Compression ratios

**Retention**: 7 days (configurable)

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                        User/Application                          │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                │ 1. Upload Image
                                ▼
                    ┌───────────────────────┐
                    │   Source S3 Bucket    │
                    │  (Original Images)    │
                    └───────────┬───────────┘
                                │
                                │ 2. S3 Event Notification
                                ▼
                    ┌───────────────────────┐
                    │   Lambda Function     │◄───── Lambda Layer
                    │   (Image Processor)   │       (Sharp)
                    └───────────┬───────────┘
                                │
                                │ 3. Store Resized Image
                                ▼
                    ┌───────────────────────┐
                    │ Destination S3 Bucket │
                    │  (Resized Images)     │
                    └───────────────────────┘
                                │
                                │ 4. Retrieve Optimized Image
                                ▼
                    ┌───────────────────────┐
                    │      Website/App      │
                    └───────────────────────┘

                    All Logs ──────────────────► CloudWatch Logs
```

## Processing Workflow

### Step-by-Step Process

1. **Image Upload**
   - User uploads image to source bucket
   - S3 generates event notification

2. **Event Processing**
   - Lambda receives event with bucket and key info
   - Function validates configuration
   - Checks for infinite loop condition

3. **Image Download**
   - Lambda downloads image from S3
   - Image loaded into memory buffer

4. **Image Resizing**
   - Sharp library processes image
   - Resize with aspect ratio preserved
   - Format-specific compression applied

5. **Image Upload**
   - Resized image uploaded to destination
   - Metadata attached to object
   - Original key name preserved

6. **Logging**
   - Processing results logged
   - Compression ratio calculated
   - Success/failure recorded

## Security Architecture

### Identity and Access Management (IAM)

**Lambda Execution Role**:
- Read permissions on source bucket
- Write permissions on destination bucket
- CloudWatch Logs write permissions

**Principle of Least Privilege**: Function has only necessary permissions

### S3 Security

**Bucket Policies**:
- Public access blocked by default
- Server-side encryption optional
- Bucket versioning recommended

**Access Control**:
- IAM-based access only
- No public bucket access
- Cross-account access configurable

### Network Security

**Default Configuration**:
- Lambda runs in AWS-managed VPC
- Public internet access for S3 API calls

**VPC Configuration (Optional)**:
- Deploy Lambda in private subnet
- Use VPC endpoints for S3 access
- No internet gateway required

## Scalability

### Automatic Scaling

**Lambda Concurrency**:
- Scales automatically based on events
- Up to 1000 concurrent executions (default)
- Reserved concurrency configurable

**S3 Performance**:
- 3,500 PUT requests per second
- 5,500 GET requests per second
- Automatically scales for higher rates

### Performance Optimization

**Cold Start Mitigation**:
- Keep function warm with scheduled invocations
- Provisioned concurrency for critical workloads

**Memory Optimization**:
- Increase memory for faster processing
- More memory = more CPU power

## Reliability

### Error Handling

**Lambda Retries**:
- Automatic retries for failed invocations
- Exponential backoff strategy
- Dead letter queue (optional)

**Idempotency**:
- Same input produces same output
- Safe to retry operations

### Monitoring

**CloudWatch Metrics**:
- Invocations
- Duration
- Errors
- Throttles
- Concurrent executions

**CloudWatch Alarms**:
- Error rate threshold
- Duration threshold
- Throttle alerts

## Cost Optimization

### Cost Factors

1. **Lambda Execution**
   - Charged per request
   - Charged per GB-second
   - Free tier: 1M requests, 400,000 GB-seconds/month

2. **S3 Storage**
   - Standard storage pricing
   - Request pricing (PUT, GET)
   - Data transfer costs

3. **CloudWatch**
   - Log storage
   - Log ingestion
   - Metrics and alarms

### Optimization Strategies

1. **Right-size Memory**
   - Balance cost vs. performance
   - Monitor duration and memory usage

2. **Lifecycle Policies**
   - Archive old images to S3 Glacier
   - Delete temporary files

3. **Compression**
   - Reduce storage costs
   - Lower transfer costs

4. **Reserved Capacity**
   - Provisioned concurrency for predictable workloads
   - Savings plans for consistent usage

## Disaster Recovery

### Backup Strategy

**Source Bucket**:
- Enable versioning
- Cross-region replication
- Lifecycle policies for retention

**Destination Bucket**:
- Same region as source (default)
- Cross-region replication optional

### Recovery Procedures

**Function Failure**:
- Automatic retries
- Dead letter queue captures failures
- Replay from DLQ after fix

**Bucket Deletion**:
- Versioning enables recovery
- MFA delete protection recommended

## Compliance and Governance

### Tagging Strategy

**Required Tags**:
- `Environment` (dev, staging, prod)
- `Project` (image-resize)
- `CostCenter` (billing allocation)

### Audit Logging

**CloudTrail**:
- API calls logged
- S3 object-level logging
- Lambda invocation tracking

### Data Retention

**CloudWatch Logs**: 7 days (adjustable)
**S3 Objects**: Based on lifecycle policy
**Lambda Versions**: Latest version only

## Integration Points

### Upstream Systems

- Content Management Systems (CMS)
- Mobile applications
- Web applications
- Batch upload tools

### Downstream Systems

- CDN (CloudFront)
- Web servers
- Mobile apps
- Email systems

## Future Enhancements

### Potential Improvements

1. **Multiple Resize Profiles**
   - Generate multiple sizes per upload
   - Thumbnail, medium, large variants

2. **Format Conversion**
   - WebP for modern browsers
   - AVIF support

3. **Advanced Processing**
   - Watermarking
   - Face detection
   - Smart cropping

4. **API Gateway Integration**
   - On-demand resizing
   - RESTful API endpoint

5. **Caching Layer**
   - CloudFront distribution
   - Reduced processing costs

6. **Machine Learning**
   - Content-aware cropping
   - Quality optimization

## References

- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [S3 Event Notifications](https://docs.aws.amazon.com/AmazonS3/latest/userguide/NotificationHowTo.html)
- [Sharp Documentation](https://sharp.pixelplumbing.com/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
