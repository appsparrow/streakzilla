#!/bin/bash

# Explicitly use npm for Cloudflare Pages
echo "Using npm for build..."
npm --version
npm install
npm run build

echo "Build complete!"
