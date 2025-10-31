#!/bin/bash
set -euo pipefail

echo "🔨 Building Glimpse..."
swift build -c release

echo "📦 Packaging app bundle..."
Scripts/package_app.sh release

echo "📥 Installing to /Applications..."
rm -rf /Applications/Glimpse.app
cp -R .build/release/Glimpse.app /Applications/

echo "✅ Glimpse installed successfully!"
echo "🚀 Launch Glimpse from Launchpad or Spotlight"
