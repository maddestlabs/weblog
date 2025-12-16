#!/bin/bash
# Build and run the blog engine

cd "$(dirname "$0")"

echo "Building TStorie Blog Engine..."
nim c --out:../weblog -d:userFile=blog/weblog ../tstorie.nim

if [ $? -eq 0 ]; then
    echo "✓ Build successful!"
    echo ""
    echo "Starting blog engine..."
    ../weblog
else
    echo "✗ Build failed!"
    exit 1
fi
