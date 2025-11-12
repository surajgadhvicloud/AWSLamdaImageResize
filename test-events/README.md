# Test Events

This directory contains sample S3 event payloads for testing the Lambda function locally or in AWS.

## Files

- `s3-event.json`: Single image upload event
- `s3-multiple-events.json`: Multiple image upload events (batch processing)

## Local Testing with SAM CLI

### Invoke function locally

```bash
# Test with single event
sam local invoke ImageResizeFunction \
  --event test-events/s3-event.json \
  --env-vars env.json

# Test with multiple events
sam local invoke ImageResizeFunction \
  --event test-events/s3-multiple-events.json \
  --env-vars env.json
```

### Create environment variables file

Create `env.json` with your test configuration:

```json
{
  "ImageResizeFunction": {
    "DESTINATION_BUCKET": "test-destination-bucket",
    "RESIZE_WIDTH": "800",
    "RESIZE_HEIGHT": "600",
    "IMAGE_QUALITY": "80"
  }
}
```

## Creating Custom Test Events

### S3 Event Structure

```json
{
  "Records": [
    {
      "eventVersion": "2.1",
      "eventSource": "aws:s3",
      "awsRegion": "us-east-1",
      "eventTime": "ISO-8601-timestamp",
      "eventName": "ObjectCreated:Put",
      "s3": {
        "bucket": {
          "name": "your-source-bucket-name"
        },
        "object": {
          "key": "your-image-filename.jpg"
        }
      }
    }
  ]
}
```

### Supported Event Types

- `ObjectCreated:Put`: Direct upload
- `ObjectCreated:Post`: Form upload
- `ObjectCreated:Copy`: Copy operation
- `ObjectCreated:*`: Any create event

## Testing Different Scenarios

### 1. JPEG Image

```json
{
  "Records": [{
    "s3": {
      "bucket": { "name": "source-bucket" },
      "object": { "key": "photo.jpg" }
    }
  }]
}
```

### 2. PNG Image

```json
{
  "Records": [{
    "s3": {
      "bucket": { "name": "source-bucket" },
      "object": { "key": "logo.png" }
    }
  }]
}
```

### 3. WebP Image

```json
{
  "Records": [{
    "s3": {
      "bucket": { "name": "source-bucket" },
      "object": { "key": "image.webp" }
    }
  }]
}
```

### 4. Filename with Spaces

```json
{
  "Records": [{
    "s3": {
      "bucket": { "name": "source-bucket" },
      "object": { "key": "my+photo+file.jpg" }
    }
  }]
}
```

Note: S3 URL-encodes spaces as `+`

## Integration Testing

After deploying to AWS, trigger real events:

```bash
# Upload test image to actual S3 bucket
aws s3 cp test-image.jpg s3://your-source-bucket/

# Monitor Lambda logs
aws logs tail /aws/lambda/ImageResizeFunction --follow
```

## Tips

1. **Test Locally First**: Use SAM CLI before deploying
2. **Check Logs**: Lambda logs show detailed processing info
3. **Verify Buckets**: Ensure source and destination buckets exist
4. **Image Formats**: Test all supported formats (JPG, PNG, WebP)
5. **Edge Cases**: Test large files, special characters in filenames
6. **Error Scenarios**: Test with missing buckets, invalid images

## Additional Resources

- [AWS Lambda Event Source Mappings](https://docs.aws.amazon.com/lambda/latest/dg/invocation-eventsourcemapping.html)
- [S3 Event Message Structure](https://docs.aws.amazon.com/AmazonS3/latest/userguide/notification-content-structure.html)
- [SAM Local Testing](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-using-invoke.html)
