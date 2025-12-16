# TStorie Blog Engine

A terminal user interface (TUI) blog system built on the TStorie framework.

## Overview

The TStorie Blog Engine is a fully functional blog reader that runs entirely in your terminal. It demonstrates TStorie's capabilities including:

- **Layer-based rendering** - Separate header, content, and footer layers
- **Article navigation** - Browse and read multiple articles
- **Smooth scrolling** - Navigate long articles with keyboard controls
- **Modern TUI design** - Clean interface with styled text and separators

## Directory Structure

```
blog/
├── weblog.nim            # Main blog application
├── tools/
│   └── generate_index.nim  # Article index generator
├── articles/
│   ├── 2024/
│   │   ├── 12/
│   │   │   ├── 2024-12-01-first-post.md
│   │   │   └── 2024-12-15-tui-animations.md
│   │   └── 11/
│   │       └── 2024-11-20-getting-started.md
│   └── index.json        # Generated article index
├── templates/            # (Reserved for future use)
├── pages/                # (Reserved for future use)
└── assets/               # (Reserved for future use)
```

## Quick Start

### 1. Compile the Blog Engine

From the project root:

```bash
nim c --out:weblog -d:userFile=blog/weblog tstorie.nim
```

Or use the build script:

```bash
chmod +x blog/run_blog.sh
./blog/run_blog.sh
```

### 2. Run the Blog

```bash
./weblog
```

## Keyboard Controls

- **↑/↓** - Scroll through article content (in article view) or navigate article list
- **PAGE UP/DOWN** - Scroll faster through articles
- **L** - Return to article list
- **ENTER** - Open selected article (in list view)
- **Q** or **ESC** - Quit the application
- **H** - Help (not yet implemented)

## Article Format

Articles are stored as Markdown files with YAML front matter. Currently, the blog engine uses hardcoded article data for simplicity, but it's designed to support loading from files.

### Example Article

```markdown
---
title: My Article Title
author: Your Name
date: 2024-12-01
category: tutorials
tags: nim, tui, programming
excerpt: A brief description of the article
published: true
featured: false
---

# My Article Title

Your article content goes here...

## Sections

Use standard Markdown formatting.
```

## Features

### Current Features

- [x] Article list view with navigation
- [x] Article reading view with scrolling
- [x] Header with title and navigation hints
- [x] Footer with article counter and help hint
- [x] Keyboard navigation
- [x] Syntax highlighting for article selection

### Planned Features

- [ ] Load articles from markdown files
- [ ] Category filtering
- [ ] Tag-based navigation
- [ ] Search functionality
- [ ] Help overlay
- [ ] About page
- [ ] Custom article rendering with Nimini code blocks
- [ ] Markdown formatting (bold, italics, links)
- [ ] Color schemes

## Development

### Adding New Articles

1. Create a markdown file in `blog/articles/YYYY/MM/`
2. Add YAML front matter with metadata
3. Run the index generator:
   ```bash
   nim c -r blog/tools/generate_index.nim
   ```
4. Recompile the blog engine

### Modifying the Blog Engine

The blog engine code is in `blog/weblog.nim`. It follows the TStorie callback pattern:

- `onInit` - Initialize layers and load articles
- `onRender` - Render current view (list or article)
- `onInput` - Handle keyboard input
- `onUpdate` - Frame updates (currently unused)
- `onShutdown` - Cleanup (currently unused)

## Architecture

The blog engine uses TStorie's layer system:

1. **Header Layer** (Z=100) - Blog title and navigation hints
2. **Content Layer** (Z=50) - Article list or article content
3. **Footer Layer** (Z=90) - Status bar and help text

Layers are composited in Z-order, allowing for clean separation of concerns.

## Tools

### generate_index.nim

Scans the `blog/articles` directory and generates `index.json` with metadata for all published articles.

Usage:
```bash
nim c -r blog/tools/generate_index.nim
```

## License

Same as the parent TStorie project.

## Contributing

Contributions are welcome! Areas for improvement:

- File-based article loading
- Better Markdown rendering
- Category/tag navigation
- Search functionality
- Themes and customization
- Performance optimizations

## Credits

Built with [TStorie](https://github.com/maddestlabs/weblog) - A terminal user interface framework for Nim.
