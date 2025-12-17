# Weblog - TStorie Blog Engine

A terminal user interface (TUI) blog reader built with the TStorie framework.

## Quick Start

### Terminal Version

```bash
# Build
./build-blog.sh

# Or manually
nim c -o:weblog tstorie.nim

# Run
./weblog
```

### Web Version (WASM)

```bash
# Build and deploy to /docs/
./build-web.sh

# Test locally
cd docs && python3 -m http.server 8000
# Open http://localhost:8000
```

The web version is automatically deployed to `/docs/` including all articles and assets, ready for GitHub Pages or static hosting.

## Project Structure

```
weblog/
├── index.nim              # Blog engine implementation
├── tstorie.nim            # TStorie framework
├── build-blog.sh          # Build script
├── articles/              # Blog articles
│   ├── index.json        # Generated article index
│   └── 2024/             # Articles by year/month
├── pages/                 # Static pages
├── templates/             # Template components
├── tools/                 # Utility scripts
│   └── generate_index.nim # Article index generator
├── lib/                   # Libraries
│   ├── drawing.nim
│   ├── events.nim
│   ├── storie_md.nim
│   └── ui_components.nim
└── examples/              # Example applications

```

## Adding Articles

### 1. Create Article File

Create a markdown file in `articles/YYYY/MM/`:

```markdown
---
title: My Article Title
author: Your Name
date: 2024-12-17
category: tutorials
tags: nim, tui, programming
excerpt: A brief description
published: true
featured: false
---

# My Article Title

Your content goes here...
```

### 2. Generate Index

```bash
nim c -r tools/generate_index.nim
```

### 3. Rebuild and Run

```bash
./build-blog.sh
./weblog
```

## Keyboard Controls

- **↑/↓** - Scroll article or navigate list
- **PAGE UP/DOWN** - Fast scrolling
- **L** - Return to article list
- **ENTER** - Open selected article (in list view)
- **Q** or **ESC** - Quit

## Architecture

The blog engine is implemented in `index.nim` which is included by `tstorie.nim`. This means:

- **No need for `-d:userFile`** - Just compile `tstorie.nim`
- **All TStorie APIs available** - Full framework integration
- **Simple build process** - One command to build
- **File-based articles** - Loads from `articles/index.json`
- **Hardcoded fallback** - Web builds use embedded content

### How It Works

1. `tstorie.nim` includes `index.nim`
2. `index.nim` implements blog engine using TStorie callbacks
3. Articles are loaded from `articles/index.json`
4. Renders using TStorie's layer system

## Development

### File Structure

- **index.nim** - Main blog engine code
- **articles/** - Article content (root level)
- **tools/generate_index.nim** - Scans articles, generates index
- **lib/storie_md.nim** - Markdown parser

### Key Features

- ✅ Article list with navigation
- ✅ Article reader with scrolling
- ✅ File-based article loading
- ✅ JSON index for metadata
- ✅ Three-layer rendering (header, content, footer)
- ✅ Keyboard-driven interface
- ✅ Category and tag support

### Building for Web

```bash
./build-web.sh
```

The web build uses hardcoded articles since file I/O isn't available in WebAssembly.

## Tools

### generate_index.nim

Scans `articles/` directory and generates `articles/index.json`:

```bash
nim c -r tools/generate_index.nim
```

## Previous Implementation

The old `blog/` directory structure has been moved to root. The previous standalone blog engine approach (`blog/weblog.nim`) has been integrated into `index.nim` for a simpler build process.

## License

Same as the TStorie project.

## Credits

Built with TStorie - A terminal user interface framework for Nim.
