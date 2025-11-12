#!/bin/bash

# Script to build Lambda Layer for Sharp
# This script creates a Lambda Layer compatible with AWS Lambda runtime

set -e

echo "Building Sharp Lambda Layer..."

# Create necessary directories
mkdir -p nodejs/node_modules

# Install Sharp with Linux x64 binaries
cd nodejs
npm init -y
npm install --arch=x64 --platform=linux sharp@0.32.0

echo "Lambda Layer build complete!"
echo "Package the 'nodejs' directory and upload as a Lambda Layer"
echo ""
echo "To create a ZIP file:"
echo "cd nodejs && zip -r ../sharp-layer.zip . && cd .."
