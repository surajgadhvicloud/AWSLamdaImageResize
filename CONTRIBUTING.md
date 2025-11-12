# Contributing to AWS Lambda Image Resize

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

Please be respectful and constructive in all interactions. We aim to foster an inclusive and welcoming community.

## How to Contribute

### Reporting Issues

If you find a bug or have a feature request:

1. Check if the issue already exists in the [Issues](https://github.com/surajgadhvicloud/AWSLamdaImageResize/issues) section
2. If not, create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs. actual behavior
   - Environment details (Node.js version, AWS region, etc.)
   - Logs or error messages

### Suggesting Enhancements

We welcome feature suggestions! Please:

1. Open an issue with the `enhancement` label
2. Describe the feature and its benefits
3. Provide use cases or examples
4. Discuss implementation ideas

### Pull Requests

#### Before Starting

1. Check existing issues and PRs to avoid duplication
2. For major changes, open an issue first to discuss
3. Fork the repository
4. Create a feature branch from `main`

#### Development Process

1. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/AWSLamdaImageResize.git
   cd AWSLamdaImageResize
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow the coding standards below
   - Add tests if applicable
   - Update documentation

4. **Test your changes**
   ```bash
   # Validate JavaScript syntax
   node --check lambda/index.js
   
   # Test deployment (in a test AWS account)
   ./scripts/deploy.sh
   
   # Test functionality
   ./scripts/test.sh path/to/test-image.jpg
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Create a Pull Request**
   - Provide a clear title and description
   - Reference related issues
   - Include screenshots for UI changes
   - Wait for review

#### PR Guidelines

- Keep PRs focused on a single feature/fix
- Write clear commit messages
- Update documentation for changes
- Add tests for new functionality
- Ensure CI checks pass
- Respond to review comments

## Coding Standards

### JavaScript

- Use ES6+ features
- Use `const` and `let`, avoid `var`
- Use async/await for asynchronous code
- Add JSDoc comments for functions
- Handle errors properly
- Log important events

#### Example:

```javascript
/**
 * Resize an image buffer
 * @param {Buffer} imageBuffer - The input image buffer
 * @param {number} width - Target width
 * @param {number} height - Target height
 * @returns {Promise<Buffer>} Resized image buffer
 */
async function resizeImage(imageBuffer, width, height) {
    try {
        return await sharp(imageBuffer)
            .resize(width, height)
            .toBuffer();
    } catch (error) {
        console.error('Error resizing image:', error);
        throw error;
    }
}
```

### AWS CloudFormation/SAM

- Use descriptive resource names
- Add descriptions to parameters
- Include outputs for important resources
- Use `!Ref` and `!GetAtt` for references
- Follow AWS best practices

### Shell Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error handling
- Add comments for complex logic
- Validate inputs
- Provide helpful error messages

### Documentation

- Use clear, concise language
- Include examples
- Update README for significant changes
- Add inline comments for complex code
- Keep documentation in sync with code

## Project Structure

```
.
├── lambda/              # Lambda function code
├── layer/               # Lambda Layer configuration
├── scripts/             # Deployment and utility scripts
├── template.yaml        # SAM/CloudFormation template
├── README.md           # Main documentation
├── DEPLOYMENT.md       # Deployment guide
├── ARCHITECTURE.md     # Architecture overview
└── CONTRIBUTING.md     # This file
```

## Testing

### Local Testing

Test Lambda function locally with SAM CLI:

```bash
# Start local API
sam local start-lambda

# Invoke function locally
sam local invoke ImageResizeFunction \
  --event test-events/s3-event.json
```

### Integration Testing

Deploy to a test AWS account:

```bash
# Deploy to test environment
STACK_NAME=test-image-resize \
AWS_REGION=us-east-1 \
./scripts/deploy.sh

# Test with sample image
./scripts/test.sh test-images/sample.jpg

# Verify results
aws s3 ls s3://test-destination-bucket/
```

### Test Events

Create test S3 events in `test-events/` directory:

```json
{
  "Records": [
    {
      "s3": {
        "bucket": {
          "name": "test-source-bucket"
        },
        "object": {
          "key": "test-image.jpg"
        }
      }
    }
  ]
}
```

## Documentation Updates

When making changes that affect:

- **API/Configuration**: Update README.md
- **Deployment**: Update DEPLOYMENT.md
- **Architecture**: Update ARCHITECTURE.md
- **Code**: Add/update inline comments

## Performance Considerations

When contributing code:

- Optimize image processing performance
- Minimize memory usage
- Consider cold start impact
- Profile execution time
- Test with various image sizes

## Security

### Security Best Practices

- Never commit AWS credentials
- Follow least privilege principle
- Validate all inputs
- Handle errors securely
- Review security implications

### Reporting Security Issues

For security vulnerabilities:
- **DO NOT** open a public issue
- Email security concerns privately
- Wait for acknowledgment before disclosure

## Release Process

1. Version bumps follow [Semantic Versioning](https://semver.org/)
2. Update CHANGELOG.md with changes
3. Tag releases in Git
4. Create GitHub release with notes

## Getting Help

- Open an issue for questions
- Check existing documentation
- Review closed issues and PRs
- Consult AWS documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be recognized in:
- README.md acknowledgments section
- GitHub contributors page
- Release notes

Thank you for contributing! 🎉
