#!/bin/bash

# Install Flutter
echo "Installing Flutter..."
cd /tmp
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="/tmp/flutter/bin:$PATH"

# Verify Flutter installation
flutter --version

# Navigate back to project directory
cd $OLDPWD

# Enable web support
flutter config --enable-web

# Get dependencies
flutter pub get

# Build for web
flutter build web --release

echo "Build completed successfully!"