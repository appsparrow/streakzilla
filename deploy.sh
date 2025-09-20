#!/bin/bash

# Streakzilla Cloudflare Pages Deployment Script

echo "🚀 Building Streakzilla for Cloudflare Pages..."

# Clean previous build
rm -rf dist

# Build the project
npm run build

# Copy Cloudflare Pages configuration files
cp _headers dist/
cp _redirects dist/

echo "✅ Build complete! Ready for deployment."
echo ""
echo "📁 Build output: dist/"
echo "🌐 Deploy to Cloudflare Pages with:"
echo "   - Build command: npm run build"
echo "   - Build output directory: dist"
echo "   - Root directory: / (or leave empty)"
echo ""
echo "🔧 Configuration files created:"
echo "   - package.json (with npm packageManager)"
echo "   - .npmrc (legacy-peer-deps=true)"
echo "   - .nvmrc (Node 18)"
echo "   - wrangler.toml (Cloudflare config)"
echo "   - cloudflare-pages.toml (Pages config)"
