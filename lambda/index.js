const AWS = require('aws-sdk');
const sharp = require('sharp');
const s3 = new AWS.S3();

// Configuration for image resizing
const RESIZE_WIDTH = parseInt(process.env.RESIZE_WIDTH || '800');
const RESIZE_HEIGHT = parseInt(process.env.RESIZE_HEIGHT || '600');
const IMAGE_QUALITY = parseInt(process.env.IMAGE_QUALITY || '80');
const DESTINATION_BUCKET = process.env.DESTINATION_BUCKET;

exports.handler = async (event) => {
    console.log('Lambda function invoked');
    console.log('Event:', JSON.stringify(event, null, 2));

    // Process each S3 record in the event
    const results = await Promise.all(
        event.Records.map(async (record) => {
            try {
                const sourceBucket = record.s3.bucket.name;
                const sourceKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
                
                console.log(`Processing image: ${sourceKey} from bucket: ${sourceBucket}`);

                // Validate destination bucket is configured
                if (!DESTINATION_BUCKET) {
                    throw new Error('DESTINATION_BUCKET environment variable not set');
                }

                // Skip if already in destination bucket (prevent infinite loop)
                if (sourceBucket === DESTINATION_BUCKET) {
                    console.log('Skipping image already in destination bucket');
                    return { statusCode: 200, message: 'Skipped' };
                }

                // Get the image from S3
                const params = {
                    Bucket: sourceBucket,
                    Key: sourceKey
                };
                
                const inputData = await s3.getObject(params).promise();
                console.log(`Successfully retrieved image. Size: ${inputData.Body.length} bytes`);

                // Determine output format based on input
                const fileExtension = sourceKey.split('.').pop().toLowerCase();
                let outputFormat = 'jpeg';
                
                if (fileExtension === 'png') {
                    outputFormat = 'png';
                } else if (fileExtension === 'webp') {
                    outputFormat = 'webp';
                } else if (['jpg', 'jpeg'].includes(fileExtension)) {
                    outputFormat = 'jpeg';
                }

                // Resize the image using Sharp
                let sharpInstance = sharp(inputData.Body)
                    .resize(RESIZE_WIDTH, RESIZE_HEIGHT, {
                        fit: 'inside',
                        withoutEnlargement: true
                    });

                // Apply format-specific options
                if (outputFormat === 'jpeg') {
                    sharpInstance = sharpInstance.jpeg({ quality: IMAGE_QUALITY });
                } else if (outputFormat === 'png') {
                    sharpInstance = sharpInstance.png({ quality: IMAGE_QUALITY });
                } else if (outputFormat === 'webp') {
                    sharpInstance = sharpInstance.webp({ quality: IMAGE_QUALITY });
                }

                const resizedImageBuffer = await sharpInstance.toBuffer();
                console.log(`Image resized successfully. New size: ${resizedImageBuffer.length} bytes`);

                // Generate destination key
                const destinationKey = sourceKey;

                // Upload resized image to destination bucket
                const uploadParams = {
                    Bucket: DESTINATION_BUCKET,
                    Key: destinationKey,
                    Body: resizedImageBuffer,
                    ContentType: inputData.ContentType || `image/${outputFormat}`,
                    Metadata: {
                        'original-size': inputData.Body.length.toString(),
                        'resized-size': resizedImageBuffer.length.toString(),
                        'resize-dimensions': `${RESIZE_WIDTH}x${RESIZE_HEIGHT}`
                    }
                };

                await s3.putObject(uploadParams).promise();
                console.log(`Successfully uploaded resized image to ${DESTINATION_BUCKET}/${destinationKey}`);

                return {
                    statusCode: 200,
                    message: 'Image processed successfully',
                    sourceKey: sourceKey,
                    destinationKey: destinationKey,
                    originalSize: inputData.Body.length,
                    resizedSize: resizedImageBuffer.length,
                    compressionRatio: ((1 - resizedImageBuffer.length / inputData.Body.length) * 100).toFixed(2) + '%'
                };

            } catch (error) {
                console.error('Error processing image:', error);
                return {
                    statusCode: 500,
                    error: error.message,
                    sourceKey: record.s3.object.key
                };
            }
        })
    );

    console.log('Processing complete:', JSON.stringify(results, null, 2));

    return {
        statusCode: 200,
        body: JSON.stringify({
            message: 'Image processing complete',
            results: results
        })
    };
};
