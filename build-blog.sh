#!/bin/bash
# Build Weblog - TStorie Blog Engine

echo "Building Weblog..."
nim c -o:weblog tstorie.nim

if [ $? -eq 0 ]; then
    echo "✓ Build successful!"
    echo "Run with: ./weblog"
else
    echo "✗ Build failed!"
    exit 1
fi
