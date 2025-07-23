#!/bin/bash
set -e

echo "🚀 Starting Flutter web build..."

# Install Flutter
echo "📦 Installing Flutter..."
cd /tmp
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="/tmp/flutter/bin:$PATH"

# Verify Flutter installation
echo "✅ Flutter version:"
flutter --version

# Navigate back to project directory
cd $OLDPWD
echo "📁 Current directory: $(pwd)"

# Enable web support
echo "🌐 Enabling web support..."
flutter config --enable-web

# Get dependencies
echo "📚 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building for web..."
flutter build web --release

# Verify build output
echo "📋 Build output verification:"
ls -la build/
if [ -d "build/web" ]; then
    echo "✅ build/web directory exists"
    ls -la build/web/
else
    echo "❌ build/web directory not found"
    echo "Available directories:"
    find . -name "web" -type d
fi

echo "🎉 Build completed successfully!"