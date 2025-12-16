#!/bin/bash
# TStorie Blog Engine - Helper Script

set -e

BLOG_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$BLOG_DIR")"
BLOG_BINARY="$PROJECT_ROOT/weblog"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

show_help() {
    cat << EOF
TStorie Blog Engine - Helper Script

Usage: $0 <command>

Commands:
    build       Compile the blog engine
    run         Compile and run the blog engine
    index       Generate article index from markdown files
    clean       Remove compiled binaries
    new <name>  Create a new article template (not implemented yet)
    help        Show this help message

Examples:
    $0 build            # Compile the blog engine
    $0 run              # Compile and run
    $0 index            # Regenerate article index
    $0 clean            # Clean up binaries

EOF
}

cmd_build() {
    echo -e "${GREEN}Building TStorie Blog Engine...${NC}"
    cd "$PROJECT_ROOT"
    nim c --out:weblog -d:userFile=blog/weblog tstorie.nim
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo -e "Binary: ${YELLOW}$BLOG_BINARY${NC}"
}

cmd_run() {
    cmd_build
    echo ""
    echo -e "${GREEN}Starting blog engine...${NC}"
    echo -e "${YELLOW}Press Q to quit${NC}"
    echo ""
    "$BLOG_BINARY"
}

cmd_index() {
    echo -e "${GREEN}Generating article index...${NC}"
    cd "$PROJECT_ROOT"
    nim c -r blog/tools/generate_index.nim
    echo -e "${GREEN}✓ Index generated!${NC}"
}

cmd_clean() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    rm -f "$BLOG_BINARY"
    rm -f "$PROJECT_ROOT/blog/tools/generate_index"
    echo -e "${GREEN}✓ Clean complete!${NC}"
}

cmd_new() {
    local slug="$1"
    if [ -z "$slug" ]; then
        echo -e "${RED}Error: Please provide an article name${NC}"
        echo "Usage: $0 new <article-slug>"
        exit 1
    fi
    
    local date=$(date +%Y-%m-%d)
    local year=$(date +%Y)
    local month=$(date +%m)
    local dir="$BLOG_DIR/articles/$year/$month"
    local filename="$dir/$date-$slug.md"
    
    mkdir -p "$dir"
    
    if [ -f "$filename" ]; then
        echo -e "${RED}Error: Article already exists: $filename${NC}"
        exit 1
    fi
    
    cat > "$filename" << EOF
---
title: ${slug//-/ }
author: Your Name
date: $date
category: uncategorized
tags: 
excerpt: 
published: false
featured: false
---

# ${slug//-/ }

Your article content goes here...

## Section 1

Content...

## Section 2

More content...
EOF
    
    echo -e "${GREEN}✓ Created new article: $filename${NC}"
    echo "Edit the file and set published: true when ready"
    echo "Run '$0 index' to update the index"
}

# Main command dispatcher
case "${1:-help}" in
    build)
        cmd_build
        ;;
    run)
        cmd_run
        ;;
    index)
        cmd_index
        ;;
    clean)
        cmd_clean
        ;;
    new)
        cmd_new "$2"
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac
